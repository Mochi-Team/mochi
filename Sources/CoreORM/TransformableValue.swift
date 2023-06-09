//
//  Attrribute.swift
//
//
//  Created by ErrorErrorError on 5/3/23.
//
//

import CoreData
import Foundation

// MARK: - ConvertableValueError

enum ConvertableValueError: Swift.Error {
    case failedToDecode(for: String, model: String)
    case failedToEncode(for: String, model: String)
    case failedToEncodeRelation(for: String, model: String)
    case badInput(Any?)
}

// MARK: - PrimitiveType

public protocol PrimitiveType {
    static var attributeType: NSAttributeType { get }
}

// MARK: - TransformableValue

public protocol TransformableValue {
    associatedtype PrimitiveValue: PrimitiveType
    func encode() -> PrimitiveValue
    static func decode(value: PrimitiveValue) throws -> Self
}

extension TransformableValue {
    static var _attributeType: NSAttributeType { PrimitiveValue.attributeType }
}

public extension TransformableValue where Self: PrimitiveType {
    func encode() -> Self { self }
    static func decode(value: Self) throws -> Self { value }
}

extension TransformableValue {
    static func decode(_ some: Any?) throws -> Self {
        guard let value = some as? Self.PrimitiveValue else {
            throw ConvertableValueError.badInput(some)
        }
        return try Self.decode(value: value)
    }
}

extension Optional where Wrapped: TransformableValue {
    static func decode(_ anyValue: Any?) throws -> Wrapped? {
        try anyValue.flatMap { value in
            try Wrapped.decode(value)
        }
    }
}

public extension RawRepresentable where RawValue: TransformableValue {
    func encode() -> RawValue.PrimitiveValue {
        rawValue.encode()
    }

    static func decode(value: RawValue.PrimitiveValue) throws -> Self {
        let rawValue = try RawValue.decode(value: value)
        guard let value = Self(rawValue: rawValue) else {
            throw ConvertableValueError.badInput(rawValue)
        }
        return value
    }
}

// MARK: - Int + PrimitiveType, TransformableValue

extension Int: PrimitiveType, TransformableValue {
    public static var attributeType: NSAttributeType { .integer64AttributeType }
}

// MARK: - Int16 + PrimitiveType, TransformableValue

extension Int16: PrimitiveType, TransformableValue {
    public static var attributeType: NSAttributeType { .integer16AttributeType }
}

// MARK: - Int32 + PrimitiveType, TransformableValue

extension Int32: PrimitiveType, TransformableValue {
    public static var attributeType: NSAttributeType { .integer32AttributeType }
}

// MARK: - Int64 + PrimitiveType, TransformableValue

extension Int64: PrimitiveType, TransformableValue {
    public static var attributeType: NSAttributeType { .integer64AttributeType }
}

// MARK: - Float + PrimitiveType, ConvertableValue

#if os(iOS)
extension Float16: PrimitiveType, TransformableValue {
    public static var attributeType: NSAttributeType { .floatAttributeType }
}
#endif

// MARK: - Float32 + PrimitiveType, TransformableValue

extension Float32: PrimitiveType, TransformableValue {
    public static var attributeType: NSAttributeType { .floatAttributeType }
}

// MARK: - Double + PrimitiveType, TransformableValue

extension Double: PrimitiveType, TransformableValue {
    public static var attributeType: NSAttributeType { .doubleAttributeType }
}

// MARK: - Decimal + PrimitiveType, TransformableValue

extension Decimal: PrimitiveType, TransformableValue {
    public static var attributeType: NSAttributeType { .decimalAttributeType }
}

// MARK: - Bool + PrimitiveType, TransformableValue

extension Bool: PrimitiveType, TransformableValue {
    public static var attributeType: NSAttributeType { .booleanAttributeType }
}

// MARK: - Date + PrimitiveType, TransformableValue

extension Date: PrimitiveType, TransformableValue {
    public static var attributeType: NSAttributeType { .dateAttributeType }
}

// MARK: - String + PrimitiveType, TransformableValue

extension String: PrimitiveType, TransformableValue {
    public static var attributeType: NSAttributeType { .stringAttributeType }
}

// MARK: - Data + PrimitiveType, TransformableValue

extension Data: PrimitiveType, TransformableValue {
    public static var attributeType: NSAttributeType { .binaryDataAttributeType }
}

// MARK: - UUID + PrimitiveType, TransformableValue

extension UUID: PrimitiveType, TransformableValue {
    public static var attributeType: NSAttributeType { .UUIDAttributeType }
}

// MARK: - URL + PrimitiveType, TransformableValue

extension URL: PrimitiveType, TransformableValue {
    public static var attributeType: NSAttributeType { .URIAttributeType }
}
