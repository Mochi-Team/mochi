//
//  Repo.swift
//
//
//  Created by ErrorErrorError on 4/10/23.
//
//

import CoreDB
import Foundation
import SwiftData

// MARK: - Repo

@Entity
@dynamicMemberLookup
public struct Repo: Equatable, Sendable {
  @Attribute public var remoteURL = URL(string: "/").unsafelyUnwrapped
  @Attribute public var manifest = Manifest()
  @Relation public var modules = Set<Module>()

  public init() {}

  public init(
    remoteURL: URL,
    manifest: Self.Manifest,
    modules: Set<Module> = []
  ) {
    self.remoteURL = remoteURL
    self.manifest = manifest
    self.modules = modules
  }
}
