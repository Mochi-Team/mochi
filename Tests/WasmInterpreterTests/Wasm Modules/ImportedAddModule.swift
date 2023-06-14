import Foundation
import WasmInterpreter

public struct ImportedAddModule {
    private let _vm: WasmInstance

    init() throws {
        self._vm = try .init(module: Self.wasm) {
            WasmInstance.Import(namespace: "imports") {
                WasmInstance.Function("imported_add_func") { (arg1: Int32, arg2: Int64) -> Int32 in
                    Int32(Int64(arg1) + arg2)
                }
            }
        }
    }

    func askModuleToCallImportedFunction() throws -> Int {
        try Int(_vm.exports.integer_provider_func() as Int32)
    }

    // `wat2wasm -o >(base64) Tests/WasmInterpreterTests/Resources/imported-add.wat | pbcopy`
    private static var wasm: [UInt8] {
        let base64 =
            "AGFzbQEAAAABCwJgAn9+AX9gAAF/Ah0BB2ltcG9ydHMRaW1wb3J0ZWRfYWRkX2Z1bmMAAAMCAQEHGQEVaW50ZWdlcl9wcm92aWRlcl9mdW5jAAEKCwEJAEH7ZUIqEAAL"
        return [UInt8](Data(base64Encoded: base64) ?? .init())
    }
}
