//
//  SettingsFeature.swift
//
//
//  Created ErrorErrorError on 4/8/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import SharedModels
import UserSettingsClient

public struct SettingsFeature: Feature {
    public struct State: FeatureState {
        public var userSettings: UserSettings

        public init(
            userSettings: UserSettings = .init()
        ) {
            self.userSettings = userSettings
        }
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
        public let store: StoreOf<SettingsFeature>

        public nonisolated init(store: StoreOf<SettingsFeature>) {
            self.store = store
        }
    }

    public init() {}
}
