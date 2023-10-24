//
//  WasmValue.swift
//
//
//  Created by ErrorErrorError on 4/4/23.
//
//

import Foundation

// MARK: - WasmValue

public protocol WasmValue: CustomStringConvertible {
    static var wasmType: WasmValueType { get }

    init(_ value: Int32)
    init(_ value: Int64)
    init(_ value: Float32)
    init(_ value: Float64)
}

// MARK: - WasmValueType

public enum WasmValueType {
    case int32
    case int64
    case float32
    case float64
}

// MARK: - Int32 + WasmValue

extension Int32: WasmValue {
    public static var wasmType: WasmValueType { .int32 }
}

// MARK: - Int64 + WasmValue

extension Int64: WasmValue {
    public static var wasmType: WasmValueType { .int64 }
}

// MARK: - Float32 + WasmValue

extension Float32: WasmValue {
    public static var wasmType: WasmValueType { .float32 }
}

// MARK: - Float64 + WasmValue

extension Float64: WasmValue {
    public static var wasmType: WasmValueType { .float64 }
}
