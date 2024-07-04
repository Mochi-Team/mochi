//
//  LibraryFeature.swift
//
//
//  Created by MochiTeam on 09.04.2024.
//

import Architecture
import ComposableArchitecture
import Foundation
import FileClient
import SwiftUI
import ViewComponents
import PlaylistDetails
import SharedModels
import DownloadQueue


// MARK: - LibraryFeature

public struct LibraryFeature: Feature {
  public struct Path: Reducer {
    @CasePathable
    @dynamicMemberLookup
    public enum State: Equatable, Sendable {
      case playlistDetails(PlaylistDetailsFeature.State)
      case downloadQueue(DownloadQueueFeature.State)
    }

    @CasePathable
    @dynamicMemberLookup
    public enum Action: Equatable, Sendable {
      case playlistDetails(PlaylistDetailsFeature.Action)
      case downloadQueue(DownloadQueueFeature.Action)
    }

    @ReducerBuilder<State, Action> public var body: some ReducerOf<Self> {
      Scope(state: \.playlistDetails, action: \.playlistDetails) {
        PlaylistDetailsFeature()
      }
      Scope(state: \.downloadQueue, action: \.downloadQueue) {
        DownloadQueueFeature()
      }
    }
  }

  public struct State: FeatureState {
    public var path: StackState<Path.State>
    public var playlists: Loadable<[PlaylistCache]>

    public var searchedPlaylists: [PlaylistCache] = []
    @BindingState public var searchValue: String = ""
    public var showOfflineOnly: Bool = false

    public init(path: StackState<Path.State> = .init(), playlists: Loadable<[PlaylistCache]> = .pending) {
      self.path = path
      self.playlists = playlists
    }
  }

  @CasePathable
  @dynamicMemberLookup
  public enum Action: FeatureAction {
    @CasePathable
    @dynamicMemberLookup
    public enum ViewAction: SendableAction, BindableAction {
      case didAppear
      case didTapPlaylist(PlaylistCache)
      case didtapOpenLibraryCollectionSheet
      case didTapRemoveBookmark(PlaylistCache)
      case didTapRemovePlaylist(PlaylistCache)
      case didTapShowDownloadedOnly
      case didTapDownloadQueue

      case binding(BindingAction<State>)
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
    }

    @CasePathable
    @dynamicMemberLookup
    public enum InternalAction: SendableAction {
      case path(StackAction<Path.State, Path.Action>)
      case playlistsDidLoad([PlaylistCache])
      case observeDirectory(URL)
    }

    case view(ViewAction)
    case delegate(DelegateAction)
    case `internal`(InternalAction)
  }

  @MainActor
  public struct View: FeatureView {
    public let store: StoreOf<LibraryFeature>
    @Environment(\.colorScheme) var scheme
    var buttonBackgroundColor: Color { scheme == .dark ? .init(white: 0.2) : .init(white: 0.94) }

    @SwiftUI.State public var selectedDirectory: String?

    @MainActor
    public init(store: StoreOf<LibraryFeature>) {
      self.store = store
    }
  }

  @Dependency(\.fileClient) var fileClient
  @Dependency(\.offlineManagerClient) var offlineManagerClient

  public init() {}
}
