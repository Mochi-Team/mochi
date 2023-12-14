//
//  JSValueEncoder.swift
//
//
//  Created by ErrorErrorError on 11/4/23.
//
//  from https://github.com/theolampert/JSValueCoder

import Foundation
import JavaScriptCore

// MARK: - JSValueEncoder

@dynamicMemberLookup
public class JSValueEncoder {
  public typealias DataEncodingStrategy = JSONEncoder.DataEncodingStrategy
  public typealias NonConformingFloatEncodingStrategy = JSONEncoder.NonConformingFloatEncodingStrategy
  public typealias DateEncodingStrategy = JSONEncoder.DateEncodingStrategy
  public typealias KeyEncodingStrategy = JSONEncoder.KeyEncodingStrategy

  private var options: Options = .init()
  private var userInfo: [CodingUserInfoKey: Any] = [:]

  public init() {}

  public struct Options {
    public var dataEncodingStrategy = DataEncodingStrategy.base64
    public var nonConformingFloatEncodingStrategy = NonConformingFloatEncodingStrategy.throw
    public var dateEncodingStrategy = DateEncodingStrategy.deferredToDate
    public var keyEncodingStrategy = KeyEncodingStrategy.useDefaultKeys
  }

  public subscript<V>(dynamicMember keyPath: WritableKeyPath<Options, V>) -> V {
    get { self.options[keyPath: keyPath] }
    set { self.options[keyPath: keyPath] = newValue }
  }

  public func encode(_ value: some Encodable, into context: JSContext) throws -> JSValue {
    let encoder = Encoder(
      context: context,
      userInfo: userInfo,
      options: options
    )
    try value.encode(to: encoder)
    return encoder.result
  }
}

// MARK: JSValueEncoder.Encoder

extension JSValueEncoder {
  fileprivate struct Encoder {
    let context: JSContext
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any]
    let options: Options
    var result: JSValue {
      nonmutating get { storage.value }
      nonmutating set { storage.value = newValue }
    }

    private let storage: Storage

    init(parent: Self, key: CodingKey) {
      self.init(
        context: parent.context,
        codingPath: parent.codingPath + [key],
        userInfo: parent.userInfo,
        options: parent.options
      )
    }

    init(
      context: JSContext,
      codingPath: [CodingKey] = [],
      userInfo: [CodingUserInfoKey: Any],
      options: JSValueEncoder.Options
    ) {
      self.context = context
      self.codingPath = codingPath
      self.userInfo = userInfo
      self.options = options
      self.storage = .init(context)
    }
  }
}

// MARK: - JSValueEncoder.Encoder.Storage

extension JSValueEncoder.Encoder {
  @dynamicMemberLookup
  private class Storage {
    init(_ context: JSContext) { self.value = .init(undefinedIn: context) }

    var value: JSValue

    subscript<T>(dynamicMember member: WritableKeyPath<JSValue, T>) -> T {
      get { value[keyPath: member] }
      set { value[keyPath: member] = newValue }
    }
  }
}

// MARK: - JSValueEncoder.Encoder + Encoder

extension JSValueEncoder.Encoder: Encoder {
  func container<Key: CodingKey>(keyedBy _: Key.Type) -> KeyedEncodingContainer<Key> {
    if result.isUndefined {
      result = .init(newObjectIn: context)
    }
    return KeyedEncodingContainer(KeyedContainer(self))
  }

  func unkeyedContainer() -> UnkeyedEncodingContainer {
    if result.isUndefined {
      result = .init(newArrayIn: context)
    }
    return JSValueEncoder.Encoder.UnkeyedContainer(self)
  }

  func singleValueContainer() -> SingleValueEncodingContainer { self }

  private func encodedKey(_ codingKey: CodingKey) -> CodingKey {
    switch options.keyEncodingStrategy {
    case .useDefaultKeys:
      codingKey
    case .convertToSnakeCase:
      JSValueCodingKey(convertingToSnakeCase: codingKey)
    case let .custom(block):
      block(codingPath + [codingKey])
    @unknown default:
      fatalError("\(options.keyEncodingStrategy) is not supported")
    }
  }
}

// MARK: - JSValueEncoder.Encoder.KeyedContainer

extension JSValueEncoder.Encoder {
  struct KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
    var codingPath: [CodingKey] { encoder.codingPath }

    private let encoder: JSValueEncoder.Encoder

    init(_ encoder: JSValueEncoder.Encoder) {
      self.encoder = encoder
    }

    func encodeNil(forKey key: Key) { encode(JSValue(nullIn: encoder.context), forKey: key) }
    func encode(_ value: Bool, forKey key: Key) { encode(JSValue(bool: value, in: encoder.context), forKey: key) }
    func encode(_ value: String, forKey key: Key) { encode(JSValue(object: value, in: encoder.context), forKey: key) }
    func encode(_ value: Double, forKey key: Key) { encode(JSValue(double: value, in: encoder.context), forKey: key) }
    func encode(_ value: Int32, forKey key: Key) { encode(JSValue(int32: value, in: encoder.context), forKey: key) }
    func encode(_ value: UInt32, forKey key: Key) { encode(JSValue(uInt32: value, in: encoder.context), forKey: key) }
    func encode(_ value: Float, forKey key: Key) { encode(Double(value), forKey: key) }
    func encode(_ value: Int, forKey key: Key) { encode(Int32(value), forKey: key) }
    func encode(_ value: Int8, forKey key: Key) { encode(Int32(value), forKey: key) }
    func encode(_ value: Int16, forKey key: Key) { encode(Int32(value), forKey: key) }
    func encode(_ value: Int64, forKey key: Key) { encode(Int32(value), forKey: key) }
    func encode(_ value: UInt, forKey key: Key) { encode(UInt32(value), forKey: key) }
    func encode(_ value: UInt8, forKey key: Key) { encode(UInt32(value), forKey: key) }
    func encode(_ value: UInt16, forKey key: Key) { encode(UInt32(value), forKey: key) }
    func encode(_ value: UInt64, forKey key: Key) { encode(UInt32(value), forKey: key) }
    func encode(_ value: some Encodable, forKey key: Key) throws {
      switch value {
      case let date as Date:
        encode(JSValue(object: date, in: encoder.context), forKey: key)
      case let value:
        let encoder = JSValueEncoder.Encoder(parent: encoder, key: key)
        try value.encode(to: encoder)
        encode(encoder.result, forKey: key)
      }
    }

    func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> Swift.KeyedEncodingContainer<NestedKey> {
      JSValueEncoder.Encoder(parent: encoder, key: key)
        .container(keyedBy: keyType)
    }

    func nestedUnkeyedContainer(forKey key: Key) -> Swift.UnkeyedEncodingContainer {
      JSValueEncoder.Encoder(parent: encoder, key: key).unkeyedContainer()
    }

    func superEncoder() -> Swift.Encoder {
      JSValueEncoder.Encoder(parent: encoder, key: JSValueCodingKey.super)
    }

    func superEncoder(forKey key: Key) -> Swift.Encoder {
      JSValueEncoder.Encoder(parent: encoder, key: key)
    }

    private func encode(_ jsValue: JSValue, forKey key: Key) {
      encoder.result.setValue(jsValue, forProperty: encoder.encodedKey(key).stringValue)
    }
  }
}

// MARK: - JSValueEncoder.Encoder.UnkeyedContainer

extension JSValueEncoder.Encoder {
  struct UnkeyedContainer: Swift.UnkeyedEncodingContainer {
    var codingPath: [CodingKey] { encoder.codingPath }
    var count: Int { .init(target.forProperty("length").toInt32()) }

    private var currentKey: CodingKey { JSValueCodingKey(intValue: count) }
    private let encoder: JSValueEncoder.Encoder
    private var target: JSValue { encoder.result }
    private var context: JSContext { encoder.context }

    init(_ encoder: JSValueEncoder.Encoder) {
      self.encoder = encoder
    }

    func encodeNil() { encode(JSValue(nullIn: context)) }
    func encode(_ value: Bool) { encode(JSValue(bool: value, in: context)) }
    func encode(_ value: String) { encode(JSValue(object: value, in: context)) }
    func encode(_ value: Double) { encode(JSValue(double: value, in: context)) }
    func encode(_ value: Int32) { encode(JSValue(int32: value, in: context)) }
    func encode(_ value: UInt32) { encode(JSValue(uInt32: value, in: context)) }
    func encode(_ value: Float) { encode(Double(value)) }
    func encode(_ value: Int) { encode(Int32(value)) }
    func encode(_ value: Int8) { encode(Int32(value)) }
    func encode(_ value: Int16) { encode(Int32(value)) }
    func encode(_ value: Int64) { encode(Int32(value)) }
    func encode(_ value: UInt) { encode(UInt32(value)) }
    func encode(_ value: UInt8) { encode(UInt32(value)) }
    func encode(_ value: UInt16) { encode(UInt32(value)) }
    func encode(_ value: UInt64) { encode(UInt32(value)) }
    func encode(_ value: some Encodable) throws {
      switch value {
      case let date as Date:
        encode(JSValue(object: date, in: context))
      case let value:
        let encoder = JSValueEncoder.Encoder(parent: encoder, key: currentKey)
        try value.encode(to: encoder)
        encode(encoder.result)
      }
    }

    func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
      JSValueEncoder.Encoder(parent: encoder, key: currentKey)
        .container(keyedBy: keyType)
    }

    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
      JSValueEncoder.Encoder(parent: encoder, key: currentKey)
        .unkeyedContainer()
    }

    func superEncoder() -> Encoder { JSValueEncoder.Encoder(parent: encoder, key: JSValueCodingKey.super) }

    private func encode(_ jsValue: JSValue) {
      target.setValue(jsValue, at: count)
    }
  }
}

// MARK: - JSValueEncoder.Encoder + Swift.SingleValueEncodingContainer

extension JSValueEncoder.Encoder: Swift.SingleValueEncodingContainer {
  mutating func encodeNil() { encode(JSValue(nullIn: context)) }
  mutating func encode(_ value: Bool) { encode(JSValue(bool: value, in: context)) }
  mutating func encode(_ value: String) { encode(JSValue(object: value, in: context)) }
  mutating func encode(_ value: Double) { encode(JSValue(double: value, in: context)) }
  mutating func encode(_ value: Int32) { encode(JSValue(int32: value, in: context)) }
  mutating func encode(_ value: UInt32) { encode(JSValue(uInt32: value, in: context)) }
  mutating func encode(_ value: Float) { encode(Double(value)) }
  mutating func encode(_ value: Int) { encode(Int32(value)) }
  mutating func encode(_ value: Int8) { encode(Int32(value)) }
  mutating func encode(_ value: Int16) { encode(Int32(value)) }
  mutating func encode(_ value: Int64) { encode(Int32(value)) }
  mutating func encode(_ value: UInt) { encode(UInt32(value)) }
  mutating func encode(_ value: UInt8) { encode(UInt32(value)) }
  mutating func encode(_ value: UInt16) { encode(UInt32(value)) }
  mutating func encode(_ value: UInt64) { encode(UInt32(value)) }
  mutating func encode(_ value: some Encodable) throws {
    switch value {
    case let date as Date:
      encode(JSValue(object: date, in: context))
    case let value:
      try value.encode(to: self)
    }
  }

  private mutating func encode(_ jsValue: JSValue) {
    self.result = jsValue
  }
}
