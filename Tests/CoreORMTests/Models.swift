//
//  CoreORM.swift
//  
//
//  Created by ErrorErrorError on 5/19/23.
//  
//

import CoreORM
import Foundation

struct TestSchema: Schema {
    @SchemaBuilder
    static var entities: Entities {
        Parent.self
        Child.self
    }
}

struct Parent: Entity {
    @Attribute
    var name = ""

    @Attribute
    var nameOptional: String?

    @Relation
    var child: Child = .init()

    @Relation
    var childOptional: Child?

//        @Relation
//        var children = [Child]()
}

struct Child: Entity {
    @Attribute
    var name = ""

//        @Relation
//        var parent: Parent = .init()
}
