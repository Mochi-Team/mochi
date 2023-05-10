//
//  File 2.swift
//  
//
//  Created by ErrorErrorError on 4/5/23.
//  
//

import CWasm3
import Foundation

extension WasmInstance {
    public final class Memory {
        private let _runtime: IM3Runtime

        init(runtime: IM3Runtime) {
            self._runtime = runtime
        }
    }
}

// MARK: Read from Heap

public extension WasmInstance.Memory {
    func string(byteOffset: Int, length: Int) throws -> String {
        let data = try data(byteOffset: byteOffset, length: length)

        guard let string = String(data: data, encoding: .utf8) else {
            throw WasmInstance.Error.memory(.invalidUTF8String)
        }
        return string
    }

    func value<T: WasmValue>(byteOffset: Int) throws -> T {
        let values: [T] = try values(byteOffset: byteOffset, length: 1)
        guard let value = values.first else {
            throw WasmInstance.Error.memory(.couldNotLoadMemory)
        }
        return value
    }

    func values<T: WasmValue>(byteOffset: Int, length: Int) throws -> [T] {
        let heap = try heap()

        guard heap.isValid(byteOffset: byteOffset, length: length) else {
            throw WasmInstance.Error.memory(.invalidMemoryAccess)
        }

        let bufferPointer = UnsafeRawPointer(heap.pointer)
            .advanced(by: byteOffset)
            .bindMemory(to: T.self, capacity: length)

        return (0..<length).map { bufferPointer[$0] }
    }

    func data(byteOffset: Int, length: Int) throws -> Data {
        let heap = try heap()

        guard heap.isValid(byteOffset: byteOffset, length: length) else {
            throw WasmInstance.Error.memory(.invalidMemoryAccess)
        }

        return .init(
            bytes: heap.pointer.advanced(by: byteOffset),
            count: length
        )
    }

    func bytes(byteOffset: Int, length: Int) throws -> [UInt8] {
        let heap = try heap()

        guard heap.isValid(byteOffset: byteOffset, length: length) else {
            throw WasmInstance.Error.memory(.invalidMemoryAccess)
        }

        let bufferPointer = UnsafeBufferPointer(
            start: heap.pointer.advanced(by: byteOffset),
            count: length
        )

        return .init(bufferPointer)
    }
}

// MARK: Write to Heap

public extension WasmInstance.Memory {
    func write(with string: String, byteOffset: Int) throws {
        try write(with: Data(string.utf8), byteOffset: byteOffset)
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

    func write(with data: Data, byteOffset: Int) throws {
        let heap = try heap()

        guard heap.isValid(byteOffset: byteOffset, length: data.count) else {
            throw WasmInstance.Error.memory(.invalidMemoryAccess)
        }

        try data.withUnsafeBytes { ptr in
            guard let pointer = ptr.bindMemory(to: UInt8.self).baseAddress else {
                throw WasmInstance.Error.memory(.invalidMemoryAccess)
            }
            heap.pointer
                .advanced(by: byteOffset)
                .initialize(from: pointer, count: ptr.count)
        }
    }

    func write(with bytes: [UInt8], byteOffset: Int) throws {
        let heap = try heap()

        guard heap.isValid(byteOffset: byteOffset, length: bytes.count) else {
            throw WasmInstance.Error.memory(.invalidMemoryAccess)
        }

        heap.pointer
            .advanced(by: byteOffset)
            .initialize(from: bytes, count: bytes.count)
    }
}

extension WasmInstance.Memory {
    private struct Heap {
        let pointer: UnsafeMutablePointer<UInt8>
        let size: Int

        func isValid(byteOffset: Int, length: Int) -> Bool {
            0 <= byteOffset + length && byteOffset + length <= size
        }
    }

    private func heap() throws -> Heap {
        let totalBytes = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
        defer { totalBytes.deallocate() }

        guard let bytesPointer = m3_GetMemory(_runtime, totalBytes, 0) else {
            throw WasmInstance.Error.memory(.invalidMemoryAccess)
        }

        return .init(pointer: bytesPointer, size: .init(totalBytes.pointee))
    }
}
