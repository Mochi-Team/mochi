//
//  Macros.swift
//
//
//  Created by ErrorErrorError on 12/28/23.
//
//

import CoreData
import Foundation

@attached(extension, conformances: Entity)
@attached(member, names: named(init), named(_$id), named(_$properties))
public macro Entity() = #externalMacro(module: "CoreDBMacros", type: "EntityMacro")

@attached(peer, names: overloaded)
public macro Attribute(
  name: String? = nil,
  traits: Set<PropertyTrait> = []
) = #externalMacro(module: "CoreDBMacros", type: "AttributeMacro")

@attached(peer, names: overloaded)
public macro Relation(
  name: String? = nil,
  isTransient: Bool = false,
  deleteRule: NSDeleteRule = .cascadeDeleteRule
) = #externalMacro(module: "CoreDBMacros", type: "RelationMacro")
