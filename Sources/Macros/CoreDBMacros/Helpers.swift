//
//  Helpers.swift
//
//
//  Created by ErrorErrorError on 12/29/23.
//
//

import Foundation

import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension TokenSyntax {
  var identifier: String? {
    for token in tokens(viewMode: .all) {
      switch token.tokenKind {
      case let .identifier(name):
        return name
      default:
        continue
      }
    }
    return nil
  }
}
