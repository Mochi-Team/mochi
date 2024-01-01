//
//  AttributeMacro.swift
//
//
//  Created by ErrorErrorError on 12/29/23.
//
//

import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

// MARK: - AttributeMacro

public enum AttributeMacro {
  static let packageName = "CoreDB"
  static let attributeName = "Attribute"
  static let packageWithProtocol = "\(packageName).\(attributeName)"
}

// MARK: PeerMacro

extension AttributeMacro: PeerMacro {
  public static func expansion(
    of _: SwiftSyntax.AttributeSyntax,
    providingPeersOf _: some SwiftSyntax.DeclSyntaxProtocol,
    in _: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.DeclSyntax] {
    []
  }
}
