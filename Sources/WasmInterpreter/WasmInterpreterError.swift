import Foundation

public enum WasmInterpreterError: Error {
    case couldNotLoadEnvironment
    case couldNotLoadRuntime
    case couldNotLoadWasmBinary(String)
    case couldNotParseModule
    case couldNotLoadModule
    case couldNotFindFunction(String)
    case onCallFunction(String)
    case invalidFunctionReturnType
    case invalidStackPointer
    case invalidMemoryAccess
    case invalidUTF8String
    case couldNotGenerateFunctionContext
    case incorrectArguments
    case missingHeap
    case couldNotLoadMemory
    case couldNotBindMemory
    case unsupportedWasmType(String)
    case wasm3Error(String)
}
