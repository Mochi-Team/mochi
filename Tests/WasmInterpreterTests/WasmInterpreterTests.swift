//
//  WasmInterpreterTests.swift
//
//
//  Created by ErrorErrorError on 3/25/23.
//
//

import WasmInterpreter
import XCTest

final class WasmInterpreterTests: XCTestCase {
    func testAddModule() throws {
        let wasmAdd = [UInt8](Data(base64Encoded: "AGFzbQEAAAABBwFgAn9/AX8DAgEABwcBA2FkZAAACgkBBwAgACABags=") ?? .init())
        let interpreter = try WasmInterpreter(module: wasmAdd)
        let first: Int32 = 6
        let second: Int32 = 9
        let value: Int32 = try interpreter.add(first, second)
        XCTAssertEqual(value, first + second)
    }

    func testImportedModule() throws {
        let wasmImportedAddModule = [UInt8](
            Data(
                base64Encoded: "AGFzbQEAAAABCwJgAn9+AX9gAAF/Ah0BB2ltcG9ydHMRaW1wb3J0ZWRfYWRkX2Z1bmMAAAMCAQEHGQEVaW50ZWdlcl9wcm92aWRlcl9mdW5jAAEKCwEJAEH7ZUIqEAAL"
            ) ?? .init()
        )

        let interpreter = try WasmInterpreter(module: wasmImportedAddModule)
        try interpreter.addImportHandler(
            named: "imported_add_func",
            namespace: "imports",
            argTypes: [Int32.self, Int64.self],
            block: { args in
                let arg1 = Int64(wasm: args[0])
                let arg2 = Int64(wasm: args[1])
                return Int32(arg1 + arg2)
            }
        )

        let result = try Int(interpreter.integer_provider_func() as Int32)
        XCTAssertEqual(-3_291, result)
    }
}
