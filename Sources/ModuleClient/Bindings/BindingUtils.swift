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
