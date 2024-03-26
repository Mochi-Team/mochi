//
//  RepoModuleID.swift
//
//
//  Created by ErrorErrorError on 6/2/23.
//
//

@_exported
import DatabaseClient
import Foundation
import Tagged

// MARK: - RepoModuleID

public struct RepoModuleID: Hashable, Sendable {
  public let repoId: Repo.ID
  public let moduleId: Module.ID

  public init(repoId: Repo.ID, moduleId: Module.ID) {
    self.repoId = repoId
    self.moduleId = moduleId
  }
}

extension Repo.ID {
  // Follow reverse domain name notation
  public var displayIdentifier: String {
    // "dev.errorerrorerror.mochi.repo.local" for local storage
    rawValue.host?.split(separator: ".").reversed().joined(separator: ".").lowercased() ?? rawValue.absoluteString
  }
}

// MARK: - RepoModuleID + CustomStringConvertible

extension RepoModuleID: CustomStringConvertible {
  public var description: String {
    "\(repoId.displayIdentifier).\(moduleId)"
  }
}

extension RepoModuleID {
  public static func create(_ repo: Repo, _ module: Module) -> RepoModuleID {
    .init(repoId: repo.id, moduleId: module.id)
  }
}

extension Repo {
  public func id(_ moduleID: Module.ID) -> RepoModuleID {
    .init(repoId: id, moduleId: moduleID)
  }

  public func id(_ module: Module.Manifest) -> RepoModuleID {
    id(module.id)
  }
}

extension Module {
  public func id(repoID: Repo.ID) -> RepoModuleID {
    .init(repoId: repoID, moduleId: id)
  }
}

extension Module.Manifest {
  public func id(repoID: Repo.ID) -> RepoModuleID {
    .init(repoId: repoID, moduleId: id)
  }
}
