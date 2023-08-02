//
//  CoreORM.swift
//
//
//  Created by ErrorErrorError on 5/19/23.
//
//

import CoreORM
import Foundation

// MARK: - TestSchema

struct TestSchema: Schema {
    @SchemaBuilder
    static var entities: Entities {
        Parent.self
        Child.self
    }
}

// MARK: - Parent

struct Parent: Entity {
    @Attribute
    var name = ""

    @Attribute
    var nameOptional: String? = nil

    @Relation
    var child: Child = .init()

    @Relation
    var childOptional: Child? = nil

//        @Relation
//        var children = [Child]()
}

// MARK: - Child

struct Child: Entity {
    @Attribute
    var name = ""

//        @Relation
//        var parent: Parent = .init()
}
