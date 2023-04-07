//
//  Swift + CChar.swift
//
//
//  Created by ErrorErrorError on 4/5/23.
//
//

import Foundation

extension [String] {
    enum StringCCharError: Error {
        case memoryPointerFailed
    }

    func withCStrings<Result>(
        _ body: ([UnsafePointer<CChar>?]) throws -> Result
    ) rethrows -> Result {
        let lengths = map { $0.utf8.count + 1 }
        let (offsets, totalLength) = lengths.offsetsAndTotalLength()

        var buffer: [UInt8] = []
        buffer.reserveCapacity(totalLength)
        for string in self {
            buffer.append(contentsOf: string.utf8)
            buffer.append(0)
        }

        return try buffer.withUnsafeBufferPointer { buffer -> Result in
            guard let baseAddress = buffer.baseAddress else {
                throw StringCCharError.memoryPointerFailed
            }
            let pointer = UnsafeRawPointer(baseAddress)
                .bindMemory(to: CChar.self, capacity: buffer.count)
            var cStrings: [UnsafePointer<CChar>?] = offsets.map { pointer + $0 }
            cStrings.append(nil)
            return try body(cStrings)
        }
    }
}

private extension [Int] {
    func offsetsAndTotalLength() -> ([Int], Int) {
        var output = [0]
        var total = 0
        for length in self {
            total += length
            output.append(total)
        }
        return (output.dropLast(), total)
    }
}
