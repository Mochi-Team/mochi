//
//  Client.swift
//  
//
//  Created ErrorErrorError on 4/8/23.
//  Copyright © 2023. All rights reserved.
//

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
    public let validateRepo: @Sendable (URL) async throws -> Repo

    /// Adding a new repo
    ///
    public let addRepo: @Sendable (URL) async -> Result<Repo, Error>

    /// Remove repo and all installed modules from that repo
    ///
    public let removeRepo: @Sendable (Repo.ID) async -> Result<Void, Error>

    /// Installs module and  stores it
    ///
    public let installModule: @Sendable (Repo, Module) async -> Result<Void, Error>

    /// Remove module
    ///
    public let removeModule: @Sendable (Module.ID) async -> Result<Void, Error>

    /// Repos installed
    ///
    public let repos: @Sendable () async -> [Repo]

    /// Modules installed
    ///
    public let modules: @Sendable () async -> [Module]

    /// Modules for repo
    /// includes local and network modules
    ///
    public let repoModules: @Sendable (Repo) async throws -> RepoModulesResult
}

extension RepoClient {
    public struct SelectedModule: Equatable, Sendable {
        public let repoId: Repo.ID
        public let module: Module
    }
}

extension RepoClient: TestDependencyKey {
    public static let testValue = Self(
        selectModule: unimplemented("\(Self.self).selectModule"),
        selectedModuleStream: unimplemented("\(Self.self).selectedModule", placeholder: .never),
        validateRepo: unimplemented(),
        addRepo: unimplemented("\(Self.self).addRepo", placeholder: .failure(Error.failedToAddRepo)),
        removeRepo: unimplemented("\(Self.self).removeRepo", placeholder: .success(())),
        installModule: unimplemented("\(Self.self).installModule", placeholder: .failure(.failedToInstallModule)),
        removeModule: unimplemented("\(Self.self).removeModule", placeholder: .success(())),
        repos: unimplemented("\(Self.self).repos", placeholder: []),
        modules: unimplemented("\(Self.self).modules", placeholder: []),
        repoModules: unimplemented("\(Self.self).repoModules", placeholder: .init())
    )
}

extension DependencyValues {
    public var repo: RepoClient {
        get { self[RepoClient.self] }
        set { self[RepoClient.self] = newValue }
    }
}
