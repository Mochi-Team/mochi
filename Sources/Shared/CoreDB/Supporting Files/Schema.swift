//
//  Schema.swift
//
//
//  Created by ErrorErrorError on 12/28/23.
//
//

import Foundation

// MARK: - Schema

public protocol Schema {
  static var schemaName: String { get }

  typealias Entities = [any Entity.Type]

  @SchemaBuilder static var entities: Entities { get }
}

extension Schema {
  public static var schemaName: String { String(describing: Self.self) }
}

// MARK: - SchemaBuilder

@resultBuilder
public enum SchemaBuilder {
  public typealias Element = any Entity.Type

  public static func buildBlock() -> [Element] {
    []
  }

  public static func buildBlock(_ element: Element) -> [Element] {
    [element]
  }

  public static func buildBlock(_ elements: Element...) -> [Element] {
    elements
  }

  public static func buildBlock(_ elements: [Element]) -> [Element] {
    elements
  }
}
