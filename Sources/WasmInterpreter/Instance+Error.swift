//
//  Instance+Error.swift
//
//
//  Created by ErrorErrorError on 4/3/23.
//
//

import Foundation

// MARK: - WasmInstance.Error

public extension WasmInstance {
    enum Error: Swift.Error, Equatable, Sendable {
        case environment(EnvironmentError)
        case runtime(RuntimeError)
        case module(ModuleRuntime)
        case functions(FunctionsError)
        case memory(MemoryError)
        case wasm3Error(String)
    }
}

public extension WasmInstance.Error {
    enum EnvironmentError: Error, Equatable, Sendable {
        case failedToInitializeEnv
    }

    enum RuntimeError: Error, Equatable, Sendable {
        case failedToInitializeRuntime
    }

    enum ModuleRuntime: Error, Equatable, Sendable {
        case couldNotParseModule
    }

    enum FunctionsError: Error, Equatable, Sendable {
        case failedToFindFunction(named: String, error: String)
        case invalidFunctionReturnType
        case onCallFunction(String)
        case invalidStackPointer
        case unsupportedWasmType(String)
        case couldNotGenerateFunctionContext
        case failedToImportFunction(String)
    }

    enum MemoryError: Error, Equatable, Sendable {
        case invalidMemoryAccess
        case couldNotLoadMemory
        case invalidUTF8String
    }
}
