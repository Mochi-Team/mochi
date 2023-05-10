//
//  Client.swift
//  
//
//  Created ErrorErrorError on 4/8/23.
//  Copyright © 2023. All rights reserved.
//

import DatabaseClient
import Dependencies
import Foundation
import SharedModels
import XCTestDynamicOverlay

public struct RepoClient: Sendable {

    /// Shared select module
    ///
    /// Module must be installed in order to select it
    public let selectModule: @Sendable (Repo.ID, Module.ID) async -> Void

    /// Shared selected module
    ///
    public let selectedModuleStream: @Sendable () -> AsyncStream<SelectedModule?>

    /// Validates a repo url string
    ///
    ///
    public let validateRepo: @Sendable (URL) async throws -> RepoPayload

    /// Modules for repo
    ///
    /// Fetches repo modules
    public let fetchRepoModules: @Sendable (Repo) async throws -> [Module.Manifest]

    /// Install Repo
    ///
    /// This function installs a repo in the system.
    public let installRepo: @Sendable (RepoPayload) async throws -> Void

    /// Remove Repo
    ///
    /// Removes a repo from he system
    public let removeRepo: @Sendable (Repo.ID) async throws -> Void

    /// Install a Module
    ///
    /// Installs a module on the system
    public let installModule: @Sendable (Repo.ID, Module.Manifest) -> AsyncThrowingStream<RepoModuleDownloadState, Swift.Error>

    /// Remove a Module
    ///
    /// This removes a moduled installed on a system
    public let removeModule: @Sendable (Repo.ID, Module.ID) async throws -> Void

    /// Installed Repos
    ///
    /// Returns installed repos
    public let repos: @Sendable (Request<Repo>) -> AsyncStream<[Repo]>

    /// Installed Modules
    ///
    /// Returns installed modules
    public let modules: @Sendable (Repo.ID) -> AsyncStream<Set<Module>>
}

extension RepoClient {
    public struct SelectedModule: Equatable, Sendable {
        public let repoId: Repo.ID
        public let module: Module
    }

    @dynamicMemberLookup
    public struct RepoPayload: Equatable, Sendable {
        public let remoteURL: URL
        public var iconURL: URL? {
            manifest.icon
                .flatMap { URL(string: $0) }
                .flatMap { url in
                    if url.baseURL == nil {
                        return .init(string: url.relativeString, relativeTo: remoteURL)
                    } else {
                        return url
                    }
                }
        }

        public let manifest: Repo.Manifest

        public subscript<Value>(dynamicMember dynamicMember: KeyPath<Repo.Manifest, Value>) -> Value {
            manifest[keyPath: dynamicMember]
        }

        public init(
            remoteURL: URL,
            manifest: Repo.Manifest
        ) {
            self.remoteURL = remoteURL
            self.manifest = manifest
        }
    }
}

extension RepoClient: TestDependencyKey {
    public static let testValue = Self(
        selectModule: unimplemented("\(Self.self).selectModule"),
        selectedModuleStream: unimplemented("\(Self.self).selectedModule", placeholder: .never),
        validateRepo: unimplemented(),
        fetchRepoModules: unimplemented("\(Self.self).repoModules", placeholder: .init()),
        installRepo: unimplemented(),
        removeRepo: unimplemented(),
        installModule: unimplemented(),
        removeModule: unimplemented(),
        repos: unimplemented(),
        modules: unimplemented()
    )
}

extension DependencyValues {
    public var repo: RepoClient {
        get { self[RepoClient.self] }
        set { self[RepoClient.self] = newValue }
    }
}
