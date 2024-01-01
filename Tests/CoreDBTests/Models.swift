//
//  Models.swift
//
//
//  Created by ErrorErrorError on 5/19/23.
//
//

import CoreDB
import Foundation

// MARK: - TestSchema

struct TestSchema: Schema {
  static var entities: Entities {
    Parent.self
    Child.self
  }
}

// MARK: - Parent

@Entity
struct Parent: Equatable {
  @Attribute(name: "lol") var name = ""
  @Attribute var nameOptional: String?
  @Relation var child = Child()
  @Relation var childOptional: Child?
  @Relation var children = [Child]()
}

// MARK: - Child

@Entity
struct Child: Equatable {
  @Attribute var name = ""
  @Attribute var nameOptional: String?
}
