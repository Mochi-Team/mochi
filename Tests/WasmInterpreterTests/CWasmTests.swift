@testable import CWasm3
import XCTest

final class CWasm3Tests: XCTestCase {
    func testCanCreateEnvironmentAndRuntime() throws {
        let environment = m3_NewEnvironment()
        defer { m3_FreeEnvironment(environment) }
        XCTAssertNotNil(environment)

        let runtime = m3_NewRuntime(environment, 512, nil)
        defer { m3_FreeRuntime(runtime) }
        XCTAssertNotNil(runtime)
    }

    func testCanCallFunctionsWithSameImplementations() throws {
        let environment = m3_NewEnvironment()
        defer { m3_FreeEnvironment(environment) }

        let runtime = m3_NewRuntime(environment, 512, nil)
        defer { m3_FreeRuntime(runtime) }

        var constantBytes = try constantWasm()
        defer { constantBytes.removeAll() }

        var module: IM3Module?
        XCTAssertNil(m3_ParseModule(
            environment,
            &module,
            constantBytes,
            UInt32(constantBytes.count)
        ))
        XCTAssertNil(m3_LoadModule(runtime, module))

        var constant1Function: IM3Function?
        XCTAssertNil(m3_FindFunction(&constant1Function, runtime, "constant_1"))

        var constant2Function: IM3Function?
        XCTAssertNil(m3_FindFunction(&constant2Function, runtime, "constant_2"))

        var constant3Function: IM3Function?
        XCTAssertNil(m3_FindFunction(&constant3Function, runtime, "constant_3"))

        var constant4Function: IM3Function?
        XCTAssertNil(m3_FindFunction(&constant4Function, runtime, "constant_4"))

        var constant5Function: IM3Function?
        XCTAssertNil(m3_FindFunction(&constant5Function, runtime, "constant_5"))

        var constant6Function: IM3Function?
        XCTAssertNil(m3_FindFunction(&constant6Function, runtime, "constant_6"))

        var constant7Function: IM3Function?
        XCTAssertNil(m3_FindFunction(&constant7Function, runtime, "constant_7"))

        var constant8Function: IM3Function?
        XCTAssertNil(m3_FindFunction(&constant8Function, runtime, "constant_8"))

        var constant9Function: IM3Function?
        XCTAssertNil(m3_FindFunction(&constant9Function, runtime, "constant_9"))

        var constant10Function: IM3Function?
        XCTAssertNil(m3_FindFunction(&constant10Function, runtime, "constant_10"))

        var constant11Function: IM3Function?
        let err = try XCTUnwrap(m3_FindFunction(&constant11Function, runtime, "constant_11"))
        XCTAssertEqual("function lookup failed", String(cString: err))

        [constant1Function, constant2Function, constant3Function]
            .forEach { function in
                guard function != nil else {
                    return XCTFail("function is not a function")
                }
                let size = UnsafeMutablePointer<Int>.allocate(capacity: 1)
                let output = UnsafeMutablePointer<Int32>.allocate(capacity: 1)

                XCTAssertNil(wasm3_CallWithArgs(function, 0, [], size, output))
                XCTAssertEqual(65_536, output.pointee)

                size.deallocate()
                output.deallocate()
            }
    }

    func testCanCallAndReceiveReturnValueFromAdd() throws {
        let environment = m3_NewEnvironment()
        defer { m3_FreeEnvironment(environment) }

        let runtime = m3_NewRuntime(environment, 512, nil)
        defer { m3_FreeRuntime(runtime) }

        var addBytes = try addWasm()
        defer { addBytes.removeAll() }

        var module: IM3Module?
        XCTAssertNil(m3_ParseModule(environment, &module, addBytes, UInt32(addBytes.count)))
        XCTAssertNil(m3_LoadModule(runtime, module))

        var addFunction: IM3Function?
        XCTAssertNil(m3_FindFunction(&addFunction, runtime, "add"))

        let result = ["3", "12345"].withCStrings { args -> Int32 in
            let size = UnsafeMutablePointer<Int>.allocate(capacity: 1)
            let output = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
            XCTAssertNil(wasm3_CallWithArgs(addFunction, UInt32(2), args, size, output))
            XCTAssertEqual(MemoryLayout<Int32>.size, size.pointee)
            return output.pointee
        }

        XCTAssertEqual(12_348, result)
    }

    func testCanCallAndReceiveReturnValueFromFibonacci() throws {
        let environment = m3_NewEnvironment()
        defer { m3_FreeEnvironment(environment) }

        let runtime = m3_NewRuntime(environment, 1 * 1_024 * 1_024, nil)
        defer { m3_FreeRuntime(runtime) }

        var fibonacciBytes = try fibonacciWasm()
        defer { fibonacciBytes.removeAll() }

        var module: IM3Module?
        XCTAssertNil(m3_ParseModule(
            environment,
            &module,
            fibonacciBytes,
            UInt32(fibonacciBytes.count)
        ))
        XCTAssertNil(m3_LoadModule(runtime, module))

        var fibonacciFunction: IM3Function?
        XCTAssertNil(m3_FindFunction(&fibonacciFunction, runtime, "fib"))

        let result = ["25"].withCStrings { args -> Int64 in
            let size = UnsafeMutablePointer<Int>.allocate(capacity: 1)
            let output = UnsafeMutablePointer<Int64>.allocate(capacity: 1)
            XCTAssertNil(wasm3_CallWithArgs(fibonacciFunction, UInt32(1), args, size, output))
            XCTAssertEqual(MemoryLayout<Int64>.size, size.pointee)
            return output.pointee
        }

        XCTAssertEqual(75_025, result)
    }

    func testImportingNativeFunction() throws {
        let environment = m3_NewEnvironment()
        defer { m3_FreeEnvironment(environment) }

        let runtime = m3_NewRuntime(environment, 512, nil)
        defer { m3_FreeRuntime(runtime) }

        var importedAddBytes = try importedAddWasm()
        defer { importedAddBytes.removeAll() }

        var module: IM3Module?
        XCTAssertNil(m3_ParseModule(
            environment,
            &module,
            importedAddBytes,
            UInt32(importedAddBytes.count)
        ))
        XCTAssertNil(m3_LoadModule(runtime, module))

        // The imported function needs to linked before the exported function can be referenced.
        XCTAssertNil(m3_LinkRawFunction(
            module, "imports", "imported_add_func", "i(i I)", importedAdd
        ))

        var integerProviderFunction: IM3Function?
        XCTAssertNil(m3_FindFunction(
            &integerProviderFunction,
            runtime,
            "integer_provider_func"
        ))

        let size = UnsafeMutablePointer<Int>.allocate(capacity: 1)
        defer { size.deallocate() }

        let ret = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        defer { ret.deallocate() }

        XCTAssertNil(wasm3_CallWithArgs(integerProviderFunction, UInt32(0), nil, size, ret))
        XCTAssertEqual(MemoryLayout<Int32>.size, size.pointee)
        let sum = ret.pointee

        XCTAssertEqual(-3_291, sum)
    }

    func testModifyingHeapMemoryInsideImportedFunction() throws {
        let environment = m3_NewEnvironment()
        defer { m3_FreeEnvironment(environment) }

        let runtime = m3_NewRuntime(environment, 512, nil)
        defer { m3_FreeRuntime(runtime) }

        var addBytes = try memoryWasm()
        defer { addBytes.removeAll() }

        var module: IM3Module?
        XCTAssertNil(m3_ParseModule(environment, &module, addBytes, UInt32(addBytes.count)))
        XCTAssertNil(m3_LoadModule(runtime, module))

        XCTAssertNil(m3_LinkRawFunction(
            module, "native", "write", "v(i i)", importedWrite
        ))

        var writeUTF8Function: IM3Function?
        XCTAssertNil(m3_FindFunction(&writeUTF8Function, runtime, "write_utf8"))

        XCTAssertNil(wasm3_CallWithArgs(writeUTF8Function, UInt32(0), nil, nil, nil))

        var heapBytes = 0
        let heapString = try runtime.stringFromHeap(
            offset: 0,
            length: 13, // defined in memory.wasm
            totalHeapBytes: &heapBytes
        )

        XCTAssertEqual(65_536, heapBytes) // minimum heap size defined in memory.wasm
        XCTAssertEqual("DDDDDDDDDDDDD", heapString)
    }

    func testModifyHeapMemoryInsideOfWasmFunction() throws {
        let environment = m3_NewEnvironment()
        defer { m3_FreeEnvironment(environment) }

        let runtime = m3_NewRuntime(environment, 512, nil)
        defer { m3_FreeRuntime(runtime) }

        var addBytes = try memoryWasm()
        defer { addBytes.removeAll() }

        var module: IM3Module?
        XCTAssertNil(m3_ParseModule(environment, &module, addBytes, UInt32(addBytes.count)))
        XCTAssertNil(m3_LoadModule(runtime, module))

        XCTAssertNil(m3_LinkRawFunction(
            module, "native", "write", "v(i i)", importedWrite
        ))

        var writeUTF8Function: IM3Function?
        XCTAssertNil(m3_FindFunction(&writeUTF8Function, runtime, "write_utf8"))

        var modifyUTF8Function: IM3Function?
        XCTAssertNil(m3_FindFunction(&modifyUTF8Function, runtime, "modify_utf8"))

        XCTAssertNil(wasm3_CallWithArgs(writeUTF8Function, UInt32(0), nil, nil, nil))

        let beforeModification = try runtime.stringFromHeap(offset: 0, length: 13)
        XCTAssertEqual("DDDDDDDDDDDDD", beforeModification)

        let afterModification = try ["4"].withCStrings { args throws -> String in
            XCTAssertNil(wasm3_CallWithArgs(modifyUTF8Function, UInt32(1), args, nil, nil))
            return try runtime
                .stringFromHeap(offset: 0, length: 13) // length defined in memory.wasm
        }
        XCTAssertEqual("DDDDEDDDDDDDD", afterModification)
    }

    static var allTests = [
        ("testCanCreateEnvironmentAndRuntime", testCanCreateEnvironmentAndRuntime),
        (
            "testCanCallFunctionsWithSameImplementations",
            testCanCallFunctionsWithSameImplementations
        ),
        ("testCanCallAndReceiveReturnValueFromAdd", testCanCallAndReceiveReturnValueFromAdd),
        (
            "testCanCallAndReceiveReturnValueFromFibonacci",
            testCanCallAndReceiveReturnValueFromFibonacci
        ),
        ("testImportingNativeFunction", testImportingNativeFunction),
        (
            "testModifyingHeapMemoryInsideImportedFunction",
            testModifyingHeapMemoryInsideImportedFunction
        ),
        ("testModifyHeapMemoryInsideOfWasmFunction", testModifyHeapMemoryInsideOfWasmFunction)
    ]
}

private func importedWrite(
    runtime _: IM3Runtime?,
    context _: IM3ImportContext?,
    stackPointer: UnsafeMutablePointer<UInt64>?,
    memory: UnsafeMutableRawPointer?
) -> UnsafeRawPointer? {
    guard let stackPointer = UnsafeMutableRawPointer(stackPointer) else {
        return UnsafeRawPointer(m3Err_trapUnreachable)
    }

    guard let memory = memory else {
        return UnsafeRawPointer(m3Err_wasmMemoryOverflow)
    }

    let offset = stackPointer.load(as: Int32.self)
    let length = stackPointer.load(fromByteOffset: MemoryLayout<Int64>.stride, as: Int32.self)

    memory
        .advanced(by: Int(offset))
        .initializeMemory(
            as: CChar.self,
            repeating: CChar(bitPattern: 0x0044),
            count: Int(length)
        )

    return nil
}

private func importedAdd(
    runtime _: IM3Runtime?,
    context _: IM3ImportContext?,
    stackPointer: UnsafeMutablePointer<UInt64>?,
    memory _: UnsafeMutableRawPointer?
) -> UnsafeRawPointer? {
    guard let stackPointer = UnsafeMutableRawPointer(stackPointer) else {
        return UnsafeRawPointer(m3Err_trapUnreachable)
    }

    // Arguments and return values are passed in and out through the stack pointer _sp.
    // Placeholder return value slots are first and arguments after. So, the first
    // argument is at _sp [numReturns].
    // Return values should be written into _sp [0] to _sp [num_returns - 1].
    // Wasm3 always aligns the stack to 64 bits.
    let offset = MemoryLayout<Int64>.stride
    let first = stackPointer.load(fromByteOffset: offset, as: Int32.self)
    let second = stackPointer.load(fromByteOffset: offset + offset, as: Int32.self)
    let sum = first + second
    stackPointer.storeBytes(of: sum, as: Int32.self)

    return nil
}

private extension Optional where Wrapped == IM3Runtime {
    func stringFromHeap(
        offset: Int,
        length: Int,
        totalHeapBytes: UnsafeMutablePointer<Int>? = nil
    ) throws -> String {
        let heapBytes = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
        defer { heapBytes.deallocate() }

        let heap: UnsafeMutableRawPointer = try XCTUnwrap(
            UnsafeMutableRawPointer(m3_GetMemory(self, heapBytes, 0).advanced(by: offset))
        )

        totalHeapBytes?.pointee = Int(heapBytes.pointee)

        let ptr = heap.bindMemory(to: CChar.self, capacity: length)
        return String(cString: ptr)
    }
}

extension CWasm3Tests {
    // compile and copy base64 binaries in Bash via:
    // `wat2wasm -o >(base64) path/to/file.wat | pbcopy`

    private enum TestError: Error {
        case couldNotDecodeWasm(String)
        case couldNotLoadResource(String)
    }

    private func addWasm() throws -> [UInt8] {
        let base64 = "AGFzbQEAAAABBwFgAn9/AX8DAgEABwcBA2FkZAAACgkBBwAgACABags="
        guard let data = Data(base64Encoded: base64)
        else { throw TestError.couldNotDecodeWasm("add.wasm") }
        return [UInt8](data)
    }

    private func constantWasm() throws -> [UInt8] {
        // swiftlint:disable line_length
        let base64 =
            "AGFzbQEAAAABBQFgAAF/AwIBAAeSAQsKY29uc3RhbnRfMQAACmNvbnN0YW50XzIAAApjb25zdGFudF8zAAAKY29uc3RhbnRfNAAACmNvbnN0YW50XzUAAApjb25zdGFudF82AAAKY29uc3RhbnRfNwAACmNvbnN0YW50XzgAAApjb25zdGFudF85AAALY29uc3RhbnRfMTAAAAtjb25zdGFudF8xMQAACggBBgBBgIAECw=="
        guard let data = Data(base64Encoded: base64)
        else { throw TestError.couldNotDecodeWasm("constant.wasm") }
        return [UInt8](data)
    }

    private func fibonacciWasm() throws -> [UInt8] {
        let base64 =
            "AGFzbQEAAAABBgFgAX4BfgMCAQAHBwEDZmliAAAKHwEdACAAQgJUBEAgAA8LIABCAn0QACAAQgF9EAB8Dws="
        guard let data = Data(base64Encoded: base64)
        else { throw TestError.couldNotDecodeWasm("fib64.wasm") }
        return [UInt8](data)
    }

    private func importedAddWasm() throws -> [UInt8] {
        let base64 =
            "AGFzbQEAAAABCwJgAn9+AX9gAAF/Ah0BB2ltcG9ydHMRaW1wb3J0ZWRfYWRkX2Z1bmMAAAMCAQEHGQEVaW50ZWdlcl9wcm92aWRlcl9mdW5jAAEKCwEJAEH7ZUIqEAAL"
        guard let data = Data(base64Encoded: base64)
        else { throw TestError.couldNotDecodeWasm("imported-add.wasm") }
        return [UInt8](data)
    }

    private func memoryWasm() throws -> [UInt8] {
        let base64 =
            "AGFzbQEAAAABDQNgAn9/AGAAAGABfwACEAEGbmF0aXZlBXdyaXRlAAADAwIBAgUDAQABBxwCCndyaXRlX3V0ZjgAAQttb2RpZnlfdXRmOAACChoCCABBAEENEAALDwAgACAAKAIAQQFqNgIACw=="
        guard let data = Data(base64Encoded: base64)
        else { throw TestError.couldNotDecodeWasm("memory.wasm") }
        return [UInt8](data)
    }
}
