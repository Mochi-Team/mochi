//
//  TransformableValue.swift
//
//
//  Created by ErrorErrorError on 5/3/23.
//
//

import CoreData
import Foundation

// MARK: - TransformableValueError

enum TransformableValueError: Swift.Error {
  case failedToDecode(for: String, model: String)
  case failedToEncode(for: String, model: String)
  case failedToEncodeRelation(for: String, model: String)
  case invalidPrimitiveValueType(of: Any)
  case badInput(Any? = nil)
}

// MARK: - PrimitiveValue

public protocol PrimitiveValue {
  static var attributeType: NSAttributeType { get }
}

// MARK: - TransformableValue

public protocol TransformableValue {
  associatedtype Primitive: PrimitiveValue
  func encode() throws -> Primitive
  static func decode(value: Primitive) throws -> Self
}

extension TransformableValue {
  static func decode(_ value: Any?) throws -> Self {
    guard let value = value as? Primitive else {
      throw TransformableValueError.badInput(value)
    }
    return try Self.decode(value: value)
  }
}

extension TransformableValue where Self: PrimitiveValue {
  public func encode() throws -> Self { self }
  public static func decode(value: Self) throws -> Self { value }
}

extension Optional where Wrapped: TransformableValue {
  public typealias Primitive = Wrapped.Primitive

  public func encode() throws -> Primitive {
    guard let value = self else {
      throw TransformableValueError.badInput()
    }
    return try value.encode()
  }

  public static func decode(value: Primitive) throws -> Self {
    try Wrapped.decode(value: value)
  }
}

extension RawRepresentable where RawValue: TransformableValue {
  public func encode() throws -> RawValue.Primitive {
    try rawValue.encode()
  }

  public static func decode(value: RawValue.Primitive) throws -> Self {
    let rawValue = try RawValue.decode(value: value)
    guard let value = Self(rawValue: rawValue) else {
      throw TransformableValueError.badInput(rawValue)
    }
    return value
  }
}

// MARK: - Int + PrimitiveValue, TransformableValue

extension Int: PrimitiveValue, TransformableValue {
  public static var attributeType: NSAttributeType { .integer64AttributeType }
}

// MARK: - Int16 + PrimitiveValue, TransformableValue

extension Int16: PrimitiveValue, TransformableValue {
  public static var attributeType: NSAttributeType { .integer16AttributeType }
}

// MARK: - Int32 + PrimitiveValue, TransformableValue

extension Int32: PrimitiveValue, TransformableValue {
  public static var attributeType: NSAttributeType { .integer32AttributeType }
}

// MARK: - Int64 + PrimitiveValue, TransformableValue

extension Int64: PrimitiveValue, TransformableValue {
  public static var attributeType: NSAttributeType { .integer64AttributeType }
}

// MARK: - Float + PrimitiveValue, ConvertableValue

#if os(iOS)
extension Float16: PrimitiveValue, TransformableValue {
  public static var attributeType: NSAttributeType { .floatAttributeType }
}
#endif

// MARK: - Float32 + PrimitiveValue, TransformableValue

extension Float32: PrimitiveValue, TransformableValue {
  public static var attributeType: NSAttributeType { .floatAttributeType }
}

// MARK: - Double + PrimitiveValue, TransformableValue

extension Double: PrimitiveValue, TransformableValue {
  public static var attributeType: NSAttributeType { .doubleAttributeType }
}

// MARK: - Decimal + PrimitiveValue, TransformableValue

extension Decimal: PrimitiveValue, TransformableValue {
  public static var attributeType: NSAttributeType { .decimalAttributeType }
}

// MARK: - Bool + PrimitiveValue, TransformableValue

extension Bool: PrimitiveValue, TransformableValue {
  public static var attributeType: NSAttributeType { .booleanAttributeType }
}

// MARK: - Date + PrimitiveValue, TransformableValue

extension Date: PrimitiveValue, TransformableValue {
  public static var attributeType: NSAttributeType { .dateAttributeType }
}

// MARK: - String + PrimitiveValue, TransformableValue

extension String: PrimitiveValue, TransformableValue {
  public static var attributeType: NSAttributeType { .stringAttributeType }
}

// MARK: - Data + PrimitiveValue, TransformableValue

extension Data: PrimitiveValue, TransformableValue {
  public static var attributeType: NSAttributeType { .binaryDataAttributeType }
}

// MARK: - UUID + PrimitiveValue, TransformableValue

extension UUID: PrimitiveValue, TransformableValue {
  public static var attributeType: NSAttributeType { .UUIDAttributeType }
}

// MARK: - URL + PrimitiveValue, TransformableValue

extension URL: PrimitiveValue, TransformableValue {
  public static var attributeType: NSAttributeType { .URIAttributeType }
}

extension TransformableValue {
  func validate() throws {
    if Self.Primitive.self == Int.self {
      return
    } else if Self.Primitive.self == Int16.self {
      return
    } else if Self.Primitive.self == Int32.self {
      return
    } else if Self.Primitive.self == Int64.self {
      return
    } else if Self.Primitive.self == Float32.self {
      return
    } else if Self.Primitive.self == Double.self {
      return
    } else if Self.Primitive.self == Decimal.self {
      return
    } else if Self.Primitive.self == Bool.self {
      return
    } else if Self.Primitive.self == Date.self {
      return
    } else if Self.Primitive.self == String.self {
      return
    } else if Self.Primitive.self == Data.self {
      return
    } else if Self.Primitive.self == UUID.self {
      return
    } else if Self.Primitive.self == URL.self {
      return
    }

    #if os(iOS)
    if Self.Primitive.self == Float16.self {
      return
    }
    #endif

    throw TransformableValueError.invalidPrimitiveValueType(of: Self.self)
  }
}
