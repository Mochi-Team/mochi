//
//  URL+.swift
//
//
//  Created by MochiTeam on 11/12/23.
//
//

import Foundation

extension URL: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self = URL(string: value).unsafelyUnwrapped
  }
}
