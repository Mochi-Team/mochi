//
//  Signature.swift
//
//
//  Created by ErrorErrorError on 4/5/23.
//
//

import Foundation

// MARK: - Signature

enum Signature {
    // swiftformat:disable redundantParens
    static func parse<each T: WasmValue>(
        _: (repeat (each T).Type),
        ret: WasmValueType? = nil
    ) -> String {
        var signature = ""
        signature += ret?.identifier ?? "v"
        signature += "("
        var args: [String] = []
        repeat (args.append((each T).wasmType.identifier))
        signature += args.joined(separator: " ")
        signature += ")"
        return signature
    }
}

private extension WasmValueType {
    var identifier: String {
        switch self {
        case .int32:
            "i"
        case .int64:
            "I"
        case .float32:
            "f"
        case .float64:
            "F"
        }
    }
}
