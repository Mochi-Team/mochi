//
//  Live.swift
//  
//
//  Created ErrorErrorError on 4/8/23.
//  Copyright © 2023. All rights reserved.
//

import Combine
import DatabaseClient
import Dependencies
import Foundation
import SharedModels
import TOMLDecoder

extension RepoClient: DependencyKey {
    private static let selectedModule = CurrentValueSubject<SelectedModule?, Never>(nil)

    @Dependency(\.databaseClient)
    private static var databaseClient

    public static let liveValue = Self(
        selectModule: { repoId, moduleId in
            guard let repo: Repo = try? await databaseClient.fetch(.all.where(\.baseURL == repoId.rawValue)).first else {
                selectedModule.send(nil)
                return
            }

            if let module = repo.modules.first(where: { $0.id == moduleId }) {
                selectedModule.send(.init(repoId: repoId, module: module))
            } else {
                selectedModule.send(nil)
            }
        },
        selectedModuleStream: {
            .init { continuation in
                continuation.yield(selectedModule.value)

                let cancellation = selectedModule.sink { selectedModule in
                    continuation.yield(selectedModule)
                }

                continuation.onTermination = { _ in
                    cancellation.cancel()
                }
            }
        },
        validateRepo: { url in
            let manifestURL = url.appendingPathComponent("Manifest.toml", isDirectory: false)
            let request = URLRequest(url: manifestURL)
            let (data, response) = try await URLSession.shared.data(for: request)
            let manifest = try TOMLDecoder().decode(Repo.Manifest.self, from: data)
            let repoPayload = RepoPayload(
                remoteURL: url,
                manifest: manifest
            )
            return repoPayload
        },
        fetchRepoModules: { repo in
            struct ModulesContainer: Decodable {
                let modules: [Module.Manifest]
            }

            let url = repo.baseURL.appendingPathComponent("Releases.toml", isDirectory: false)
            let request = URLRequest(url: url)
            let (data, response) = try await URLSession.shared.data(for: request)
            return try TOMLDecoder().decode(ModulesContainer.self, from: data).modules
        },
        installRepo: { repoPayload in
            let repo = Repo(
                baseURL: repoPayload.remoteURL,
                dateAdded: .init(),
                lastRefreshed: .init(),
                manifest: repoPayload.manifest
            )

            try await databaseClient.insert(repo)
        },
        removeRepo: { repoId in
            if let repo: Repo = try? await databaseClient.fetch(.all.where(\.baseURL == repoId.rawValue)).first {
                try await databaseClient.delete(repo)
            }
        },
        installModule: { repoId, moduleManifest in
            .init { continuation in
                continuation.yield(.pending)
                let task = Task.detached {
                    guard var repo: Repo = try await databaseClient.fetch(.all.where(\.baseURL == repoId.rawValue)).first else {
                        continuation.finish(throwing: RepoClient.Error.failedToFindRepo)
                        return
                    }

                    let moduleFileURL = repo.baseURL.appendingPathComponent(moduleManifest.file, isDirectory: false)
                    let request = URLRequest(url: moduleFileURL)

                    do {
                        let (data, response) = try await URLSession.shared.data(for: request)

                        guard let response = response as? HTTPURLResponse else {
                            throw RepoClient.Error.failedToDownloadModule
                        }

                        continuation.yield(.installing)

                        if let index = repo.modules.firstIndex(where: { $0.id == moduleManifest.id }) {
                            repo.modules.remove(at: index)
                        }

                        let module = Module(
                            binaryModule: data,
                            installDate: .init(),
                            manifest: moduleManifest
                        )

                        repo.modules.insert(module)

                        try await databaseClient.insert(repo)

                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: RepoClient.Error.failedToDownloadModule)
                    }
                }

                continuation.onTermination = { @Sendable _ in
                    task.cancel()
                }
            }
        },
        removeModule: { repoId, moduleId in
            guard var repo: Repo = try await databaseClient.fetch(.all.where(\.baseURL == repoId.rawValue)).first else {
                return
            }

            if let index = repo.modules.firstIndex(where: { $0.id == moduleId }) {
                repo.modules.remove(at: index)
                try await databaseClient.insert(repo)
            }

            if Self.selectedModule.value?.repoId == repoId && Self.selectedModule.value?.module.id == moduleId {
                Self.selectedModule.send(nil)
            }
        },
        repos: { databaseClient.observe($0) },
        modules: { repoId in
            let stream: AsyncStream<[Repo]> = databaseClient.observe(.all.where(\.baseURL == repoId.rawValue))
            return stream.map { repos in
                repos.first?.modules ?? .init()
            }
            .eraseToStream()
        }
    )
}
