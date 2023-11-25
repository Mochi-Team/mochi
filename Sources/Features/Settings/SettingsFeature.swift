//
//  SettingsFeature.swift
//
//
//  Created ErrorErrorError on 4/8/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import BuildClient
import ComposableArchitecture
@preconcurrency import Semver
import SharedModels
import Styling
import SwiftUI
import UserSettingsClient

public struct SettingsFeature: Feature {
    public struct State: FeatureState {
        public var buildVersion: Semver
        public var buildNumber: Int

        @BindingState
        public var userSettings: UserSettings

        public init(
            buildVersion: Semver = .init(0, 0, 1),
            buildNumber: Int = 0
        ) {
            self.buildVersion = buildVersion
            self.buildNumber = buildNumber

            @Dependency(\.userSettings)
            var userSettings
            self.userSettings = userSettings.get()
        }
    }

    @CasePathable
    public enum Action: FeatureAction {
        @CasePathable
        public enum ViewAction: SendableAction, BindableAction {
            case didAppear
            case binding(BindingAction<State>)
        }

        @CasePathable
        public enum DelegateAction: SendableAction {}

        @CasePathable
        public enum InternalAction: SendableAction {}

        case view(ViewAction)
        case delegate(DelegateAction)
        case `internal`(InternalAction)
    }

    @MainActor
    public struct View: FeatureView {
        public let store: StoreOf<SettingsFeature>

        @Environment(\.theme)
        var theme

        public nonisolated init(store: StoreOf<SettingsFeature>) {
            self.store = store
        }
    }

    @Dependency(\.mainQueue)
    var mainQueue
    @Dependency(\.userSettings)
    var userSettingsClient

    public init() {}
}
