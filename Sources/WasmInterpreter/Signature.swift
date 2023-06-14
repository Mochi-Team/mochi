//
//  File.swift
//
//
//  Created by ErrorErrorError on 4/5/23.
//
//

import Foundation

// MARK: - Signature

enum Signature {
    static func generate(
        args: WasmValueType...,
        ret: WasmValueType? = nil
    ) -> String {
        generate(args: args, ret: ret)
    }

    static func generate(
        args: [WasmValueType],
        ret: WasmValueType? = nil
    ) -> String {
        var signature = ""
        signature += ret?.signatureIdentifier ?? "v"
        signature += "("
        signature += args.map(\.signatureIdentifier)
            .joined(separator: " ")
        signature += ")"
        return signature
    }
}

private extension WasmValueType {
    var signatureIdentifier: String {
        switch self {
        case .int32:
            return "i"
        case .int64:
            return "I"
        case .float32:
            return "f"
        case .float64:
            return "F"
        }
    }
}
