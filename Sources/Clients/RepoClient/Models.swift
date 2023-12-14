//
//  Models.swift
//
//
//  Created by ErrorErrorError on 4/8/23.
//
//

import DatabaseClient
import Foundation
import SharedModels
import Tagged

extension RepoClient {
  public enum Error: Swift.Error, Equatable, Sendable {
    case failedToFindRepo
    case failedToDownloadModule
    case invalidMimeTypeForModule(received: String)
    case failedToDownloadRepo
    case failedToAddRepo
    case failedToInstallModule
    case failedToLoadPackages
  }

  public enum RepoModuleDownloadState: Equatable, Sendable {
    case pending
    case downloading(percent: Double)
    case installing
    case installed
    case failed(Error)

    var canRestartDownload: Bool {
      switch self {
      case .failed, .installed:
        true
      default:
        false
      }
    }
  }

  public struct SelectedModule: Equatable, Sendable {
    public let repoId: Repo.ID
    public let module: Module.Manifest

    public init(
      repoId: Repo.ID,
      module: Module.Manifest
    ) {
      self.repoId = repoId
      self.module = module
    }

    public var id: RepoModuleID { module.id(repoID: repoId) }
  }

  @dynamicMemberLookup
  public struct RepoPayload: Equatable, Sendable {
    public let remoteURL: URL
    public var iconURL: URL? {
      manifest.icon
        .flatMap { URL(string: $0) }
        .flatMap { url in
          if url.baseURL == nil {
            .init(string: url.relativeString, relativeTo: remoteURL)
          } else {
            url
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

  public struct RepoManifest: Equatable, Codable {
    let repository: Repo.Manifest
    let modules: [Module.Manifest]
  }
}

extension Decodable {
  static func decode(from data: Data) throws -> Self {
    try JSONDecoder().decode(Self.self, from: data)
  }
}
