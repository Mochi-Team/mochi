//
//  File.swift
//  
//
//  Created by ErrorErrorError on 4/4/23.
//  
//

import Foundation

public protocol WasmValue: CustomStringConvertible {
    static var wasmType: WasmValueType { get }

    init(_ value: Int32)
    init(_ value: Int64)
    init(_ value: Float32)
    init(_ value: Float64)
}

public enum WasmValueType {
    case int32
    case int64
    case float32
    case float64
}

extension Int32: WasmValue {
    public static var wasmType: WasmValueType { .int32 }
}

extension Int64: WasmValue {
    public static var wasmType: WasmValueType { .int64 }
}

extension Float32: WasmValue {
    public static var wasmType: WasmValueType { .float32 }
}

extension Float64: WasmValue {
    public static var wasmType: WasmValueType { .float64 }
}
