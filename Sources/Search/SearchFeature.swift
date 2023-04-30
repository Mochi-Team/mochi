//
//  SearchFeature.swift
//  
//
//  Created ErrorErrorError on 4/18/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture

public enum SearchFeature: Feature {
    public struct State: FeatureState {
        @BindingState
        public var query: String

        public init(query: String = "") {
            self.query = query
        }
    }

    public enum Action: FeatureAction {
        public enum ViewAction: SendableAction, BindableAction {
            case didAppear
            case didClearQuery
            case binding(BindingAction<State>)
        }

        public enum DelegateAction: SendableAction {}
        public enum InternalAction: SendableAction {}

        case view(ViewAction)
        case delegate(DelegateAction)
        case `internal`(InternalAction)
    }

    @MainActor
    public struct View: FeatureView {
        public let store: FeatureStoreOf<SearchFeature>

        nonisolated public init(store: FeatureStoreOf<SearchFeature>) {
            self.store = store
        }
    }

    public struct Reducer: FeatureReducer {
        public typealias State = SearchFeature.State
        public typealias Action = SearchFeature.Action

        public init() {}
    }
}
