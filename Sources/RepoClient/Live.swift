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
        selectModule: { _, moduleId in
            if let module: Module = try? await databaseClient.fetch(.all.where(\.id == moduleId)).first {
//                selectedModule.send(nil)
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
        installModule: { _, _ in
            // / TODO: Download module contents and then add it to coredata
        },
        removeModule: { _, _ in
//            try await databaseClient.delete(module)
        },
        repos: { databaseClient.observe($0) },
        modules: { databaseClient.observe($0) }
    )
}
