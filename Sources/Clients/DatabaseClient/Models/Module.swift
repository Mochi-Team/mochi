//
//  Module.swift
//
//
//  Created by ErrorErrorError on 5/17/23.
//
//

import CoreDB
import Foundation

// MARK: - Module

@Entity
@dynamicMemberLookup
public struct Module: Entity, Hashable, Sendable {
  @Attribute public var directory: URL = .init(string: "/").unsafelyUnwrapped
  @Attribute public var installDate: Date = .init()
  @Attribute public var manifest: Manifest = .init()

  public init() {}
}
