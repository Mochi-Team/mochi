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
import SharedModels
import Styling
import SwiftUI
import UserSettingsClient

public struct SettingsFeature: Feature {
  public enum Section: String, Sendable, Hashable, Localizable, CaseIterable {
    case general = "General"
    case appearance = "Appearance"
    case history = "History"
    case developer = "Developer"

    var systemImage: String {
      switch self {
      case .history:
        "clock.arrow.circlepath"
      case .general:
        "gearshape.fill"
      case .appearance:
        "paintbrush.fill"
      case .developer:
        "wrench.and.screwdriver.fill"
      }
    }
  }

  public struct Path: Reducer {
    @CasePathable
    public enum State: Equatable, Sendable {
      case logs(Logs.State)
    }

    @CasePathable
    public enum Action: Equatable, Sendable {
      case logs(Logs.Action)
    }

    @ReducerBuilder<State, Action> public var body: some ReducerOf<Self> {
      Scope(state: \.logs, action: \.logs) {
        Logs()
      }
    }
  }

  public struct State: FeatureState {
    public var path: StackState<Path.State>

    @BindingState public var userSettings: UserSettings

    public init(path: StackState<Path.State> = .init()) {
      self.path = path
      @Dependency(\.userSettings) var userSettings
      self.userSettings = userSettings.get()
    }
  }

  @CasePathable
  public enum Action: FeatureAction {
    @CasePathable
    public enum ViewAction: SendableAction, BindableAction {
      case onTask
      case didTapViewLogs
      case clearHistory
      case binding(BindingAction<State>)
    }

    @CasePathable
    public enum DelegateAction: SendableAction {}

    @CasePathable
    public enum InternalAction: SendableAction {
      case path(StackAction<Path.State, Path.Action>)
    }

    case view(ViewAction)
    case delegate(DelegateAction)
    case `internal`(InternalAction)
  }

  @MainActor
  public struct View: FeatureView {
    public let store: StoreOf<SettingsFeature>

    @Environment(\.theme) var theme

    @MainActor
    public init(store: StoreOf<SettingsFeature>) {
      self.store = store
    }
  }

  @Dependency(\.mainQueue) var mainQueue

  @Dependency(\.userSettings) var userSettingsClient

  public init() {}
}
