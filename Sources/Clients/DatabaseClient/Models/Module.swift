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
public struct Module: Hashable, Sendable {
  @Attribute public var directory = URL(string: "/").unsafelyUnwrapped
  @Attribute public var installDate = Date()
  @Attribute public var manifest = Manifest()

  public init(
    directory: URL,
    installDate: Date,
    manifest: Self.Manifest
  ) {
    self.directory = directory
    self.installDate = installDate
    self.manifest = manifest
  }
}
