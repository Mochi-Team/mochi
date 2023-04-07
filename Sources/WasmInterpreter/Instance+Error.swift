//
//  Instance+Error.swift
//  
//
//  Created by ErrorErrorError on 4/3/23.
//  
//

import Foundation

extension WasmInstance {
    public enum Error: Swift.Error {
        case environment(EnvironmentError)
        case runtime(RuntimeError)
        case module(ModuleRuntime)
        case functions(FunctionsError)
        case memory(MemoryError)
        case wasm3Error(String)
    }
}

public extension WasmInstance.Error {
    enum EnvironmentError: Error {
        case failedToInitializeEnv
    }

    enum RuntimeError: Error {
        case failedToInitializeRuntime
    }

    enum ModuleRuntime: Error {
        case couldNotParseModule
    }

    enum FunctionsError: Error {
        case failedToFindFunction(named: String)
        case invalidFunctionReturnType
        case onCallFunction(String)
        case invalidStackPointer
        case unsupportedWasmType(String)
        case couldNotGenerateFunctionContext
    }

    enum MemoryError: Error {
        case invalidMemoryAccess
        case couldNotLoadMemory
        case invalidUTF8String
    }
}
