//
//  RepoPackagesFeature.swift
//  
//
//  Created ErrorErrorError on 5/4/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import RepoClient
import Semver
import SharedModels
import SwiftUI
import Tagged
import ViewComponents

public enum RepoPackagesFeature {
    public typealias Package = [Module.Manifest]

    public struct State: FeatureState, Identifiable {
        public init(
            repo: Repo,
            modules: Loadable<[Module.Manifest], RepoClient.Error> = .pending,
            installingModules: [Module.ID: RepoClient.RepoModuleDownloadState] = [:]
        ) {
            self.repo = repo
            self.modules = modules
            self.installingModules = installingModules
        }

        public var id: Repo.ID { repo.id }

        public var repo: Repo
        public var modules: Loadable<[Module.Manifest], RepoClient.Error>
        public var installingModules: [Module.ID: RepoClient.RepoModuleDownloadState]

        public var packages: Loadable<[Package], RepoClient.Error> {
            modules.mapValue { manifests in
                Dictionary(grouping: manifests, by: \.id)
                    .map(\.value)
                    .filter { !$0.isEmpty }
                    .sorted { $0.latestModule.name < $1.latestModule.name }
            }
        }

        public var installedModules: [Module] {
            repo.modules.sorted(by: \.name)
        }
    }

    public typealias Action = ReposFeature.Action

    @MainActor
    public struct View: FeatureView {
        public let store: Store<RepoPackagesFeature.State, RepoPackagesFeature.Action>

        nonisolated public init(store: Store<RepoPackagesFeature.State, RepoPackagesFeature.Action>) {
            self.store = store
        }
    }

    public typealias Reducer = ReposFeature.Reducer
}

extension RepoPackagesFeature.Package {
    var latestModule: Module.Manifest {
        self.max { $0.version < $1.version }.unsafelyUnwrapped
    }
}
