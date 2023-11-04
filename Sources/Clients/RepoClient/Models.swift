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

public extension RepoClient {
    enum Error: Swift.Error, Equatable, Sendable {
        case failedToFindRepo
        case failedToDownloadModule
        case failedToDownloadRepo
        case failedToAddRepo
        case failedToInstallModule
        case failedToLoadPackages
    }

    enum RepoModuleDownloadState: Equatable, Sendable {
        case pending
        case downloading(percent: Double)
        case installing
        case installed
        case failed(Error)

        var canRestartDownload: Bool {
            switch self {
            case .failed:
                true
            default:
                false
            }
        }
    }

    struct SelectedModule: Equatable, Sendable {
        public let repoId: Repo.ID
        public let module: Module.Manifest

        public init(
            repoId: Repo.ID,
            module: Module.Manifest
        ) {
            self.repoId = repoId
            self.module = module
        }

        public var id: RepoModuleID { .init(repoId: repoId, moduleId: module.id) }
    }

    @dynamicMemberLookup
    struct RepoPayload: Equatable, Sendable {
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

    struct RepoManifest: Equatable, Codable {
        let repository: Repo.Manifest
        let modules: [Module.Manifest]
    }
}

extension Decodable {
    static func decode(from data: Data) throws -> Self {
        try JSONDecoder().decode(Self.self, from: data)
    }
}
