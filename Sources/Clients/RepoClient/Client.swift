//
//  Client.swift
//
//
//  Created ErrorErrorError on 4/8/23.
//  Copyright © 2023. All rights reserved.
//

@_exported
import DatabaseClient
import Dependencies
import Foundation
import SharedModels
import Tagged
import XCTestDynamicOverlay

// MARK: - RepoClient

public struct RepoClient: Sendable {
  public var validate: @Sendable (URL) async throws -> RepoPayload

  public var addRepo: @Sendable (RepoPayload) async throws -> Void
  public var updateRepo: @Sendable (Repo) async throws -> Void
  public var deleteRepo: @Sendable (Repo.ID) async throws -> Void

  public var installModule: @Sendable (Repo.ID, Module.Manifest) -> Void
  public var removeModule: @Sendable (RepoModuleID) async throws -> Void

  public var repos: @Sendable (Request<Repo>) -> AsyncStream<[Repo]>

  public var downloads: @Sendable () -> AsyncStream<[RepoModuleID: RepoModuleDownloadState]>
  public var fetchModulesMetadata: @Sendable (Repo.ID) async throws -> [Module.Manifest]
}

// MARK: TestDependencyKey

extension RepoClient: TestDependencyKey {
  public static let testValue = Self(
    validate: unimplemented("\(Self.self).validateRepo"),
    addRepo: unimplemented("\(Self.self).addRepo"),
    updateRepo: unimplemented("\(Self.self).updateRepo"),
    deleteRepo: unimplemented("\(Self.self).deleteRepo"),
    installModule: unimplemented("\(Self.self).addModule"),
    removeModule: unimplemented("\(Self.self).removeModule"),
    repos: unimplemented("\(Self.self).repos"),
    downloads: unimplemented("\(Self.self).downloads"),
    fetchModulesMetadata: unimplemented("\(Self.self).fetchRemoteRepoModules")
  )
}

extension DependencyValues {
  public var repoClient: RepoClient {
    get { self[RepoClient.self] }
    set { self[RepoClient.self] = newValue }
  }
}
