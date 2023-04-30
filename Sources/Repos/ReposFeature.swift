//
//  ReposFeature.swift
//  
//
//  Created ErrorErrorError on 4/18/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import Foundation
import RepoClient
import SharedModels
import SwiftUI
import ViewComponents

public enum ReposFeature: Feature {
    public struct RepoURLState: Equatable, Sendable {
        let repo: Repo

        public enum Error: Swift.Error, Equatable, Sendable {
            case notValidRepo
        }
    }

    public struct State: FeatureState {
        public var repos: [Repo]
        @BindingState
        public var urlTextInput: String
        public var urlRepoState: Loadable<RepoURLState, RepoURLState.Error>?

        public init(
            repos: [Repo] = [],
            repoUrlTextInput: String = "",
            repoURLState: Loadable<RepoURLState, RepoURLState.Error>? = nil
        ) {
            self.repos = repos
            self.urlTextInput = repoUrlTextInput
            self.urlRepoState = repoURLState
        }
    }

    public enum Action: FeatureAction {
        public enum ViewAction: SendableAction, BindableAction {
            case didAppear
            case addNewRepo(Repo)
            case binding(BindingAction<State>)
        }

        public enum DelegateAction: SendableAction {}

        public enum InternalAction: SendableAction {
            case validateRepoURL(Loadable<RepoURLState, RepoURLState.Error>)
        }

        case view(ViewAction)
        case delegate(DelegateAction)
        case `internal`(InternalAction)
    }

    @MainActor
    public struct View: FeatureView {
        public let store: FeatureStoreOf<ReposFeature>

        @SwiftUI.State var topBarSize = SizeInset.zero
        @InsetValue(\.tabNavigation) var tabNavigationSize

        nonisolated public init(store: FeatureStoreOf<ReposFeature>) {
            self.store = store
        }
    }

    public struct Reducer: FeatureReducer {
        public typealias State = ReposFeature.State
        public typealias Action = ReposFeature.Action

        @Dependency(\.repo) var repoClient

        public init() {}
    }
}
