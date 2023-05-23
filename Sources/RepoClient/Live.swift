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
    private static let moduleDownloadProgress = CurrentValueSubject<[RepoModuleID: RepoModuleDownloadState], Never>([:])
    private static let modulesDownloadProgressTasks = LockIsolated<[RepoModuleID: Task<Void, RepoClient.Error>]>([:])

    @Dependency(\.databaseClient)
    private static var databaseClient

    public static let liveValue = Self(
        selectModule: { repoId, moduleId in
            guard let repo: Repo = try? await databaseClient.fetch(.all.where(\.$baseURL == repoId.rawValue)).first else {
                selectedModule.send(nil)
                return
            }

            if let module = repo.modules.first(where: { $0.id == moduleId }) {
                selectedModule.send(.init(repoId: repoId, module: module))
            } else {
                selectedModule.send(nil)
            }
        },
        selectedModule: { selectedModule.value },
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
        addRepo: { repoPayload in
            let repo = Repo(
                baseURL: repoPayload.remoteURL,
                dateAdded: .init(),
                lastRefreshed: .init(),
                manifest: repoPayload.manifest
            )

            try await databaseClient.insertOrUpdate(repo)
        },
        removeRepo: { repoId in
            if let repo: Repo = try? await databaseClient.fetch(.all.where(\.$baseURL == repoId.rawValue)).first {
                try await databaseClient.delete(repo)
            }
            if selectedModule.value?.repoId == repoId {
                selectedModule.send(nil)
            }
        },
        addModule: { repoId, moduleManifest in
            let id = RepoModuleID(repoId: repoId, moduleId: moduleManifest.id)

            modulesDownloadProgressTasks[id]?.cancel()
            modulesDownloadProgressTasks.withValue { $0[id] = nil }
            moduleDownloadProgress.value[id] = .pending

            let task = Task.detached {
                do {
                    guard var repo: Repo = try await databaseClient.fetch(.all.where(\.$baseURL == repoId.rawValue)).first else {
                        Self.moduleDownloadProgress.value[id] = .failed(.failedToFindRepo)
                        return
                    }

                    let moduleFileURL = repo.baseURL.appendingPathComponent(moduleManifest.file, isDirectory: false)
                    let request = URLRequest(url: moduleFileURL)

                    class Delegate: NSObject, URLSessionTaskDelegate {
                        let id: RepoModuleID
                        var observation: NSKeyValueObservation?

                        init(id: RepoClient.RepoModuleID) {
                            self.id = id
                        }

                        func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
                            observation = task.observe(\.progress) { [weak self] _, changed in
                                if !Task.isCancelled, let id = self?.id {
                                    moduleDownloadProgress.value[id] = .downloading(percent: changed.newValue?.fractionCompleted ?? 0.0)
                                }
                            }
                        }
                    }

                    var delegate: Delegate? = Delegate(id: id)
                    defer { delegate = nil }

                    let (data, response) = try await URLSession.shared.data(for: request, delegate: delegate)

                    guard let response = response as? HTTPURLResponse else {
                        throw RepoClient.Error.failedToDownloadModule
                    }

                    Self.moduleDownloadProgress.value[id] = .installing

                    if let index = repo.modules.firstIndex(where: { $0.id == moduleManifest.id }) {
                        repo.modules.remove(at: index)
                    }

                    let module = Module(
                        binaryModule: data,
                        installDate: .init(),
                        manifest: moduleManifest
                    )

                    repo.modules.insert(module)

                    try await databaseClient.insertOrUpdate(repo)

                    Self.moduleDownloadProgress.value[id] = .installed
                } catch {
                    Self.moduleDownloadProgress.value[id] = .failed(.failedToInstallModule)
                }
            }
        },
        removeModule: { repoId, moduleId in
            let id = RepoModuleID(repoId: repoId, moduleId: moduleId)
            modulesDownloadProgressTasks[id]?.cancel()
            modulesDownloadProgressTasks.withValue { $0[id] = nil }

            moduleDownloadProgress.value[id] = nil

            guard var repo: Repo = try await databaseClient.fetch(.all.where(\.$baseURL == repoId.rawValue)).first else {
                return
            }

            if let index = repo.modules.firstIndex(where: { $0.id == moduleId }) {
                repo.modules.remove(at: index)
                try await databaseClient.insertOrUpdate(repo)
            }

            if Self.selectedModule.value?.repoId == repoId && Self.selectedModule.value?.module.id == moduleId {
                Self.selectedModule.send(nil)
            }
        },
        observeModuleInstalls: {
            moduleDownloadProgress
                .values
                .eraseToStream()
        },
        repos: { databaseClient.observe($0) },
        modules: { repoId in
            (databaseClient.observe(.all.where(\.$baseURL == repoId.rawValue)) as AsyncStream<[Repo]>)
                .map { $0.first?.modules ?? .init() }
                .eraseToStream()
        }
    )
}

private actor DownloadActor {

}
