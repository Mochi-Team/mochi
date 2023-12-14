//
//  Equatable+.swift
//
//
//  Created by ErrorErrorError on 8/14/23.
//
//

import Foundation

extension Equatable {
  public var `self`: Self {
    get { self }
    mutating set { self = newValue }
  }
}
