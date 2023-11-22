//
//  Live.swift
//
//
//  Created ErrorErrorError on 6/3/23.
//  Copyright © 2023. All rights reserved.
//

import DatabaseClient
import Dependencies
import Foundation
import Semaphore
import SharedModels

// MARK: - ModuleClient + DependencyKey

extension ModuleClient: DependencyKey {
    public static let liveValue: Self = {
        let cached = ModulesCache()

        return Self(
            initialize: cached.initialize,
            getModule: cached.getCached,
            removeCachedModule: cached.removeModule,
            removeCachedModules: cached.removeModules
        )
    }()
}

// MARK: - ModulesCache

private actor ModulesCache {
    private var cached: [RepoModuleID: ModuleClient.Instance] = [:]
    private let semaphore = AsyncSemaphore(value: 1)

    init() {}

    @Sendable
    func initialize() async throws {
        @Dependency(\.databaseClient)
        var databaseClient
    }

    @Sendable
    func getCached(for id: RepoModuleID) async throws -> ModuleClient.Instance {
        try await fetchFromDB(for: id)
    }

    private func fetchFromDB(for id: RepoModuleID) async throws -> ModuleClient.Instance {
        @Dependency(\.databaseClient)
        var databaseClient

        try await semaphore.waitUnlessCancelled()
        defer { semaphore.signal() }

        // TODO: Check if the module is cached already & validate version & file hash or reload

        if let instance = cached[id] {
            return instance
        }

        guard let repo = try await databaseClient.fetch(.all.where(\Repo.remoteURL == id.repoId.rawValue)).first,
              let module: Module = repo.modules.first(where: { $0.id == id.moduleId }) else {
            throw ModuleClient.Error.client(.moduleNotFound)
        }

        let instance = try ModuleClient.Instance(module: module)
        cached[id] = instance

        return instance
    }

    @Sendable
    func removeModule(id: RepoModuleID) async throws {
        try await semaphore.waitUnlessCancelled()
        defer { semaphore.signal() }
        self.cached[id] = nil
    }

    @Sendable
    func removeModules(id: Repo.ID) async throws {
        try await semaphore.waitUnlessCancelled()
        defer { semaphore.signal() }

        for key in cached.keys where key.repoId == id {
            cached[key] = nil
        }
    }
}
