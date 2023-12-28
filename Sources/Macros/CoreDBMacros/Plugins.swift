//
//  Plugins.swift
//
//
//  Created by ErrorErrorError on 12/28/23.
//
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MacrosPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    EntityMacro.self
  ]
}
