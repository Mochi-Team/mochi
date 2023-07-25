//
//  HostModuleInterop+Memory.swift
//
//
//  Created by ErrorErrorError on 4/25/23.
//
//

import ComposableArchitecture
import Foundation
import WasmInterpreter

// MARK: - MemoryInstance

/// MemoryInstance Protocol
///
/// allows for switching between simulated memory and wasm memory
protocol MemoryInstance {
    func write(with value: some WasmValue, byteOffset: Int) throws
    func write<T: WasmValue>(with values: [T], byteOffset: Int) throws
    func write(with bytes: [UInt8], byteOffset: Int) throws
    func write(with data: Data, byteOffset: Int) throws
    func write(with string: String, byteOffset: Int) throws

    func bytes(byteOffset: Int, length: Int) throws -> [UInt8]
    func data(byteOffset: Int, length: Int) throws -> Data
    func value<T: WasmValue>(byteOffset: Int) throws -> T
    func values<T: WasmValue>(byteOffset: Int, length: Int) throws -> [T]
    func string(byteOffset: Int, length: Int) throws -> String
}

// MARK: - WasmInstance.Memory + MemoryInstance

/// Wasm Instance memory access
///
extension WasmInstance.Memory: MemoryInstance {}

// MARK: - LocalMemoryInstance

/// Local memory instance which simulates a module memory
///
class LocalMemoryInstance: MemoryInstance {
    private let storage = LockIsolated<[Int: [UInt8]]>(.init())

    func write(with string: String, byteOffset: Int) throws {
        try write(with: Data(string.utf8), byteOffset: byteOffset)
    }

    func write(with data: Data, byteOffset: Int) throws {
        storage.withValue { alloc in
            var array = [UInt8](repeating: 0, count: data.count)
            data.copyBytes(to: &array, count: data.count)
            alloc[byteOffset] = array
        }
    }

    func write(with bytes: [UInt8], byteOffset: Int) throws {
        storage.withValue { alloc in
            alloc[byteOffset] = bytes
        }
    }

    func write(with value: some WasmValue, byteOffset: Int) throws {
        try write(with: [value], byteOffset: byteOffset)
    }

    func write<T: WasmValue>(with values: [T], byteOffset: Int) throws {
        var values = values
        try write(
            with: Data(bytes: &values, count: values.count * MemoryLayout<T>.size),
            byteOffset: byteOffset
        )
    }

    func value<T: WasmValue>(byteOffset: Int) throws -> T {
        let values: [T] = try values(byteOffset: byteOffset, length: 1)
        guard let value = values.first else {
            throw WasmInstance.Error.memory(.couldNotLoadMemory)
        }
        return value
    }

    func values<T: WasmValue>(byteOffset: Int, length: Int) throws -> [T] {
        try storage.withValue { alloc in
            guard let values = alloc[byteOffset] else {
                throw WasmInstance.Error.memory(.invalidMemoryAccess)
            }

            return values.withUnsafeBytes { bytesPtr in
                let pointer = bytesPtr.bindMemory(to: T.self)
                return (0..<length).map { pointer[$0] }
            }
        }
    }

    func bytes(byteOffset: Int, length _: Int) throws -> [UInt8] {
        try storage.withValue { alloc in
            guard let bytes = alloc[byteOffset] else {
                throw WasmInstance.Error.memory(.invalidMemoryAccess)
            }
            return bytes
        }
    }

    func data(byteOffset: Int, length _: Int) throws -> Data {
        try storage.withValue { alloc in
            guard var value = alloc[byteOffset] else {
                throw WasmInstance.Error.memory(.invalidMemoryAccess)
            }

            return .init(bytes: &value, count: value.count)
        }
    }

    func string(byteOffset: Int, length: Int) throws -> String {
        let data = try data(byteOffset: byteOffset, length: length)

        guard let string = String(data: data, encoding: .utf8) else {
            throw WasmInstance.Error.MemoryError.invalidUTF8String
        }
        return string
    }
}
