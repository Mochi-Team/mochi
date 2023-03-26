import CWasm3
import Foundation

// Arguments and return values are passed in and out through the stack pointer
// of imported functions.
//
// Placeholder return value slots are first and arguments after. So, the first
// argument is at _sp [numReturns].
//
// Return values should be written into _sp [0] to _sp [num_returns - 1].
//
// Wasm3 always aligns the stack to 64 bits.

public extension WasmInterpreter {
    func addImportHandler(
        named name: String,
        namespace: String,
        block: @escaping () throws -> Void
    ) throws {
        let importedFunction: ImportedFunctionSignature = { _, _ in
            do {
                try block()
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
        let sig = try signature()
        try importNativeFunction(
            named: name,
            namespace: namespace,
            signature: sig,
            handler: importedFunction
        )
    }

    func addImportHandler(
        named name: String,
        namespace: String,
        block: @escaping (UnsafeMutableRawPointer?) throws -> Void
    ) throws {
        let importedFunction: ImportedFunctionSignature = { _, heap in
            do {
                try block(heap)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
        let sig = try signature()
        try importNativeFunction(
            named: name,
            namespace: namespace,
            signature: sig,
            handler: importedFunction
        )
    }

    func addImportHandler<Ret: WasmTypeProtocol>(
        named name: String,
        namespace: String,
        block: @escaping () throws -> Ret
    ) throws {
        let importedFunction: ImportedFunctionSignature = { stack, _ in
            do {
                let ret = try block()
                try NativeFunction.pushReturnValue(ret, to: stack)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
        let sig = try signature(ret: Ret.self)
        try importNativeFunction(
            named: name,
            namespace: namespace,
            signature: sig,
            handler: importedFunction
        )
    }

    func addImportHandler<Ret: WasmTypeProtocol>(
        named name: String,
        namespace: String,
        block: @escaping (UnsafeMutableRawPointer?) throws -> Ret
    ) throws {
        let importedFunction: ImportedFunctionSignature = { stack, heap in
            do {
                let ret = try block(heap)
                try NativeFunction.pushReturnValue(ret, to: stack)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
        let sig = try signature(ret: Ret.self)
        try importNativeFunction(
            named: name,
            namespace: namespace,
            signature: sig,
            handler: importedFunction
        )
    }

    func addImportHandler(
        named name: String,
        namespace: String,
        argTypes: [any WasmTypeProtocol.Type],
        block: @escaping ([any WasmTypeProtocol]) throws -> Void
    ) throws {
        let importedFunction: ImportedFunctionSignature = { stack, _ in
            do {
                var count = 0
                let args = try argTypes.map {
                    let value = try NativeFunction.argument(of: $0, from: stack, at: count)
                    count += 1
                    return value
                }
                try block(args)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
        let sig = try signature(args: argTypes)
        try importNativeFunction(
            named: name,
            namespace: namespace,
            signature: sig,
            handler: importedFunction
        )
    }

    func addImportHandler(
        named name: String,
        namespace: String,
        argTypes: [any WasmTypeProtocol.Type],
        block: @escaping ([any WasmTypeProtocol], UnsafeMutableRawPointer?) throws -> Void
    ) throws {
        let importedFunction: ImportedFunctionSignature = { stack, heap in
            do {
                var count = 0
                let args = try argTypes.map {
                    let value = try NativeFunction.argument(of: $0, from: stack, at: count)
                    count += 1
                    return value
                }
                try block(args, heap)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
        let sig = try signature(args: argTypes)
        try importNativeFunction(
            named: name,
            namespace: namespace,
            signature: sig,
            handler: importedFunction
        )
    }

    func addImportHandler<R: WasmTypeProtocol>(
        named name: String,
        namespace: String,
        argTypes: [any WasmTypeProtocol.Type],
        block: @escaping ([any WasmTypeProtocol]) throws -> R
    ) throws {
        let importedFunction: ImportedFunctionSignature = { stack, _ in
            do {
                var count = 1
                let args = try argTypes.map {
                    let value = try NativeFunction.argument(of: $0, from: stack, at: count)
                    count += 1
                    return value
                }
                let ret = try block(args)
                try NativeFunction.pushReturnValue(ret, to: stack)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
        let sig = try signature(args: argTypes, ret: R.self)
        try importNativeFunction(
            named: name,
            namespace: namespace,
            signature: sig,
            handler: importedFunction
        )
    }

    func addImportHandler<R: WasmTypeProtocol>(
        named name: String,
        namespace: String,
        argTypes: [any WasmTypeProtocol.Type],
        block: @escaping ([any WasmTypeProtocol], UnsafeMutableRawPointer?) throws -> R
    ) throws {
        let importedFunction: ImportedFunctionSignature = { stack, heap in
            do {
                var count = 1
                let args = try argTypes.map {
                    let value = try NativeFunction.argument(of: $0, from: stack, at: count)
                    count += 1
                    return value
                }
                let ret = try block(args, heap)
                try NativeFunction.pushReturnValue(ret, to: stack)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
        let sig = try signature(args: argTypes, ret: R.self)
        try importNativeFunction(
            named: name,
            namespace: namespace,
            signature: sig,
            handler: importedFunction
        )
    }
}
