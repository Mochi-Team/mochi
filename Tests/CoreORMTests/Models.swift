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
    static var entities: Entities {
        Parent.self
        Child.self
    }
}

// MARK: - Parent

// swiftformat:disable:next redundantType
// swiftlint:disable redundant_optional_initialization
struct Parent: Entity {
    @Attribute
    var name = ""

    @Attribute
    var nameOptional: String?

    @Relation
    var child: Child = .init()

    @Relation
    var childOptional: Child? = nil

//    @Relation
//    var children = [Child]()
}

// MARK: - Child

// swiftformat:disable:next redundantType
struct Child: Entity, Equatable {
    @Attribute
    var name = ""

//    @Relation
//    var parent: Parent = .init()
}
