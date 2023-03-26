import Foundation

extension String {
    init<T: WasmTypeProtocol>(wasmType: T) throws {
        if Int32.self == T.self {
            self = "\(wasmType as! Int32)"
        } else if Int64.self == T.self {
            self = "\(wasmType as! Int64)"
        } else if Float32.self == T.self {
            self = "\(wasmType as! Float32)"
        } else if Float64.self == T.self {
            self = "\(wasmType as! Float64)"
        } else {
            throw WasmInterpreterError.unsupportedWasmType(String(describing: wasmType.self))
        }
    }
}
