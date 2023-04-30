//
//  Live.swift
//  
//
//  Created ErrorErrorError on 4/8/23.
//  Copyright © 2023. All rights reserved.
//

import Dependencies
import Foundation
import SharedModels
import TOMLDecoder

extension RepoClient: DependencyKey {
    public static let liveValue = Self(
        selectModule: unimplemented(),
        selectedModuleStream: unimplemented(),
        validateRepo: { url in
            let manifestURL = url.appendingPathComponent("Manifest.toml", isDirectory: false)
            let request = URLRequest(url: manifestURL)
            let (data, response) = try await URLSession.shared.data(for: request)
            let manifest = try TOMLDecoder().decode(Repo.Manifest.self, from: data)
            let repo = Repo(
                repoURL: url,
                manifest: manifest
            )
            return repo
        },
        addRepo: unimplemented(),
        removeRepo: unimplemented(),
        installModule: unimplemented(),
        removeModule: unimplemented(),
        repos: unimplemented(),
        modules: unimplemented(),
        repoModules: unimplemented()
    )
}
