import CWasm3
import Foundation

// MARK: - WasmInterpreter

@dynamicMemberLookup
public final class WasmInterpreter {
    private var id: UInt64
    private var idPointer: UnsafeMutableRawPointer

    private var environment: IM3Environment
    private var runtime: IM3Runtime
    private var moduleAndBytes: (IM3Module, [UInt8])
    private var module: IM3Module { moduleAndBytes.0 }

    private var functionCache = [String: IM3Function]()
    private var importedFunctionContexts = [UnsafeMutableRawPointer]()

    private let lock = Lock()

    public convenience init(module: URL) throws {
        try self.init(stackSize: 512 * 1_024, module: module)
    }

    public convenience init(
        stackSize: UInt32,
        module: URL
    ) throws {
        try self.init(stackSize: stackSize, module: [UInt8](Data(contentsOf: module)))
    }

    public convenience init(module bytes: [UInt8]) throws {
        try self.init(stackSize: 512 * 1_024, module: bytes)
    }

    public init(
        stackSize: UInt32,
        module bytes: [UInt8]
    ) throws {
        self.id = nextInstanceIdentifier
        self.idPointer = makeRawPointer(for: id)

        guard let environment = m3_NewEnvironment() else {
            throw WasmInterpreterError.couldNotLoadEnvironment
        }

        guard let runtime = m3_NewRuntime(environment, stackSize, idPointer) else {
            throw WasmInterpreterError.couldNotLoadRuntime
        }

        var mod: IM3Module?
        try WasmInterpreter.check(m3_ParseModule(environment, &mod, bytes, UInt32(bytes.count)))
        guard let module = mod else {
            throw WasmInterpreterError.couldNotParseModule
        }
        try WasmInterpreter.check(m3_LoadModule(runtime, module))

        self.environment = environment
        self.runtime = runtime
        self.moduleAndBytes = (module, bytes)
    }

    deinit {
        m3_FreeRuntime(runtime)
        m3_FreeEnvironment(environment)
        removeImportedFunctions(forInstanceIdentifier: id)
        idPointer.deallocate()
    }
}

// MARK: - WasmInterpreter + DynamicMemberLookup

public extension WasmInterpreter {
    subscript(dynamicMember member: String) -> (_ args: any WasmTypeProtocol...) throws -> Void {
        { try self.call(member, $0) }
    }

    subscript<R: WasmTypeProtocol>(dynamicMember member: String) -> (_ args: any WasmTypeProtocol...) throws -> R {
        { try self.call(member, $0) }
    }
}

public extension WasmInterpreter {
    func stringFromHeap(byteOffset: Int, length: Int) throws -> String {
        let data = try dataFromHeap(byteOffset: byteOffset, length: length)

        guard let string = String(data: data, encoding: .utf8)
        else {
            throw WasmInterpreterError.invalidUTF8String
        }

        return string
    }

    func valueFromHeap<T: WasmTypeProtocol>(byteOffset: Int) throws -> T {
        let values = try valuesFromHeap(byteOffset: byteOffset, length: 1) as [T]
        guard let value = values.first
        else {
            throw WasmInterpreterError.couldNotLoadMemory
        }
        return value
    }

    func valuesFromHeap<T: WasmTypeProtocol>(byteOffset: Int, length: Int) throws -> [T] {
        let heap = try heap()

        guard heap.isValid(byteOffset: byteOffset, length: length)
        else {
            throw WasmInterpreterError.invalidMemoryAccess
        }

        let ptr = UnsafeRawPointer(heap.pointer)
            .advanced(by: byteOffset)
            .bindMemory(to: T.self, capacity: length)

        return (0..<length).map { ptr[$0] }
    }

    func dataFromHeap(byteOffset: Int, length: Int) throws -> Data {
        let heap = try heap()

        guard heap.isValid(byteOffset: byteOffset, length: length) else {
            throw WasmInterpreterError.invalidMemoryAccess
        }

        return Data(bytes: heap.pointer.advanced(by: byteOffset), count: length)
    }

    func bytesFromHeap(byteOffset: Int, length: Int) throws -> [UInt8] {
        let heap = try heap()

        guard heap.isValid(byteOffset: byteOffset, length: length) else {
            throw WasmInterpreterError.invalidMemoryAccess
        }

        let bufferPointer = UnsafeBufferPointer(
            start: heap.pointer.advanced(by: byteOffset),
            count: length
        )

        return Array(bufferPointer)
    }

    func writeToHeap(string: String, byteOffset: Int) throws {
        try writeToHeap(data: Data(string.utf8), byteOffset: byteOffset)
    }

    func writeToHeap(value: some WasmTypeProtocol, byteOffset: Int) throws {
        try writeToHeap(values: [value], byteOffset: byteOffset)
    }

    func writeToHeap<T: WasmTypeProtocol>(values: [T], byteOffset: Int) throws {
        var values = values
        try writeToHeap(
            data: Data(bytes: &values, count: values.count * MemoryLayout<T>.size),
            byteOffset: byteOffset
        )
    }

    func writeToHeap(data: Data, byteOffset: Int) throws {
        let heap = try heap()

        guard heap.isValid(byteOffset: byteOffset, length: data.count)
        else {
            throw WasmInterpreterError.invalidMemoryAccess
        }

        try data.withUnsafeBytes { (rawPointer: UnsafeRawBufferPointer) in
            guard let pointer = rawPointer.bindMemory(to: UInt8.self).baseAddress
            else {
                throw WasmInterpreterError.couldNotBindMemory
            }
            heap.pointer
                .advanced(by: byteOffset)
                .initialize(from: pointer, count: data.count)
        }
    }

    func writeToHeap(bytes: [UInt8], byteOffset: Int) throws {
        let heap = try heap()

        guard heap.isValid(byteOffset: byteOffset, length: bytes.count)
        else {
            throw WasmInterpreterError.invalidMemoryAccess
        }

        heap.pointer
            .advanced(by: byteOffset)
            .initialize(from: bytes, count: bytes.count)
    }

    private func heap() throws -> Heap {
        let totalBytes = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
        defer { totalBytes.deallocate() }

        guard let bytesPointer = m3_GetMemory(runtime, totalBytes, 0)
        else {
            throw WasmInterpreterError.invalidMemoryAccess
        }

        return Heap(pointer: bytesPointer, size: Int(totalBytes.pointee))
    }
}

typealias ImportedFunctionSignature = (UnsafeMutablePointer<UInt64>?, UnsafeMutableRawPointer?) -> UnsafeRawPointer?

extension WasmInterpreter {
    /// Imports the specified block into the module matching the supplied name. The
    /// imported block must be included in the compiled module as an `import`.
    ///
    /// The function's signature must conform to `wasm3`'s format, which matches the following
    /// form:
    ///
    /// ```c
    /// u8  ConvertTypeCharToTypeId (char i_code)
    /// {
    ///     switch (i_code) {
    ///     case 'v': return c_m3Type_void;
    ///     case 'i': return c_m3Type_i32;
    ///     case 'I': return c_m3Type_i64;
    ///     case 'f': return c_m3Type_f32;
    ///     case 'F': return c_m3Type_f64;
    ///     case '*': return c_m3Type_ptr;
    ///     }
    ///     return c_m3Type_none;
    /// }
    /// ```
    ///
    /// For example, a block taking two arguments of types `Int64` and `Float32` and
    /// no return value would have this signature: `v(I f)`
    ///
    /// - Throws: Throws if a module matching the given name can't be found or if the
    /// underlying `wasm3` function returns an error.
    ///
    /// - Parameters:
    ///   - name: The name of the function to import, matching the name specified inside the
    ///   WebAssembly module.
    ///   - namespace: The namespace of the function to import, matching the namespace
    ///   specified inside the WebAssembly module.
    ///   - signature: The signature of the function to import, conforming to `wasm3`'s
    /// guidelines
    ///   as outlined above.
    ///   - handler: The function to import into the specified WebAssembly module.
    func importNativeFunction(
        named name: String,
        namespace: String,
        signature: String,
        handler: @escaping ImportedFunctionSignature
    ) throws {
        guard let context = UnsafeMutableRawPointer(bitPattern: (namespace + name).hashValue)
        else {
            throw WasmInterpreterError.couldNotGenerateFunctionContext
        }

        do {
            setImportedFunction(handler, for: context, instanceIdentifier: id)
            try WasmInterpreter.check(
                m3_LinkRawFunctionEx(
                    module,
                    namespace,
                    name,
                    signature,
                    handleImportedFunction,
                    context
                )
            )
            lock.locked { importedFunctionContexts.append(context) }
        } catch {
            removeImportedFunction(for: context, instanceIdentifier: id)
            throw error
        }
    }
}

extension WasmInterpreter {
    func function(named name: String) throws -> IM3Function {
        try lock.locked {
            if let compiledFunction = functionCache[name] {
                return compiledFunction
            } else {
                var f: IM3Function?
                try WasmInterpreter.check(m3_FindFunction(&f, runtime, name))
                guard let function = f
                else {
                    throw WasmInterpreterError.couldNotFindFunction(name)
                }
                functionCache[name] = function
                return function
            }
        }
    }

    func _call(_ function: IM3Function, args: [String]) throws {
        try args.withCStrings { cStrings throws in
            var mutableCStrings = cStrings
            let size = UnsafeMutablePointer<Int>.allocate(capacity: 1)
            defer { size.deallocate() }
            let r = wasm3_CallWithArgs(
                function,
                UInt32(args.count),
                &mutableCStrings,
                size,
                nil
            )
            if let result = r {
                throw WasmInterpreterError.onCallFunction(String(cString: result))
            } else if size.pointee != 0 {
                throw WasmInterpreterError.invalidFunctionReturnType
            } else {
                return ()
            }
        }
    }

    func _call<T: WasmTypeProtocol>(_ function: IM3Function, args: [String]) throws -> T {
        try args.withCStrings { cStrings throws -> T in
            var mutableCStrings = cStrings
            let size = UnsafeMutablePointer<Int>.allocate(capacity: 1)
            defer { size.deallocate() }
            let output = UnsafeMutablePointer<T>.allocate(capacity: 1)
            defer { output.deallocate() }
            let r = wasm3_CallWithArgs(
                function,
                UInt32(args.count),
                &mutableCStrings,
                size,
                output
            )
            if let result = r {
                throw WasmInterpreterError.onCallFunction(String(cString: result))
            } else if MemoryLayout<T>.size != size.pointee {
                throw WasmInterpreterError.invalidFunctionReturnType
            } else {
                let output = output.pointee
                return output
            }
        }
    }
}

extension WasmInterpreter {
    private static func check(_ block: @autoclosure () throws -> M3Result?) throws {
        if let result = try block() {
            throw WasmInterpreterError.wasm3Error(String(cString: result))
        }
    }
}
