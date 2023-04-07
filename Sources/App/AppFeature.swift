//
//  AppFeature.swift
//  
//
//  Created by ErrorErrorError on 4/6/23.
//  
//

import Architecture
import Foundation
import Home
import SharedModels

public enum AppFeature: Feature {
    public enum State: FeatureState {
        case home(HomeFeature.State = .init())
    }

    public enum Action: FeatureAction {
        public enum ViewAction: SendableAction {
            case didAppear
        }
        public enum DelegateAction: SendableAction {}
        public enum InternalAction: SendableAction {
            case hahaThisShouldErrorOut
        }

        case view(ViewAction)
        case delegate(DelegateAction)
        case `internal`(InternalAction)
    }

    @MainActor
    public struct View: FeatureView {
        public let store: FeatureStoreOf<AppFeature>

        nonisolated public init(store: FeatureStoreOf<AppFeature>) {
            self.store = store
        }
    }

    public struct Reducer: FeatureReducer {
        public init() { }
    }
}
