import CWasm3
import Foundation

// MARK: - NativeFunction

enum NativeFunction {
    static func argument<Arg: WasmValue>(
        from stack: UnsafeMutablePointer<UInt64>?,
        at index: Int
    ) throws -> Arg {
        guard let stack = UnsafeMutableRawPointer(stack)
        else {
            throw WasmInstance.Error.functions(.invalidStackPointer)
        }
        guard isValidWasmType(Arg.self) else {
            throw WasmInstance.Error.functions(.unsupportedWasmType(String(describing: Arg.self)))
        }

        return stack.load(
            fromByteOffset: index * MemoryLayout<Int64>.stride,
            as: Arg.self
        )
    }

    /// Places the specified return value on the stack.
    ///
    /// - Throws: Throws if the stack pointer is `nil` or if `Ret` is not of type
    /// `Int32`, `Int64`, `Float32`, or `Float64`.
    ///
    /// - Parameters:
    ///   - ret: The value to return from the imported function.
    ///   - stack: The stack pointer.
    static func pushReturnValue<Ret: WasmValue>(
        _ ret: Ret,
        to stack: UnsafeMutablePointer<UInt64>?
    ) throws {
        guard let stack = UnsafeMutableRawPointer(stack) else {
            throw WasmInstance.Error.functions(.invalidStackPointer)
        }
        guard isValidWasmType(Ret.self) else {
            throw WasmInstance.Error.functions(.unsupportedWasmType(String(describing: Ret.self)))
        }

        stack.storeBytes(of: ret, as: Ret.self)
    }
}

func isValidWasmType<T: WasmValue>(_: T.Type) -> Bool {
    Int32.self == T.self ||
        Int64.self == T.self ||
        Float32.self == T.self ||
        Float64.self == T.self
}
