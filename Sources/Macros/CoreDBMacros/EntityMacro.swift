//
//  EntityMacro.swift
//
//
//  Created by ErrorErrorError on 12/28/23.
//
//

import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// MARK: - EntityMacro

public enum EntityMacro {
  static let packageName = "CoreDB"
  static let protocolName = "Entity"
  static let packageWithProtocol = "\(packageName).\(protocolName)"
}

// MARK: ExtensionMacro

extension EntityMacro: ExtensionMacro {
  public static func expansion(
    of _: SwiftSyntax.AttributeSyntax,
    attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
    providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
    conformingTo _: [SwiftSyntax.TypeSyntax],
    in _: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
    guard let inherited = declaration.inheritanceClause?.inheritedTypes else { return [] }
    guard !inherited.contains(where: { [protocolName, packageWithProtocol].contains($0.type.trimmedDescription) }) else { return [] }
    let ext: DeclSyntax =
      """
      extension \(type.trimmed): \(raw: packageWithProtocol) {}
      """
    return [ext.cast(ExtensionDeclSyntax.self)]
  }
}

// MARK: MemberMacro

extension EntityMacro: MemberMacro {
  public static func expansion(
    of _: SwiftSyntax.AttributeSyntax,
    providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
    in _: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.DeclSyntax] {
    let members = declaration.memberBlock.members
    var props: [(name: String, type: String)] = []
    for member in members {
      guard let v = member.decl.as(VariableDeclSyntax.self),
            let b = v.bindings.first,
            let i = b.pattern.as(IdentifierPatternSyntax.self),
            let t = b.typeAnnotation?.type else {
        continue
      }

      let n = i.identifier.text
      let tv = t.description
      props.append((name: n, type: tv))
    }

    let entityProperties = props
      .map { prop in
        """
        \(Self.packageName).Property<Self>("\(prop.name)", \\.\(prop.name))
        """
      }

    return [
      """
      public let _$id: \(raw: Self.packageName).EntityID = .init()
      public static let properties: Set<\(raw: Self.packageName).Property<Self>> = [
        // TODO: Add all properties labeled @Attribute and @Relation
        \(raw: entityProperties.joined(separator: ",\n  "))
      ]
      """
    ]
  }
}
