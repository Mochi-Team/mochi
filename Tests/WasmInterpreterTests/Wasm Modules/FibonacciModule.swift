import Foundation
import WasmInterpreter

public struct FibonacciModule {
    private let _vm: WasmInstance

    init() throws {
//        _vm = try .init(module: Self.wasmURL, stackSize: 1 * 1024 * 1024)
        _vm = try .init(module: Self.wasm, stackSize: 1 * 1_024 * 1_024)
    }

    func calculateValue(at index: Int) throws -> Int {
        Int(try _vm.exports.fib(Int64(index)) as Int64)
    }

    // `wat2wasm -o >(base64) Tests/WasmInterpreterTests/Resources/fib64.wat | pbcopy`
    private static var wasm: [UInt8] {
        let base64 =
            "AGFzbQEAAAABBgFgAX4BfgMCAQAHBwEDZmliAAAKHwEdACAAQgJUBEAgAA8LIABCAn0QACAAQgF9EAB8Dws="
        return [UInt8](Data(base64Encoded: base64) ?? .init())
    }

    private static var wasmURL: URL {
        URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources")
            .appendingPathComponent("fib64.wasm")
    }
}
