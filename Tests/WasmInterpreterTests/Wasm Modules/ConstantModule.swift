import Foundation
import WasmInterpreter

public struct ConstantModule {
    private let _vm: WasmInstance

    init() throws {
        _vm = try .init(module: Self.wasm)
    }

    func constant(version: Int) throws -> Int {
        Int(try _vm.exports[dynamicMember: "constant_\(version)"]() as Int32)
    }

    // `wat2wasm -o >(base64) Tests/WasmInterpreterTests/Resources/constant.wat | pbcopy`
    private static var wasm: [UInt8] {
        // swiftlint:disable line_length
        let base64 =
            "AGFzbQEAAAABBQFgAAF/AwIBAAeSAQsKY29uc3RhbnRfMQAACmNvbnN0YW50XzIAAApjb25zdGFudF8zAAAKY29uc3RhbnRfNAAACmNvbnN0YW50XzUAAApjb25zdGFudF82AAAKY29uc3RhbnRfNwAACmNvbnN0YW50XzgAAApjb25zdGFudF85AAALY29uc3RhbnRfMTAAAAtjb25zdGFudF8xMQAACggBBgBBgIAECw=="
        return [UInt8](Data(base64Encoded: base64) ?? .init())
    }
}
