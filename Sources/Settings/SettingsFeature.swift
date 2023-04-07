//
//  SettingsFeature.swift
//  
//
//  Created ErrorErrorError on 4/7/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import SharedModels

public enum SettingsFeature: Feature {
    public struct State: FeatureState {
        // TODO: Set state

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
        public let store: FeatureStoreOf<SettingsFeature>

        nonisolated public init(store: FeatureStoreOf<SettingsFeature>) {
            self.store = store
        }
    }

    public struct Reducer: FeatureReducer {
        public init() {}
    }
}
