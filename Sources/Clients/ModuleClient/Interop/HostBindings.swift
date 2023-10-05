//
//  HostBindings.swift
//
//
//  Created by ErrorErrorError on 7/28/23.
//
//

import ConcurrencyExtras
import Foundation
import SwiftSoup
import WasmInterpreter

/// This is a raw pointer that points into wasm's memory
///
typealias RawPtr = Int32

/// This is a pointer that points to an object stored in host's memory
///
typealias PtrRef = Int32

/// This is a pointer that points to a host's network request memory
///
typealias ReqRef = Int32

// MARK: - PtrKind

enum PtrKind: Int32 {
    case unknown
    case null
    case object
    case array
    case string
    case number
    case bool
    case node
}

// MARK: - HostBindings

/// This class allows bridging bindings to swift
///
class HostBindings<M: Memory>: NSObject {
    let memory: M
    let hostAllocations = LockIsolated<[PtrRef: Any?]>([:])

    init(memory: M) {
        self.memory = memory
    }

    func addToHostMemory(_ obj: Any?) -> PtrRef {
        hostAllocations.withValue { $0.add(obj) }
    }

    func getHostObject(_ ptr: PtrRef) -> Any? {
        guard let value = hostAllocations[ptr] else {
            return nil
        }
        return value
    }

    func handleErrorAlloc<R: WasmValue>(
        func _: String = #function,
        _ callback: (inout [PtrRef: Any?]) throws -> R
    ) -> R {
        hostAllocations.withValue { alloc in
            do {
                return try callback(&alloc)
            } catch let error as SwiftSoup.Exception {
                return .init(alloc.addError(.swiftSoup(error)))
            } catch let error as WasmInstance.Error {
                return .init(alloc.addError(.wasm3(error)))
            } catch let error as ModuleClient.Error {
                return .init(alloc.addError(error))
            } catch {
                return .init(alloc.addError(.unknown()))
            }
        }
    }
}

// MARK: - Memory

/// MemoryInstance Protocol
///
/// allows for switching between simulated memory and wasm memory
protocol Memory {
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

// MARK: - WasmInstance.Memory + Memory

/// Wasm Instance memory access
///
extension WasmInstance.Memory: Memory {}

extension [PtrRef: Any?] {
    mutating func add(_ value: Value) -> Int32 {
        let nextId = Swift.max((keys.max() ?? 0) + 1, 0)
        self[nextId] = value
        return nextId
    }

    mutating func addError(_ value: ModuleClient.Error) -> Int32 {
        let nextId = Swift.min((keys.min() ?? 0) - 1, -1)
        self[nextId] = value
        return nextId
    }
}
