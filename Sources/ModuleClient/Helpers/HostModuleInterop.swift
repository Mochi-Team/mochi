//
//  HostModuleInterop.swift
//
//
//  Created by ErrorErrorError on 4/25/23.
//
//

import ComposableArchitecture
import Foundation
import SharedModels
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

enum HTTPMethod: Int32 {
    case get
    case post
    case put
    case patch
    case delete
}

/// This class allows testability of models memory/transformations.
///
struct HostModuleInterop<M: MemoryInstance> {
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
}

// MARK: - Misc

extension HostModuleInterop {
    func handleErrorAlloc<R: WasmValue>(
        func: String = #function,
        _ callback: (inout [PtrRef: Any?]) throws -> R
    ) -> R {
        self.hostAllocations.withValue { alloc in
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
