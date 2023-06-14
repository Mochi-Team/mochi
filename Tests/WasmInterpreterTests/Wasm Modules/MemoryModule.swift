import Foundation
import WasmInterpreter

public struct MemoryModule {
    private let _vm: WasmInstance

    init() throws {
        self._vm = try .init(module: Self.wasm)
    }

    func string(at byteOffset: Int, length: Int) throws -> String {
        try _vm.memory.string(byteOffset: byteOffset, length: length)
    }

    func integers(at byteOffset: Int, length: Int) throws -> [Int] {
        try (_vm.memory.values(byteOffset: byteOffset, length: length) as [Int32])
            .map(Int.init)
    }

    func asciiString(at byteOffset: Int, length: Int) throws -> String {
        try String(
            _vm.memory.bytes(byteOffset: byteOffset, length: length)
                .map(UnicodeScalar.init)
                .map(Character.init)
        )
    }

    func write(_ string: String, to byteOffset: Int) throws {
        try _vm.memory.write(with: string, byteOffset: byteOffset)
    }

    func write(_ integers: [Int], to byteOffset: Int) throws {
        try _vm.memory.write(with: integers.map(Int32.init), byteOffset: byteOffset)
    }

    func writeASCIICharacters(in string: String, to byteOffset: Int) throws {
        let bytes = string.compactMap(\.asciiValue)

        enum Error: Swift.Error {
            case invalidString(String)
        }

        guard string.count == bytes.count else {
            throw Error.invalidString(string)
        }

        try _vm.memory.write(with: bytes, byteOffset: byteOffset)
    }

    // `wat2wasm -o >(base64) Tests/WasmInterpreterTests/Resources/memory.wat | pbcopy`
    private static var wasm: [UInt8] {
        let base64 = "AGFzbQEAAAAFAwEAAQ=="
        return [UInt8](Data(base64Encoded: base64) ?? .init())
    }
}
