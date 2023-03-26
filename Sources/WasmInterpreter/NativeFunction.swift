import CWasm3
import Foundation

// MARK: - NativeFunction

struct NativeFunction {
    static func argument(
        of type: (some WasmTypeProtocol).Type,
        from stack: UnsafeMutablePointer<UInt64>?,
        at index: Int
    ) throws -> some WasmTypeProtocol {
        guard let stack = UnsafeMutableRawPointer(stack)
        else {
            throw WasmInterpreterError.invalidStackPointer
        }
        guard isValidWasmType(type.self) else {
            throw WasmInterpreterError.unsupportedWasmType(String(describing: type.self))
        }

        return stack.load(
            fromByteOffset: index * MemoryLayout<Int64>.stride,
            as: type.self
        )
    }

    static func argument<Arg: WasmTypeProtocol>(
        from stack: UnsafeMutablePointer<UInt64>?,
        at index: Int
    ) throws -> Arg {
        guard let stack = UnsafeMutableRawPointer(stack)
        else {
            throw WasmInterpreterError.invalidStackPointer
        }
        guard isValidWasmType(Arg.self) else {
            throw WasmInterpreterError.unsupportedWasmType(String(describing: Arg.self))
        }

        return stack.load(
            fromByteOffset: index * MemoryLayout<Int64>.stride,
            as: Arg.self
        )
    }

    /// Extracts the imported function's arguments of the specified types from the stack.
    ///
    /// - Throws: Throws if the stack pointer is `nil`.
    ///
    /// - Parameters:
    ///   - types: The expected argument types.
    ///   - stack: The stack pointer.
    ///
    /// - Returns: Array of the imported function's arguments.
    static func arguments(
        withTypes types: [WasmType],
        from stack: UnsafeMutablePointer<UInt64>?
    ) throws -> [WasmValue] {
        guard let stack = UnsafeMutableRawPointer(stack)
        else {
            throw WasmInterpreterError.invalidStackPointer
        }

        var values = [WasmValue]()
        for (index, type) in types.enumerated() {
            switch type {
            case .int32:
                let value = stack.load(
                    fromByteOffset: index * MemoryLayout<Int64>.stride,
                    as: Int32.self
                )
                values.append(WasmValue.int32(value))
            case .int64:
                let value = stack.load(
                    fromByteOffset: index * MemoryLayout<Int64>.stride,
                    as: Int64.self
                )
                values.append(WasmValue.int64(value))
            case .float32:
                let value = stack.load(
                    fromByteOffset: index * MemoryLayout<Int64>.stride,
                    as: Float32.self
                )
                values.append(WasmValue.float32(value))
            case .float64:
                let value = stack.load(
                    fromByteOffset: index * MemoryLayout<Int64>.stride,
                    as: Float64.self
                )
                values.append(WasmValue.float64(value))
            }
        }

        return values
    }

    /// Places the specified return value on the stack.
    ///
    /// - Throws: Throws if the stack pointer is `nil` or if `Ret` is not of type
    /// `Int32`, `Int64`, `Float32`, or `Float64`.
    ///
    /// - Parameters:
    ///   - ret: The value to return from the imported function.
    ///   - stack: The stack pointer.
    static func pushReturnValue<Ret: WasmTypeProtocol>(
        _ ret: Ret,
        to stack: UnsafeMutablePointer<UInt64>?
    ) throws {
        guard let stack = UnsafeMutableRawPointer(stack)
        else {
            throw WasmInterpreterError.invalidStackPointer
        }
        guard isValidWasmType(Ret.self) else {
            throw WasmInterpreterError.unsupportedWasmType(String(describing: Ret.self))
        }

        stack.storeBytes(of: ret, as: Ret.self)
    }

    /// Places the specified return value on the stack.
    ///
    /// - Throws: Throws if the stack pointer is `nil`.
    ///
    /// - Parameters:
    ///   - ret: The value to return from the imported function.
    ///   - stack: The stack pointer.
    static func pushReturnValue(
        _ ret: WasmValue,
        to stack: UnsafeMutablePointer<UInt64>?
    ) throws {
        guard let stack = UnsafeMutableRawPointer(stack)
        else {
            throw WasmInterpreterError.invalidStackPointer
        }

        switch ret {
        case let .int32(value):
            stack.storeBytes(of: value, as: Int32.self)
        case let .int64(value):
            stack.storeBytes(of: value, as: Int64.self)
        case let .float32(value):
            stack.storeBytes(of: value, as: Float32.self)
        case let .float64(value):
            stack.storeBytes(of: value, as: Float64.self)
        }
    }
}

let importedFunctionInternalError = UnsafeRawPointer(UnsafeMutableRawPointer.allocate(
    byteCount: _importedFunctionInternalError.count, alignment: MemoryLayout<CChar>.alignment
))
private let _importedFunctionInternalError = "ImportedFunctionInternalError".utf8CString
