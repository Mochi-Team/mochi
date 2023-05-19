//
//  Schema.swift
//  
//
//  Created by ErrorErrorError on 5/15/23.
//  
//

import Foundation

public protocol Schema {
    static var schemaName: String { get }

    typealias Entities = [any Entity.Type]

    @SchemaBuilder
    static var entities: Entities { get }
}

public extension Schema {
    static var schemaName: String { String(describing: Self.self) }
}

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
