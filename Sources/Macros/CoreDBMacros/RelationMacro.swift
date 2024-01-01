//
//  RelationMacro.swift
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

// MARK: - RelationMacro

public enum RelationMacro {
  static let packageName = "CoreDB"
  static let attributeName = "Relation"
  static let packageWithProtocol = "\(packageName).\(attributeName)"
}

// MARK: PeerMacro

extension RelationMacro: PeerMacro {
  public static func expansion(
    of _: SwiftSyntax.AttributeSyntax,
    providingPeersOf _: some SwiftSyntax.DeclSyntaxProtocol,
    in _: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.DeclSyntax] {
    []
  }
}
