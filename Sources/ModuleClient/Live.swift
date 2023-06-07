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

extension ModuleClient: DependencyKey {
    public static let liveValue: Self = {
        let cached = ModulesCache()

        return  Self(
            initialize: cached.initialize,
            getModule: cached.getCached
        )
    }()
}

private actor ModulesCache {
    private var cached: [RepoModuleID: Module] = [:]
    private let semaphore = AsyncSemaphore(value: 1)

    init() {}

    @Sendable
    func initialize() async throws {
        @Dependency(\.databaseClient)
        var databaseClient

        for await elements: [Repo] in databaseClient.observe(.all) {
            validateCachedModules(elements)
        }
    }

    @Sendable
    func getCached(for id: RepoModuleID) async throws -> ModuleHandler {
        if let module = cached[id] {
            return try .init(module: module)
        }

        let module = try await fetchFromDB(for: id)
        return try .init(module: module)
    }

    private func fetchFromDB(for id: RepoModuleID) async throws -> Module {
        @Dependency(\.databaseClient)
        var databaseClient

        try await semaphore.waitUnlessCancelled()
        defer { semaphore.signal() }

        // Check if the module is cached already
        if let module = cached[id] {
            return module
        }

        guard let repo = try await databaseClient.fetch(.all.where(\Repo.$baseURL == id.repoId.rawValue)).first,
              let module: Module = repo.modules.first(where: { $0.id == id.moduleId })
        else {
            throw ModuleClient.Error.moduleNotFound
        }

        cached[id] = module

        return module
    }

    private func validateCachedModules(_ repos: [Repo]) {
        for cachedModule in cached {
            if let repo = repos.first(where: { $0.id == cachedModule.key.repoId }),
               let module = repo.modules.first(where: { $0.id == cachedModule.key.moduleId }) {
                if module.version != cachedModule.value.version || module.binaryModule.hashValue != cachedModule.value.binaryModule.hashValue {
                    cached[cachedModule.key] = nil
                }
            } else {
                cached[cachedModule.key] = nil
            }
        }
    }
}
