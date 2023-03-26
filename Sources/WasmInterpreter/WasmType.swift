import Foundation

// MARK: - WasmTypeProtocol

public protocol WasmTypeProtocol {
    init(_ value: WasmValue)
    var wasmValue: WasmValue { get }
}

public extension WasmTypeProtocol {
    init(wasm value: some WasmTypeProtocol) {
        self.init(value.wasmValue)
    }
}

// MARK: - Int32 + WasmTypeProtocol

extension Int32: WasmTypeProtocol {
    public init(_ value: WasmValue) {
        switch value {
        case let .int32(int32):
            self.init(int32)
        case let .int64(int64):
            self.init(int64)
        case let .float32(float32):
            self.init(float32)
        case let .float64(float64):
            self.init(float64)
        }
    }

    public var wasmValue: WasmValue { .int32(self) }
}

// MARK: - Int64 + WasmTypeProtocol

extension Int64: WasmTypeProtocol {
    public init(_ value: WasmValue) {
        switch value {
        case let .int32(int32):
            self.init(int32)
        case let .int64(int64):
            self.init(int64)
        case let .float32(float32):
            self.init(float32)
        case let .float64(float64):
            self.init(float64)
        }
    }

    public var wasmValue: WasmValue { .int64(self) }
}

// MARK: - Float32 + WasmTypeProtocol

extension Float32: WasmTypeProtocol {
    public init(_ value: WasmValue) {
        switch value {
        case let .int32(int32):
            self.init(int32)
        case let .int64(int64):
            self.init(int64)
        case let .float32(float32):
            self.init(float32)
        case let .float64(float64):
            self.init(float64)
        }
    }

    public var wasmValue: WasmValue { .float32(self) }
}

// MARK: - Float64 + WasmTypeProtocol

extension Float64: WasmTypeProtocol {
    public init(_ value: WasmValue) {
        switch value {
        case let .int32(int32):
            self.init(int32)
        case let .int64(int64):
            self.init(int64)
        case let .float32(float32):
            self.init(float32)
        case let .float64(float64):
            self.init(float64)
        }
    }

    public var wasmValue: WasmValue { .float64(self) }
}

func isValidWasmType<T: WasmTypeProtocol>(_: T.Type) -> Bool {
    Int32.self == T.self ||
        Int64.self == T.self ||
        Float32.self == T.self ||
        Float64.self == T.self
}

// MARK: - WasmType

enum WasmType: Hashable {
    case int32
    case int64
    case float32
    case float64
}

// MARK: - WasmValue

public enum WasmValue: Hashable {
    case int32(Int32)
    case int64(Int64)
    case float32(Float32)
    case float64(Float64)
}
