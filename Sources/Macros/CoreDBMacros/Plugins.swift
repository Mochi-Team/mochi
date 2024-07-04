//
//  Plugins.swift
//
//
//  Created by MochiTeam on 12/28/23.
//
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MacrosPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    EntityMacro.self,
    AttributeMacro.self,
    RelationMacro.self
  ]
}
