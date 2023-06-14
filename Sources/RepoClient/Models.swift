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
    }

    struct SelectedModule: Equatable, Sendable {
        public let repoId: Repo.ID
        public let module: Module.Manifest
    }

    @dynamicMemberLookup
    struct RepoPayload: Equatable, Sendable {
        public let remoteURL: URL
        public var iconURL: URL? {
            manifest.icon
                .flatMap { URL(string: $0) }
                .flatMap { url in
                    if url.baseURL == nil {
                        return .init(string: url.relativeString, relativeTo: remoteURL)
                    } else {
                        return url
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
}
