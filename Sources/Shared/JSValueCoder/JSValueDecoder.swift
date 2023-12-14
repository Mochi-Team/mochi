//
//  JSValueDecoder.swift
//
//
//  Created by ErrorErrorError on 11/4/23.
//
//  from https://github.com/theolampert/JSValueCoder

import Foundation
import JavaScriptCore

// MARK: - JSValueDecoder

@dynamicMemberLookup
public class JSValueDecoder {
  public typealias DataDecodingStrategy = JSONDecoder.DataDecodingStrategy
  public typealias NonConformingFloatDecodingStrategy = JSONDecoder.NonConformingFloatDecodingStrategy
  public typealias DateDecodingStrategy = JSONDecoder.DateDecodingStrategy
  public typealias KeyDecodingStrategy = JSONDecoder.KeyDecodingStrategy

  public init() {}

  var options: Options = .init()
  var userInfo: [CodingUserInfoKey: Any] = [:]

  public struct Options {
    public var dataDecodingStrategy = DataDecodingStrategy.base64
    public var nonConformingFloatDecodingStrategy = NonConformingFloatDecodingStrategy.throw
    public var dateDecodingStrategy = DateDecodingStrategy.deferredToDate
    public var keyDecodingStrategy = KeyDecodingStrategy.useDefaultKeys
  }

  public subscript<V>(dynamicMember keyPath: WritableKeyPath<Options, V>) -> V {
    get { self.options[keyPath: keyPath] }
    set { self.options[keyPath: keyPath] = newValue }
  }

  public func decode<T: Decodable>(_ type: T.Type, from value: JSValue) throws -> T {
    try type.init(
      from: Decoder(
        value: value,
        options: options,
        userInfo: userInfo
      )
    )
  }
}

// MARK: JSValueDecoder.Decoder

extension JSValueDecoder {
  fileprivate struct Decoder {
    let value: JSValue
    var codingPath: [CodingKey]
    let userInfo: [CodingUserInfoKey: Any]
    let options: Options

    init(
      parent: Self,
      key: CodingKey
    ) {
      self.init(parent: parent, value: parent.value, key: key)
    }

    init(
      parent: Self,
      value: JSValue,
      key: CodingKey
    ) {
      self.init(
        value: value,
        codingPath: parent.codingPath + [key],
        options: parent.options,
        userInfo: parent.userInfo
      )
    }

    init(
      value: JSValue,
      codingPath: [CodingKey] = [],
      options: Options,
      userInfo: [CodingUserInfoKey: Any]
    ) {
      self.value = value
      self.codingPath = codingPath
      self.options = options
      self.userInfo = userInfo
    }
  }
}

// MARK: - JSValueDecoder.Decoder + Decoder

extension JSValueDecoder.Decoder: Decoder {
  @usableFromInline
  func container<Key: CodingKey>(keyedBy _: Key.Type) throws -> KeyedDecodingContainer<Key> {
    KeyedDecodingContainer(KeyedContainer(self))
  }

  @usableFromInline
  func unkeyedContainer() throws -> UnkeyedDecodingContainer {
    UnkeyedContainer(self)
  }

  @usableFromInline
  func singleValueContainer() throws -> SingleValueDecodingContainer {
    self
  }

  func decodeKey(_ codingKey: CodingKey) -> CodingKey {
    switch options.keyDecodingStrategy {
    case .useDefaultKeys:
      codingKey
    case .convertFromSnakeCase:
      JSValueCodingKey(convertingFromSnakeCase: codingKey)
    case let .custom(block):
      block(codingPath + [codingKey])
    @unknown default:
      fatalError("\(options.keyDecodingStrategy) is not supported")
    }
  }
}

// MARK: - JSValueDecoder.Decoder.KeyedContainer

extension JSValueDecoder.Decoder {
  struct KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    var codingPath: [CodingKey] { decoder.codingPath }
    var allKeys: [Key] { decoder.value.toDictionary()?.keys.compactMap { ($0 as? String).flatMap(Key.init) } ?? [] }

    private let decoder: JSValueDecoder.Decoder

    init(_ decoder: JSValueDecoder.Decoder) {
      self.decoder = decoder
    }

    func contains(_ key: Key) -> Bool { decoder.value.hasProperty(decoder.decodeKey(key).stringValue) }
    func decodeNil(forKey key: Key) throws -> Bool { decodeValue(for: key).isOptional }
    func decode(_: Bool.Type, forKey key: Key) throws -> Bool { try decodeValue(for: key).tryTo(\.isBoolean, JSValue.toBool, codingPath + [key]) }
    func decode(_: String.Type, forKey key: Key) throws -> String { try decodeValue(for: key).tryTo(\.isString, JSValue.toString, codingPath + [key]) }
    func decode(_: Int32.Type, forKey key: Key) throws -> Int32 { try decodeValue(for: key).tryTo(\.isNumber, JSValue.toInt32, codingPath + [key]) }
    func decode(_: UInt32.Type, forKey key: Key) throws -> UInt32 { try decodeValue(for: key).tryTo(\.isNumber, JSValue.toUInt32, codingPath + [key]) }
    func decode(_: Double.Type, forKey key: Key) throws -> Double { try decodeValue(for: key).tryTo(\.isNumber, JSValue.toDouble, codingPath + [key]) }
    func decode(_: Float.Type, forKey key: Key) throws -> Float { try .init(decode(Double.self, forKey: key)) }
    func decode(_: Int.Type, forKey key: Key) throws -> Int { try numericCast(decode(Int32.self, forKey: key)) }
    func decode(_: Int8.Type, forKey key: Key) throws -> Int8 { try numericCast(decode(Int32.self, forKey: key)) }
    func decode(_: Int16.Type, forKey key: Key) throws -> Int16 { try numericCast(decode(Int32.self, forKey: key)) }
    func decode(_: Int64.Type, forKey key: Key) throws -> Int64 { try numericCast(decode(Int32.self, forKey: key)) }
    func decode(_: UInt.Type, forKey key: Key) throws -> UInt { try numericCast(decode(UInt32.self, forKey: key)) }
    func decode(_: UInt8.Type, forKey key: Key) throws -> UInt8 { try numericCast(decode(UInt32.self, forKey: key)) }
    func decode(_: UInt16.Type, forKey key: Key) throws -> UInt16 { try numericCast(decode(UInt32.self, forKey: key)) }
    func decode(_: UInt64.Type, forKey key: Key) throws -> UInt64 { try numericCast(decode(UInt32.self, forKey: key)) }
    func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
      if type == Date.self {
        return try decodeValue(for: key).tryTo(\.isDate, JSValue.toDate, codingPath + [key])
      } else if type == URL.self {
        let value: String = try decodeValue(for: key).tryTo(\.isString, JSValue.toString, codingPath + [key])
        guard let url = URL(string: value) else {
          throw DecodingError.dataCorruptedError(
            forKey: key,
            in: self,
            debugDescription: "Invalid URL string."
          )
        }
        return unsafeBitCast(url, to: T.self)
      }

      return try type.init(
        from: JSValueDecoder.Decoder(
          parent: decoder,
          value: decodeValue(for: key),
          key: key
        )
      )
    }

    func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
      try JSValueDecoder.Decoder(
        parent: decoder,
        value: decodeValue(for: key),
        key: key
      )
      .container(keyedBy: type)
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
      try JSValueDecoder.Decoder(
        parent: decoder,
        value: decodeValue(for: key),
        key: key
      )
      .unkeyedContainer()
    }

    func superDecoder() throws -> Decoder { JSValueDecoder.Decoder(parent: decoder, key: JSValueCodingKey.super) }
    func superDecoder(forKey key: Key) throws -> Decoder { JSValueDecoder.Decoder(parent: decoder, key: key) }

    private func decodeValue(for key: Key) -> JSValue { decoder.value.forProperty(decoder.decodeKey(key).stringValue) }
  }
}

// MARK: - JSValueDecoder.Decoder.UnkeyedContainer

extension JSValueDecoder.Decoder {
  struct UnkeyedContainer: UnkeyedDecodingContainer {
    var codingPath: [CodingKey] { decoder.codingPath }
    var isAtEnd: Bool { currentIndex >= (count ?? 0) }
    var currentIndex: Int = 0
    var count: Int? { .init(decoder.value.forProperty("length").toInt32()) }

    private let decoder: JSValueDecoder.Decoder
    private var currentKey: CodingKey { JSValueCodingKey(intValue: currentIndex - 1) }

    init(_ decoder: JSValueDecoder.Decoder) {
      self.decoder = decoder
    }

    mutating func decodeNil() throws -> Bool { nextValue().isOptional }
    mutating func decode(_: Bool.Type) throws -> Bool { try nextValue().tryTo(\.isBoolean, JSValue.toBool, codingPath + [currentKey]) }
    mutating func decode(_: String.Type) throws -> String { try nextValue().tryTo(\.isString, JSValue.toString, codingPath + [currentKey]) }
    mutating func decode(_: Double.Type) throws -> Double { try nextValue().tryTo(\.isNumber, JSValue.toDouble, codingPath + [currentKey]) }
    mutating func decode(_: Int32.Type) throws -> Int32 { try nextValue().tryTo(\.isNumber, JSValue.toInt32, codingPath + [currentKey]) }
    mutating func decode(_: UInt32.Type) throws -> UInt32 { try nextValue().tryTo(\.isNumber, JSValue.toUInt32, codingPath + [currentKey]) }
    mutating func decode(_: Float.Type) throws -> Float { try .init(decode(Double.self)) }
    mutating func decode(_: Int.Type) throws -> Int { try numericCast(decode(Int32.self)) }
    mutating func decode(_: Int8.Type) throws -> Int8 { try numericCast(decode(Int32.self)) }
    mutating func decode(_: Int16.Type) throws -> Int16 { try numericCast(decode(Int32.self)) }
    mutating func decode(_: Int64.Type) throws -> Int64 { try numericCast(decode(Int32.self)) }
    mutating func decode(_: UInt.Type) throws -> UInt { try numericCast(decode(UInt32.self)) }
    mutating func decode(_: UInt8.Type) throws -> UInt8 { try numericCast(decode(UInt32.self)) }
    mutating func decode(_: UInt16.Type) throws -> UInt16 { try numericCast(decode(UInt32.self)) }
    mutating func decode(_: UInt64.Type) throws -> UInt64 { try numericCast(decode(UInt32.self)) }
    mutating func decode<T: Decodable>(_ type: T.Type) throws -> T {
      if type == Date.self {
        return try nextValue().tryTo(\.isDate, JSValue.toDate, codingPath + [currentKey])
      } else if type == URL.self {
        let value: String = try nextValue().tryTo(\.isString, JSValue.toString, codingPath + [currentKey])
        guard let url = URL(string: value) else {
          throw DecodingError.dataCorruptedError(
            in: self,
            debugDescription: "Invalid URL string."
          )
        }
        return unsafeBitCast(url, to: T.self)
      }

      return try type.init(
        from: JSValueDecoder.Decoder(
          parent: decoder,
          value: nextValue(),
          key: currentKey
        )
      )
    }

    mutating func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
      try JSValueDecoder.Decoder(
        parent: decoder,
        value: nextValue(),
        key: currentKey
      )
      .container(keyedBy: type)
    }

    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
      try JSValueDecoder.Decoder(
        parent: decoder,
        value: nextValue(),
        key: currentKey
      )
      .unkeyedContainer()
    }

    mutating func superDecoder() throws -> Decoder {
      JSValueDecoder.Decoder(parent: decoder, key: JSValueCodingKey.super)
    }

    private mutating func nextValue() -> JSValue {
      defer { currentIndex += 1 }
      return decoder.value.atIndex(currentIndex)
    }
  }
}

// MARK: - JSValueDecoder.Decoder + SingleValueDecodingContainer

extension JSValueDecoder.Decoder: SingleValueDecodingContainer {
  func decodeNil() -> Bool { value.isOptional }
  func decode(_: Bool.Type) throws -> Bool { try value.tryTo(\.isBoolean, JSValue.toBool, codingPath) }
  func decode(_: String.Type) throws -> String { try value.tryTo(\.isString, JSValue.toString, codingPath) }
  func decode(_: Double.Type) throws -> Double { try value.tryTo(\.isNumber, JSValue.toDouble, codingPath) }
  func decode(_: Int32.Type) throws -> Int32 { try value.tryTo(\.isNumber, JSValue.toInt32, codingPath) }
  func decode(_: UInt32.Type) throws -> UInt32 { try value.tryTo(\.isNumber, JSValue.toUInt32, codingPath) }
  func decode(_: Float.Type) throws -> Float { try .init(decode(Double.self)) }
  func decode(_: Int.Type) throws -> Int { try numericCast(decode(Int32.self)) }
  func decode(_: Int8.Type) throws -> Int8 { try numericCast(decode(Int32.self)) }
  func decode(_: Int16.Type) throws -> Int16 { try numericCast(decode(Int32.self)) }
  func decode(_: Int64.Type) throws -> Int64 { try numericCast(decode(Int32.self)) }
  func decode(_: UInt.Type) throws -> UInt { try numericCast(decode(UInt32.self)) }
  func decode(_: UInt8.Type) throws -> UInt8 { try numericCast(decode(UInt32.self)) }
  func decode(_: UInt16.Type) throws -> UInt16 { try numericCast(decode(UInt32.self)) }
  func decode(_: UInt64.Type) throws -> UInt64 { try numericCast(decode(UInt32.self)) }
  func decode<T: Decodable>(_ type: T.Type) throws -> T {
    if type == Date.self {
      return try value.tryTo(\.isDate, JSValue.toDate, codingPath)
    } else if type == URL.self {
      let value: String = try value.tryTo(\.isString, JSValue.toString, codingPath)
      guard let url = URL(string: value) else {
        throw DecodingError.dataCorruptedError(
          in: self,
          debugDescription: "Invalid URL string."
        )
      }
      return unsafeBitCast(url, to: T.self)
    }

    return try type.init(from: self)
  }
}

extension JSValue {
  var isOptional: Bool { isNull || isUndefined }
}

extension JSValue {
  fileprivate func tryTo<R>(_ conditional: KeyPath<JSValue, Bool>, _ callback: (JSValue) -> () -> some Any, _ codingKeys: [CodingKey] = []) throws -> R {
    guard self[keyPath: conditional], let result = callback(self)() as? R else {
      throw DecodingError.typeMismatch(
        R.self,
        .init(
          codingPath: codingKeys,
          debugDescription: "Expected to decode \(R.self) but found \(valueType) instead.",
          underlyingError: nil
        )
      )
    }
    return result
  }
}

extension JSValue {
  private var valueType: String {
    if isNull {
      "a nil value"
    } else if isUndefined {
      "an undefined value"
    } else if isObject {
      "an object"
    } else if isDate {
      "a date"
    } else if isArray {
      "an array"
    } else if isBoolean {
      "a boolean"
    } else if isNumber {
      "a number"
    } else if isString {
      "a string"
    } else {
      "unknown/unsupported type"
    }
  }
}
