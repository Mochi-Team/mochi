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
import Styling
import SwiftUI
import Tagged
import ViewComponents

// MARK: - RepoPackagesFeature

public struct RepoPackagesFeature: Feature {
    public typealias Package = [Module.Manifest]

    public struct State: FeatureState, Identifiable {
        public var id: Repo.ID { repo.id }
        public let repo: Repo
        public var fetchedModules: Loadable<[Module.Manifest]>
        public var installingModules: [Module.ID: RepoClient.RepoModuleDownloadState]

        // TODO: Make this not computed but instead whenever fetched modules changes
        public var packages: Loadable<[Package]> {
            fetchedModules.map { manifests in
                Dictionary(grouping: manifests, by: \.id)
                    .map(\.value)
                    .filter { !$0.isEmpty }
                    .sorted { $0.latestModule.name < $1.latestModule.name }
            }
        }

        public var installedModules: [Module] {
            repo.modules.sorted(by: \.installDate)
        }

        public init(
            repo: Repo,
            fetchedModules: Loadable<[Module.Manifest]> = .pending,
            installingModules: [Module.ID: RepoClient.RepoModuleDownloadState] = [:]
        ) {
            self.repo = repo
            self.fetchedModules = fetchedModules
            self.installingModules = installingModules
        }
    }

    public enum Action: FeatureAction {
        case view(ViewAction)
        case `internal`(InternalAction)
        case delegate(DelegateAction)

        public enum ViewAction: SendableAction {
            case didAppear
            case didTapClose
            case didTapToRefreshRepo
        }

        public enum InternalAction: SendableAction {}
        public enum DelegateAction: SendableAction {}
    }

    @MainActor
    public struct View: FeatureView {
        public let store: StoreOf<RepoPackagesFeature>

        public nonisolated init(store: StoreOf<RepoPackagesFeature>) {
            self.store = store
        }
    }

    @Dependency(\.dismiss)
    var dismiss

    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .view(.didAppear):
                break
            case .view(.didTapToRefreshRepo):
                break
            case .view(.didTapClose):
                return .run { _ in await dismiss() }
            case .delegate:
                break
            }
            return .none
        }
    }
}

extension RepoPackagesFeature.Package {
    var latestModule: Module.Manifest {
        self.max { $0.version < $1.version }.unsafelyUnwrapped
    }
}
