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
import Styling
import SwiftUI
import UserSettingsClient

public struct SettingsFeature: Feature {
    public struct State: FeatureState {
        @BindingState
        public var userSettings: UserSettings

        public init() {
            @Dependency(\.userSettings) var userSettings
            self.userSettings = userSettings.get()
        }

        init(userSettings: UserSettings) {
            self.userSettings = userSettings
        }
    }

    public enum Action: FeatureAction {
        public enum ViewAction: SendableAction, BindableAction {
            case didAppear
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
        public let store: StoreOf<SettingsFeature>

        @Environment(\.theme) var theme

        public nonisolated init(store: StoreOf<SettingsFeature>) {
            self.store = store
        }
    }

    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.userSettings) var userSettingsClient

    public init() {}
}
