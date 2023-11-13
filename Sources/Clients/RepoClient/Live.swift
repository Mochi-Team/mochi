//
//  Live.swift
//
//
//  Created ErrorErrorError on 4/8/23.
//  Copyright © 2023. All rights reserved.
//

import Combine
import ConcurrencyExtras
import DatabaseClient
import Dependencies
import FileClient
import Foundation
import Semaphore
import SharedModels

// MARK: - RepoClient + DependencyKey

extension RepoClient: DependencyKey {
    private static let downloadManager = ModulesDownloadManager()

    @Dependency(\.databaseClient)
    private static var databaseClient

    @Dependency(\.fileClient)
    private static var fileClient

    public static let liveValue = Self(
        validate: { url in
            let manifestURL = url.appendingPathComponent("Manifest.json", isDirectory: false)
            let request = URLRequest(url: manifestURL)
            let (data, response) = try await URLSession.shared.data(for: request)
            let manifest = try RepoManifest.decode(from: data)
            let repoPayload = RepoPayload(
                remoteURL: url,
                manifest: manifest.repository
            )
            return repoPayload
        },
        addRepo: { repoPayload in
            let repo = Repo(
                remoteURL: repoPayload.remoteURL,
                manifest: repoPayload.manifest
            )

            _ = try await databaseClient.insert(repo)
        },
        removeRepo: { repoId in
            if let repo = try? await databaseClient.fetch(.all.where(\Repo.remoteURL == repoId.rawValue)).first {
                try await databaseClient.delete(repo)
            }

            await Self.downloadManager.cancelAllRepoDownloads(repoId)
        },
        addModule: { repoId, manifest in
            let id = manifest.id(repoID: repoId)
            await Self.downloadManager.download(id, module: manifest)
        },
        removeModule: { repoId, module in
            let id = module.id(repoID: repoId)
            Self.downloadManager.cancelModuleDownload(id)
            try await databaseClient.delete(module)
            try Self.fileClient.remove(fileClient.retrieveModuleDirectory(module.directory))
        },
        downloads: {
            .init { continuation in
                let cancellation = Self.downloadManager.states.sink { _ in
                    continuation.finish()
                } receiveValue: { value in
                    continuation.yield(value)
                }

                continuation.onTermination = { _ in
                    cancellation.cancel()
                }
            }
        },
        repos: { try await databaseClient.fetch($0) },
        fetchRemoteRepoModules: { repoId in
            let url = repoId.rawValue.appendingPathComponent("Manifest.json", isDirectory: false)
            let request = URLRequest(url: url)
            let (data, response) = try await URLSession.shared.data(for: request)
            return try RepoManifest.decode(from: data).modules
        }
    )
}

// MARK: - ModulesDownloadManager

private class ModulesDownloadManager {
    let states = CurrentValueSubject<[RepoModuleID: RepoClient.RepoModuleDownloadState], Never>([:])

    private var semaphore = AsyncSemaphore(value: 1)
    private var downloadTasks = [RepoModuleID: Task<Module?, Never>]()

    @Dependency(\.fileClient)
    var fileClient

    @Dependency(\.databaseClient)
    var databaseClient

    func download(_ repoModuleID: RepoModuleID, module: Module.Manifest) async {
        guard states.value[repoModuleID]?.canRestartDownload ?? true else {
            return
        }

        states.value[repoModuleID] = .pending

        await semaphore.wait()
        defer { semaphore.signal() }

        let moduleFileURL = repoModuleID.repoId.rawValue.appendingPathComponent(module.file, isDirectory: false)
        let request = URLRequest(url: moduleFileURL)

        let sequence = URLSession.shared.data(request)
        states.value[repoModuleID] = .downloading(percent: 0)

        let task = Task<Module?, Never> {
            do {
                for try await value in sequence {
                    switch value {
                    case let .progress(progress):
                        states.value[repoModuleID] = .downloading(percent: progress)
                    case let .value(data, response):
                        guard let response = response as? HTTPURLResponse,
                              response.mimeType == "text/javascript",
                              (200..<300).contains(response.statusCode) else {
                            throw RepoClient.Error.failedToDownloadModule
                        }

                        guard let directory = URL(
                            string: "\(repoModuleID.repoId.host ?? "Default")/\(repoModuleID.moduleId.rawValue)",
                            relativeTo: nil
                        ) else {
                            throw RepoClient.Error.failedToInstallModule
                        }

                        let module = Module(
                            directory: directory,
                            installDate: .init(),
                            manifest: module
                        )

                        try fileClient.createModuleDirectory(directory)
                        try data.write(to: fileClient.retrieveModuleDirectory(module.mainJSFile))

                        return module
                    }
                }
            } catch {
                print(error)
                states.value[repoModuleID] = .failed((error as? RepoClient.Error) ?? .failedToDownloadModule)
            }
            return nil
        }

        downloadTasks[repoModuleID] = task

        guard let module = await task.value else {
            states.value[repoModuleID] = .failed(.failedToDownloadModule)
            downloadTasks[repoModuleID]?.cancel()
            downloadTasks[repoModuleID] = nil
            return
        }

        states.value[repoModuleID] = .installing

        guard var repo: Repo = try? await databaseClient.fetch(.all.where(\.remoteURL == repoModuleID.repoId.rawValue)).first else {
            states.value[repoModuleID] = .failed(.failedToFindRepo)
            return
        }

        if let index = repo.modules.firstIndex(where: { $0.id == repoModuleID.moduleId }) {
            repo.modules.remove(at: index)
        }

        repo.modules.insert(module)

        do {
            _ = try await databaseClient.update(repo)
        } catch {
            states.value[repoModuleID] = .failed(.failedToInstallModule)
        }

        states.value[repoModuleID] = .installed
    }

    func cancelModuleDownload(_ repoModuleID: RepoModuleID) {
        downloadTasks[repoModuleID]?.cancel()
        downloadTasks[repoModuleID] = nil
        states.value[repoModuleID] = nil
    }

    func cancelAllRepoDownloads(_ repoId: Repo.ID) async {
        for key in downloadTasks.keys where key.repoId == repoId {
            cancelModuleDownload(key)
        }
    }
}

extension URLSession {
    enum DataProgress {
        case progress(Double)
        case value(Data, URLResponse)
    }

    func data(_ request: URLRequest) -> AsyncThrowingStream<DataProgress, Error> {
        class Delegate: NSObject, URLSessionTaskDelegate {
            let continuation: AsyncThrowingStream<DataProgress, Error>.Continuation
            var observation: NSKeyValueObservation?

            init(continuation: AsyncThrowingStream<DataProgress, Error>.Continuation) {
                self.continuation = continuation
                super.init()
            }

            func urlSession(_: URLSession, didCreateTask task: URLSessionTask) {
                observation = task.observe(\.progress) { [weak self] _, changed in
                    if !Task.isCancelled {
                        self?.continuation.yield(.progress(changed.newValue?.fractionCompleted ?? 0.0))
                    }
                }
            }
        }

        return .init { continuation in
            let delegate = Delegate(continuation: continuation)

            let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
            session.dataTask(with: request) { data, response, error in
                guard let response, let data else {
                    continuation.finish(throwing: error)
                    return
                }

                continuation.yield(.value(data, response))
                continuation.finish()
            }
            .resume()
        }
    }
}
