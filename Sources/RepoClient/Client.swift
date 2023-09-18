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
    public let validateRepo: @Sendable (URL) async throws -> RepoPayload
    public let addRepo: @Sendable (RepoPayload) async throws -> Void
    public let removeRepo: @Sendable (Repo.ID) async throws -> Void
    public let addModule: @Sendable (Repo.ID, Module.Manifest) async -> Void
    public let removeModule: @Sendable (Repo.ID, Module.ID) async throws -> Void
    public let moduleDownloads: @Sendable () -> AsyncStream<[RepoModuleID: RepoModuleDownloadState]>
    public let repos: @Sendable (Request<Repo>) async throws -> [Repo]
    public let fetchRemoteRepoModules: @Sendable (Repo.ID) async throws -> [Module.Manifest]
}

// MARK: TestDependencyKey

extension RepoClient: TestDependencyKey {
    public static let testValue = Self(
        validateRepo: unimplemented("\(Self.self).validateRepo"),
        addRepo: unimplemented("\(Self.self).addRepo"),
        removeRepo: unimplemented("\(Self.self).removeRepo"),
        addModule: unimplemented("\(Self.self).addModule"),
        removeModule: unimplemented("\(Self.self).removeModule"),
        moduleDownloads: unimplemented("\(Self.self).observeModuleInstalls"),
        repos: unimplemented("\(Self.self).repos"),
        fetchRemoteRepoModules: unimplemented("\(Self.self).fetchRemoteRepoModules")
    )
}

public extension DependencyValues {
    var repoClient: RepoClient {
        get { self[RepoClient.self] }
        set { self[RepoClient.self] = newValue }
    }
}
