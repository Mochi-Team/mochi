//
//  DiscoverFeature.swift
//
//
//  Created by MochiTeam on 4/5/23.
//
//

import Architecture
import ComposableArchitecture
import Foundation
import LocalizableClient
import ModuleClient
import ModuleLists
import OrderedCollections
import PlaylistDetails
import RepoClient
import Search
import SharedModels
import Styling
import SwiftUI
import ViewComponents
import Tagged
import OfflineManagerClient
import FileClient

// MARK: - DiscoverFeature

public struct DiscoverFeature: Feature {
  public struct Captcha: ComposableArchitecture.Reducer {
    public enum State: Equatable, Sendable {
      case solveCaptcha(SolveCaptcha.State)
    }

    public enum Action: Equatable, Sendable {
      case solveCaptcha(SolveCaptcha.Action)
    }

    public var body: some ReducerOf<Self> {
      Scope(state: /State.solveCaptcha, action: /Action.solveCaptcha) {
        SolveCaptcha()
      }
    }

    public struct SolveCaptcha: ComposableArchitecture.Reducer {
      public struct State: Equatable, Sendable {
        public let html: String
        public let hostname: String

        public init(
          html: String,
          hostname: String
        ) {
          self.html = html
          self.hostname = hostname
        }
      }

      public enum Action: Equatable, Sendable {}

      public var body: some ReducerOf<Self> { EmptyReducer() }
    }
  }

  public enum Error: Swift.Error, Equatable, Sendable, Localizable {
    case system(System)
    case module(ModuleClient.Error)

    public enum System: Equatable, Sendable {
      case unknown
      case moduleNotSelected
    }

    public var localizable: String {
      switch self {
      case .system(.moduleNotSelected):
        .init(localizable: "There is no module selected")
      case .system(.unknown):
        .init(localizable: "Unknown system error has occurred")
      case .module:
        .init(localizable: "Failed to load module listings")
      }
    }
  }

  public struct Path: Reducer {
    @CasePathable
    @dynamicMemberLookup
    public enum State: Equatable, Sendable {
      case search(SearchFeature.State)
      case playlistDetails(PlaylistDetailsFeature.State)
      case viewMoreListing(ViewMoreListing.State)
    }

    @CasePathable
    @dynamicMemberLookup
    public enum Action: Equatable, Sendable {
      case search(SearchFeature.Action)
      case playlistDetails(PlaylistDetailsFeature.Action)
      case viewMoreListing(ViewMoreListing.Action)
    }

    @ReducerBuilder<State, Action> public var body: some ReducerOf<Self> {
      Scope(state: \.search, action: \.search) {
        SearchFeature()
      }

      Scope(state: \.playlistDetails, action: \.playlistDetails) {
        PlaylistDetailsFeature()
      }

      Scope(state: \.viewMoreListing, action: \.viewMoreListing) {
        ViewMoreListing()
      }
    }
  }

  @CasePathable
  @dynamicMemberLookup
  public enum Section: Equatable, Sendable {
    case home(HomeState)
    case module(ModuleListingState)
    case empty

    var title: String {
      switch self {
      case .empty:
        .init(localizable: "Loading...")
      case .home:
        .init(localizable: "Home")
      case let .module(moduleState):
        moduleState.module.module.name
      }
    }

    var icon: URL? {
      switch self {
      case .empty:
        nil
      case .home:
        nil
      case let .module(moduleState):
        moduleState.module.module.icon.flatMap { URL(string: $0) }
      }
    }
    
    public struct HistoryListings: Equatable, Sendable, Identifiable {
      public let id: Module.ID
      public let history: [PlaylistHistory]
      public let title: String?
      public let icon: String?
    }

    public struct HomeState: Equatable, Sendable {
      public var listings: Loadable<[HistoryListings]>
      
      init(listings: Loadable<[HistoryListings]>) {
        self.listings = listings
      }
    }

    public struct ModuleListingState: Equatable, Sendable {
      public var module: RepoClient.SelectedModule
      public var listings: Loadable<[DiscoverListing]>

      public init(
        module: RepoClient.SelectedModule,
        listings: Loadable<[DiscoverListing]>
      ) {
        self.module = module
        self.listings = listings
      }
    }
  }

  public struct State: FeatureState {
    public var section: Section
    public var path: StackState<Path.State>
    public var playlistLoading = String?.none

    public var lastWatched: [PlaylistHistory]? = []
    @PresentationState public var moduleLists: ModuleListsFeature.State?
    @PresentationState public var solveCaptcha: DiscoverFeature.Captcha.State?

    public init(
      section: DiscoverFeature.Section = .empty,
      path: StackState<Path.State> = .init(),
      moduleLists: ModuleListsFeature.State? = nil,
      solveCaptcha: DiscoverFeature.Captcha.State? = nil
    ) {
      self.section = section
      self.path = path
      self.moduleLists = moduleLists
      self.solveCaptcha = solveCaptcha
    }
  }

  @CasePathable
  @dynamicMemberLookup
  public enum Action: FeatureAction {
    @CasePathable
    @dynamicMemberLookup
    public enum ViewAction: SendableAction {
      case didAppear
      case didHomeAppear
      case didTapOpenModules
      case didTapContinueWatching(PlaylistHistory)
      case didTapRemovePlaylistHistory(String, String, String)
      case didTapPlaylist(Playlist)
      case didTapSearchButton
      case didTapViewMoreListing(DiscoverListing.ID)
      case didTapRetryLoadingModule
      case onLastWatchedAppear
    }

    @CasePathable
    @dynamicMemberLookup
    public enum DelegateAction: SendableAction {
      case playbackVideoItem(
        Playlist.ItemsResponse,
        repoModuleId: RepoModuleID,
        playlist: Playlist,
        group: Playlist.Group.ID,
        variant: Playlist.Group.Variant.ID,
        paging: PagingID,
        itemId: Playlist.Item.ID
      )
      case playbackDismissed
    }

    @CasePathable
    public enum InternalAction: SendableAction {
      case selectedModule(RepoClient.SelectedModule?)
      case loadedListings(RepoModuleID, Loadable<[DiscoverListing]>)
      case moduleLists(PresentationAction<ModuleListsFeature.Action>)
      case solveCaptcha(PresentationAction<Captcha.Action>)
      case showCaptcha(String, String)
      case path(StackAction<Path.State, Path.Action>)
      case updateLastWatched([PlaylistHistory])
      case removeLastWatchedPlaylist(String)
      case setPlaylistLoading(String?)
      case fetchLastWatchedListing
      case setHomeListings(Loadable<[DiscoverFeature.Section.HistoryListings]>)
    }

    case view(ViewAction)
    case delegate(DelegateAction)
    case `internal`(InternalAction)
  }

  @MainActor
  public struct View: FeatureView {
    public let store: StoreOf<DiscoverFeature>
    
    @Dependency(\.fileClient) var fileClient
    @Dependency(\.localizableClient.localize) var localize
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @MainActor
    public init(store: StoreOf<DiscoverFeature>) {
      self.store = store
    }
  }

  @Dependency(\.repoClient) var repoClient
  @Dependency(\.databaseClient) var databaseClient
  @Dependency(\.moduleClient) var moduleClient
  @Dependency(\.fileClient) var fileClient
  @Dependency(\.offlineManagerClient) var offlineManagerClient
  @Dependency(\.playlistHistoryClient) var playlistHistoryClient

  public init() {}
}
