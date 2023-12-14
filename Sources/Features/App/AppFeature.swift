//
//  AppFeature.swift
//
//
//  Created by ErrorErrorError on 4/6/23.
//
//

import Architecture
import DatabaseClient
import Discover
import Foundation
import ModuleLists
import Repos
import Settings
import SharedModels
import Styling
import SwiftUI
import VideoPlayer
import ViewComponents

public struct AppFeature: Feature {
  public struct State: FeatureState {
    public var appDelegate = AppDelegateFeature.State()
    public var discover = DiscoverFeature.State()
    public var repos = ReposFeature.State()
    public var settings = SettingsFeature.State()

    public var selected = Tab.discover

    @PresentationState
    public var videoPlayer: VideoPlayerFeature.State?

    public init(
      discover: DiscoverFeature.State = .init(),
      repos: ReposFeature.State = .init(),
      settings: SettingsFeature.State = .init(),
      selected: AppFeature.State.Tab = Tab.discover
    ) {
      self.discover = discover
      self.repos = repos
      self.settings = settings
      self.selected = selected
    }

    public enum Tab: String, CaseIterable, Sendable, Localizable, Hashable {
      case discover = "Discover"
      case repos = "Repos"
      case settings = "Settings"

      var image: String {
        switch self {
        case .discover:
          "doc.text.image"
        case .repos:
          "globe"
        case .settings:
          "gearshape"
        }
      }

      var selected: String {
        switch self {
        case .discover:
          "doc.text.image.fill"
        case .repos:
          image
        case .settings:
          "gearshape.fill"
        }
      }

      var colorAccent: Color {
        switch self {
        case .discover:
          Theme.pastelGreen
        case .repos:
          Theme.pastelBlue
        case .settings:
          Theme.pastelOrange
        }
      }
    }
  }

  @CasePathable
  public enum Action: FeatureAction {
    @CasePathable
    @dynamicMemberLookup
    public enum ViewAction: SendableAction {
      case didAppear
      case didSelectTab(State.Tab)
    }

    @CasePathable
    public enum DelegateAction: SendableAction {}

    @CasePathable
    public enum InternalAction: SendableAction {
      case appDelegate(AppDelegateFeature.Action)
      case discover(DiscoverFeature.Action)
      case repos(ReposFeature.Action)
      case settings(SettingsFeature.Action)
      case videoPlayer(PresentationAction<VideoPlayerFeature.Action>)
    }

    case view(ViewAction)
    case delegate(DelegateAction)
    case `internal`(InternalAction)
  }

  @MainActor
  public struct View: FeatureView {
    public let store: StoreOf<AppFeature>

    @Environment(\.theme)
    var theme

    @MainActor
    public init(store: StoreOf<AppFeature>) {
      self.store = store
    }
  }

  @Dependency(\.databaseClient)
  var databaseClient

  @Dependency(\.playerClient)
  var playerClient

  public init() {}
}
