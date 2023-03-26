import Foundation

func signature(args: [any WasmTypeProtocol.Type] = []) throws -> String {
    var signature = "v"
    signature += "("
    signature += try args.map {
        try signatureIdentifier(for: $0.self)
    }
    .joined(separator: " ")
    signature += ")"
    return signature
}

func signature(
    args: [any WasmTypeProtocol.Type] = [],
    ret: (some WasmTypeProtocol).Type
) throws -> String {
    var signature = ""
    signature += try signatureIdentifier(for: ret.self)
    signature += "("
    signature += try args.map {
        try signatureIdentifier(for: $0.self)
    }
    .joined(separator: " ")
    signature += ")"
    return signature
}

func signatureIdentifier<T: WasmTypeProtocol>(for _: T.Type) throws -> String {
    if Int32.self == T.self {
        return "i"
    } else if Int64.self == T.self {
        return "I"
    } else if Float32.self == T.self {
        return "f"
    } else if Float64.self == T.self {
        return "F"
    } else {
        throw WasmInterpreterError.unsupportedWasmType(String(describing: T.self))
    }
}
