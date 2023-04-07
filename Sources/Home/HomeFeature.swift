//
//  HomeFeature.swift
//  
//
//  Created by ErrorErrorError on 4/5/23.
//  
//

import Architecture
import ComposableArchitecture
import Foundation
import SharedModels

public enum HomeFeature: Feature {
    public struct State: FeatureState {
        // TODO: Add home state

        public init() {}
    }

    public enum Action: FeatureAction {
        public enum ViewAction: SendableAction {}
        public enum DelegateAction: SendableAction {}
        public enum InternalAction: SendableAction {}

        case view(ViewAction)
        case delegate(DelegateAction)
        case `internal`(InternalAction)
    }

    @MainActor
    public struct View: FeatureView {
        public let store: FeatureStoreOf<HomeFeature>

        nonisolated public init(store: FeatureStoreOf<HomeFeature>) {
            self.store = store
        }
    }

    public struct Reducer: FeatureReducer {
        public init() {
            // TODO: Add reducer actions
        }
    }
}
