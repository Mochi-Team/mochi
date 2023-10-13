import CWasm3
import Foundation

struct ArgumentExtractor {
    private var index: Int

    init(hasReturn: Bool) {
        self.index = hasReturn ? 1 : 0
    }

    mutating func extract<each T: WasmValue>(from stack: UnsafeMutablePointer<UInt64>?, _ itemType: (repeat (each T).Type)) throws -> (repeat each T) {
        (repeat try (self.retrieve(from: stack, (each T).self)))
    }

    mutating func retrieve<T: WasmValue>(from stack: UnsafeMutablePointer<UInt64>?, _: T.Type = T.self) throws -> T {
        guard let stack = UnsafeMutableRawPointer(stack) else {
            throw WasmInstance.Error.functions(.invalidStackPointer)
        }

        guard isValidWasmType(T.self) else {
            throw WasmInstance.Error.functions(.unsupportedWasmType(String(describing: T.self)))
        }

        let value = stack.load(
            fromByteOffset: index * MemoryLayout<Int64>.stride,
            as: T.self
        )
        index += 1
        return value
    }

    func push<T: WasmValue>(value: T, to stack: UnsafeMutablePointer<UInt64>?) throws {
        guard let stack = UnsafeMutableRawPointer(stack) else {
            throw WasmInstance.Error.functions(.invalidStackPointer)
        }
        guard isValidWasmType(T.self) else {
            throw WasmInstance.Error.functions(.unsupportedWasmType(String(describing: T.self)))
        }

        stack.storeBytes(of: value, as: T.self)
    }
}

private func isValidWasmType<T: WasmValue>(_: T.Type) -> Bool {
    Int32.self == T.self ||
        Int64.self == T.self ||
        Float32.self == T.self ||
        Float64.self == T.self
}
