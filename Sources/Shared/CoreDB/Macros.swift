//
//  Macros.swift
//
//
//  Created by ErrorErrorError on 12/28/23.
//
//

@attached(extension, conformances: Entity)
@attached(member, names: named(_$id), named(properties))
public macro Entity() = #externalMacro(module: "CoreDBMacros", type: "EntityMacro")
