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
import LoggerClient
import Semaphore
import SharedModels

// MARK: - RepoClient + DependencyKey

extension RepoClient: DependencyKey {
  private static let downloadManager = ModulesDownloadManager()

  @Dependency(\.databaseClient) private static var databaseClient
  @Dependency(\.fileClient) private static var fileClient

  public static let liveValue = Self(
    validate: { url in
      let manifestURL = url.appendingPathComponent("Manifest.json", isDirectory: false)
      let request = URLRequest(url: manifestURL)
      let (data, response) = try await URLSession.ephemeral.data(for: request)
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
    updateRepo: { repo in
      _ = try await databaseClient.update(repo)
    },
    deleteRepo: { repoId in
      if let repo = try? await databaseClient.fetch(.all.where(\Repo.remoteURL == repoId.rawValue)).first {
        try await databaseClient.delete(repo)
      }

      await Self.downloadManager.cancelAllRepoDownloads(repoId)
    },
    installModule: { repoId, manifest in
      Self.downloadManager.addToQueue(manifest.id(repoID: repoId), module: manifest)
    },
    removeModule: { id in
      if let repo = try? await databaseClient.fetch(.all.where(\Repo.remoteURL == id.repoId.rawValue)).first,
         let module = repo.modules.first(where: { $0.id == id.moduleId }) {
        try await databaseClient.delete(module)
        try Self.fileClient.remove(fileClient.retrieveModuleDirectory(module.directory))
      }

      Self.downloadManager.cancelModuleDownload(id)
    },
    repos: { databaseClient.observe($0) },
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
    fetchModulesMetadata: { repoId in
      let url = repoId.rawValue.appendingPathComponent("Manifest.json", isDirectory: false)
      let request = URLRequest(url: url)
      let (data, response) = try await URLSession.ephemeral.data(for: request)
      return try RepoManifest.decode(from: data).modules
    }
  )
}

// MARK: - ModulesDownloadManager

// FIXME: Improve download manager for queue, ect

private class ModulesDownloadManager {
  let states = CurrentValueSubject<[RepoModuleID: RepoClient.RepoModuleDownloadState], Never>([:])

  private var semaphore = AsyncSemaphore(value: 1)
  private var downloadTasks = [RepoModuleID: Task<Module?, Never>]()

  @Dependency(\.fileClient) var fileClient

  @Dependency(\.databaseClient) var databaseClient

  func addToQueue(_ repoModuleId: RepoModuleID, module: Module.Manifest) {
    Task.detached { [weak self] in
      await self?.download(repoModuleId, module: module)
    }
  }

  private func download(_ repoModuleId: RepoModuleID, module: Module.Manifest) async {
    guard states.value[repoModuleId]?.canRestartDownload ?? true else {
      return
    }

    states.value[repoModuleId] = .pending

    await semaphore.wait()
    defer { semaphore.signal() }

    let moduleFileURL = repoModuleId.repoId.rawValue.appendingPathComponent(module.file, isDirectory: false)
    let request = URLRequest(url: moduleFileURL)

    let sequence = URLSession.data(request)
    states.value[repoModuleId] = .downloading(percent: 0)

    let task = Task<Module?, Never> {
      do {
        for try await value in sequence {
          switch value {
          case let .progress(progress):
            states.value[repoModuleId] = .downloading(percent: progress)
          case let .value(data, response):
            guard let response = response as? HTTPURLResponse,
                  response.mimeType == "text/javascript" ||
                  response.mimeType == "application/javascript" ||
                  response.mimeType == "application/zip" ||
                  response.mimeType == "application/x-zip",
                  (200..<300).contains(response.statusCode) else {
              throw RepoClient.Error.failedToDownloadModule
            }

            guard response.mimeType == "text/javascript" || response.mimeType == "application/javascript" else {
              throw RepoClient.Error.invalidMimeTypeForModule(received: response.mimeType ?? "Unknown")
            }

            guard let directory = URL(
              string: "\(repoModuleId.repoId.host ?? "Default")/\(repoModuleId.moduleId.rawValue)",
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
        logger.error("\(error.localizedDescription)")
        states.value[repoModuleId] = .failed((error as? RepoClient.Error) ?? .failedToDownloadModule)
      }
      return nil
    }

    downloadTasks[repoModuleId] = task

    guard let module = await task.value else {
      states.value[repoModuleId] = .failed(.failedToDownloadModule)
      downloadTasks[repoModuleId]?.cancel()
      downloadTasks[repoModuleId] = nil
      return
    }

    states.value[repoModuleId] = .installing

    guard var repo: Repo = try? await databaseClient.fetch(.all.where(\.remoteURL == repoModuleId.repoId.rawValue)).first else {
      states.value[repoModuleId] = .failed(.failedToFindRepo)
      return
    }

    if let index = repo.modules.firstIndex(where: { $0.id == repoModuleId.moduleId }) {
      repo.modules.remove(at: index)
    }

    repo.modules.insert(module)

    do {
      _ = try await databaseClient.update(repo)
    } catch {
      states.value[repoModuleId] = .failed(.failedToInstallModule)
    }

    states.value[repoModuleId] = .installed
  }

  func cancelModuleDownload(_ repoModuleId: RepoModuleID) {
    downloadTasks[repoModuleId]?.cancel()
    downloadTasks[repoModuleId] = nil
    states.value[repoModuleId] = nil
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

  static func data(_ request: URLRequest) -> AsyncThrowingStream<DataProgress, Error> {
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
      let session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: nil)
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

extension URLSession {
  fileprivate static let ephemeral = URLSession(configuration: .ephemeral)
}
