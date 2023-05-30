//
//  VideoPlayerFeature.swift
//  
//
//  Created ErrorErrorError on 5/26/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture

public enum VideoPlayerFeature: Feature {
    public struct State: FeatureState {
        // TODO: Set state

        public init() {}
    }

    public enum Action: FeatureAction {
        public enum ViewAction: SendableAction {
            case didAppear
        }

        public enum DelegateAction: SendableAction {}
        public enum InternalAction: SendableAction {}

        case view(ViewAction)
        case delegate(DelegateAction)
        case `internal`(InternalAction)
    }

    @MainActor
    public struct View: FeatureView {
        public let store: FeatureStoreOf<VideoPlayerFeature>

        nonisolated public init(store: FeatureStoreOf<VideoPlayerFeature>) {
            self.store = store
        }
    }

    public struct Reducer: FeatureReducer {
        public typealias State = VideoPlayerFeature.State
        public typealias Action = VideoPlayerFeature.Action

        @Dependency(\.videoPlayerClient)
        var videoPlayerClient

        public init() {}
    }
}
