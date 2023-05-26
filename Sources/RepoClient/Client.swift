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
import Tagged
import XCTestDynamicOverlay

public struct RepoClient: Sendable {

    /// Shared select module
    ///
    /// Module must be installed in order to select it
    public let selectModule: @Sendable (Repo.ID, Module.ID) async -> Void

    /// Selected Module
    ///
    /// Returns the selected module, if any
    public let selectedModule: @Sendable () -> SelectedModule?

    /// Shared selected module
    ///
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
    /// This function adds a repo in the system.
    public let addRepo: @Sendable (RepoPayload) async throws -> Void

    /// Remove Repo
    ///
    /// Removes a repo from he system
    public let removeRepo: @Sendable (Repo.ID) async throws -> Void

    /// Install a Module
    ///
    /// Add a module on the system
    public let addModule: @Sendable (Repo.ID, Module.Manifest) async -> Void

    /// Remove a Module
    ///
    /// This removes a moduled installed on a system
    public let removeModule: @Sendable (Repo.ID, Module.ID) async throws -> Void

    /// Observe Installing and pending modules
    ///
    ///
    public let observeModuleInstalls: @Sendable () -> AsyncStream<[RepoModuleID: RepoModuleDownloadState]>

    /// Installed Repos
    ///
    /// Returns installed repos
    public let repos: @Sendable (Request<Repo>) -> AsyncStream<[Repo]>

    /// Installed Modules
    ///
    /// Returns installed modules
    public let modules: @Sendable (Repo.ID) -> AsyncStream<Set<Module>>
}

extension RepoClient: TestDependencyKey {
    public static let testValue = Self(
        selectModule: unimplemented("\(Self.self).selectModule"),
        selectedModule: unimplemented(),
        selectedModuleStream: unimplemented("\(Self.self).selectedModule", placeholder: .never),
        validateRepo: unimplemented(),
        fetchRepoModules: unimplemented("\(Self.self).repoModules", placeholder: .init()),
        addRepo: unimplemented(),
        removeRepo: unimplemented(),
        addModule: unimplemented(),
        removeModule: unimplemented(),
        observeModuleInstalls: unimplemented(),
        repos: unimplemented(),
        modules: unimplemented()
    )
}

extension DependencyValues {
    public var repoClient: RepoClient {
        get { self[RepoClient.self] }
        set { self[RepoClient.self] = newValue }
    }
}
