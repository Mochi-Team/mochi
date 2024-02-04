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
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

// MARK: - EntityMacro

public enum EntityMacro {
  static let packageName = "CoreDB"
  static let entityType = "Entity"
  static let qualifiedEntityName = "\(packageName).\(entityType)"

  static let entityIdType = "EntityID<Self>"
  static let qualifiedEntityIdName = "\(packageName).\(entityIdType)"

  static let anyPropertyType = "AnyProperty<Self>"
  static let qualifiedAnyPropertyType = "\(packageName).\(anyPropertyType)"
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
    let inherited = declaration.inheritanceClause?.inheritedTypes ?? []
    guard !inherited.contains(where: { [entityType, qualifiedEntityName].contains($0.type.trimmedDescription) }) else {
      return []
    }
    let ext: DeclSyntax =
      """
      extension \(raw: type.trimmed): \(raw: qualifiedEntityName) {}
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
    let accessType = declaration.modifiers.map(\.name).first { name in
      [.keyword(.public), .keyword(.internal), .keyword(.fileprivate), .keyword(.private)]
        .contains(name.tokenKind)
    }

    let access = if let accessType {
      TokenSyntax(accessType.tokenKind, trailingTrivia: [.spaces(1)], presence: .present)
    } else {
      TokenSyntax(.stringSegment(""), presence: .missing)
    }

    let members = declaration.memberBlock.members
    var props: [MetaPropertyMember] = []
    for member in members {
      guard let v = member.decl.as(VariableDeclSyntax.self),
            let b = v.bindings.first,
            let i = b.pattern.as(IdentifierPatternSyntax.self) else {
        continue
      }

      let attributes = v.attributes.compactMap { attr in
        if case let .attribute(type) = attr {
          return type
        }
        return nil
      }

      guard let attached = attributes.first(
        where: { ["Attribute", "Relation"].contains($0.attributeName.trimmedDescription) }
      ) else {
        continue
      }

      let n = i.identifier.text
      let attachedProps = attached.arguments?.children(viewMode: .all).map(\.trimmedDescription) ?? []
      props.append(.init(memberName: n, attrName: attached.attributeName.trimmedDescription, attrArgs: attachedProps))
    }

    let entityProperties = props
      .map { meta in
        """
        \(qualifiedAnyPropertyType)(name: "\(meta.memberName)", \(meta.description))
        """
      }

    return [
      """
      \(raw: access)init() {}
      \(raw: access)var _$id = \(raw: qualifiedEntityIdName)()
      \(raw: access)static let _$properties: Set<\(raw: qualifiedAnyPropertyType)> = [\
      \(raw: entityProperties.joined(separator: ",\n  "))\
      ]
      """
    ]
  }
}

// MARK: EntityMacro.MetaPropertyMember

extension EntityMacro {
  struct MetaPropertyMember: CustomStringConvertible {
    let memberName: String
    let attrName: String
    let attrArgs: [String]

    var propertyArgs: String { attrArgs.isEmpty ? "" : attrArgs.joined(separator: ", ") + ", " }
    var description: String { "\(EntityMacro.packageName).\(attrName)(\(propertyArgs)\\Self.\(memberName))" }
  }
}
