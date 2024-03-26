//
//  VideoPlayerFeature.swift
//
//
//  Created ErrorErrorError on 5/26/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import AVFoundation
import ComposableArchitecture
import ContentCore
import LoggerClient
import ModuleClient
import PlayerClient
import SharedModels
import SwiftUI
import Tagged

// MARK: - VideoPlayerFeature

public struct VideoPlayerFeature: Feature {
  public enum Error: Swift.Error {
    case contentNotFound
  }

  public struct State: FeatureState {
    @CasePathable
    @dynamicMemberLookup
    public enum Overlay: Sendable, Equatable {
      case tools
      case more(MoreTab)

      @CasePathable
      @dynamicMemberLookup
      public enum MoreTab: String, Sendable, Equatable, CaseIterable, Localizable {
        case episodes = "Episodes"
        case sourcesAndServers = "Sources & Servers"
        case qualityAndSubtitles = "Quality & Subtitles"
        case speed = "Playback Speed"

        var image: Image {
          switch self {
          case .episodes:
            Image(systemName: "rectangle.stack.badge.play")
          case .sourcesAndServers:
            Image(systemName: "server.rack")
          case .qualityAndSubtitles:
            Image(systemName: "captions.bubble")
          case .speed:
            Image(systemName: "speedometer")
          }
        }
      }
    }

    public var playlist: Playlist {
      get { content.playlist }
      set { content.playlist = newValue }
    }

    public var playlistHistory: Loadable<PlaylistHistory> { content.playlistHistory }

    public var content: ContentCore.State
    public var loadables: Loadables
    public var selected: SelectedContent
    public var overlay: Overlay?
    public var player: PlayerClient.Status
    public var playerSettings: PlayerSettings

    public init(
      repoModuleId: RepoModuleID,
      playlist: Playlist,
      loadables: Loadables = .init(),
      group: Playlist.Group.ID,
      variant: Playlist.Group.Variant.ID,
      page: PagingID,
      episodeId: Playlist.Item.ID,
      overlay: Overlay? = .tools,
      playerSettings: PlayerSettings = .init()
    ) {
      @Dependency(\.playerClient.get) var status

      self.init(
        repoModuleId: repoModuleId,
        playlist: playlist,
        loadables: loadables,
        group: group,
        variant: variant,
        page: page,
        episodeId: episodeId,
        overlay: overlay,
        player: status(),
        playerSettings: playerSettings
      )
    }

    public init(
      repoModuleId: RepoModuleID,
      playlist: Playlist,
      loadables: Loadables = .init(),
      group: Playlist.Group.ID,
      variant: Playlist.Group.Variant.ID,
      page: PagingID,
      episodeId: Playlist.Item.ID,
      overlay: Overlay? = .tools,
      player: PlayerClient.Status,
      playerSettings: PlayerSettings = .init()
    ) {
      self.content = .init(
        repoModuleId: repoModuleId,
        playlist: playlist
      )
      self.loadables = loadables
      self.selected = .init(
        groupId: group,
        variantId: variant,
        pageId: page,
        itemId: episodeId
      )
      self.overlay = overlay
      self.player = player
      self.playerSettings = playerSettings
    }
  }

  @CasePathable
  public enum Action: FeatureAction {
    @CasePathable
    public enum ViewAction: SendableAction {
      case didAppear
      case didTapBackButton
      case didTapMoreButton
      case didTapPlayer
      case didSelectMoreTab(State.Overlay.MoreTab)
      case didTapCloseMoreOverlay
      case didTogglePlayback
      case didSkipForward
      case didSkipBackwards
      case didChangePlaybackRate(Double)
      case didSkipTo(time: CGFloat)
      case didSeekTo(time: CGFloat)
      case didTapGroupOption(MediaSelectionOption?, for: MediaSelectionGroup)
      case didTapSource(Playlist.EpisodeSource.ID)
      case didTapServer(Playlist.EpisodeServer.ID)
      case didTapLink(Playlist.EpisodeServer.Link.ID)
    }

    @CasePathable
    public enum DelegateAction: SendableAction {}

    @CasePathable
    public enum InternalAction: SendableAction {
      case hideToolsOverlay
      case sourcesResponse(Playlist.Item.ID, Loadable<[Playlist.EpisodeSource]>)
      case serverResponse(Playlist.EpisodeServer.ID, Loadable<Playlist.EpisodeServerResponse>)
      case playerStatusUpdate(PlayerClient.Status)
      case content(ContentCore.Action)
    }

    case view(ViewAction)
    case delegate(DelegateAction)
    case `internal`(InternalAction)
  }

  @MainActor
  public struct View: FeatureView {
    public let store: StoreOf<VideoPlayerFeature>

    @Dependency(\.playerClient.player) var player

    @SwiftUI.State var enablePiP = false
    @SwiftUI.State var gravity = AVLayerVideoGravity.resizeAspect
    @SwiftUI.State var pipSupported = true
    @SwiftUI.State var pipPossible = true
    @SwiftUI.State var pipStatus = PiPStatus.restoreUI

    @MainActor
    public init(store: StoreOf<VideoPlayerFeature>) {
      self.store = store
    }
  }

  @Dependency(\.dismiss) var dismiss
  @Dependency(\.moduleClient) var moduleClient
  @Dependency(\.playerClient) var playerClient

  public init() {}
}

extension VideoPlayerFeature.State {
  public var selectedGroup: Loadable<Playlist.Group> {
    content.group(id: selected.groupId)
  }

  public var selectedVariant: Loadable<Playlist.Group.Variant> {
    content.variant(groupId: selected.groupId, variantId: selected.variantId)
  }

  public var selectedPage: Loadable<LoadablePaging<Playlist.Item>> {
    content.page(
      groupId: selected.groupId,
      variantId: selected.variantId,
      pageId: selected.pageId
    )
  }

  public var selectedItem: Loadable<Playlist.Item> {
    content.item(
      groupId: selected.groupId,
      variantId: selected.variantId,
      pageId: selected.pageId,
      itemId: selected.itemId
    )
  }

  public var selectedSource: Loadable<Playlist.EpisodeSource> {
    selectedItem.flatMap { item in
      loadables[episodeId: item.id].flatMap { sources in
        selected.sourceId.flatMap { sourceId in
          sources[id: sourceId]
        }
        .flatMap { .loaded($0) } ?? .failed(VideoPlayerFeature.Error.contentNotFound)
      }
    }
  }

  public var selectedServer: Loadable<Playlist.EpisodeServer> {
    selectedSource.flatMap { source in
      selected.serverId.flatMap { serverId in
        source.servers[id: serverId]
      }
      .flatMap { .loaded($0) } ?? .failed(VideoPlayerFeature.Error.contentNotFound)
    }
  }

  public var selectedServerResponse: Loadable<Playlist.EpisodeServerResponse> {
    selectedServer.flatMap { server in
      loadables[serverId: server.id].flatMap { .loaded($0) }
    }
  }

  public var selectedLink: Loadable<Playlist.EpisodeServer.Link> {
    selectedServerResponse.flatMap { serverResponse in
      selected.linkId.flatMap { linkId in
        serverResponse.links[id: linkId]
      }
      .flatMap { .loaded($0) } ?? .failed(VideoPlayerFeature.Error.contentNotFound)
    }
  }

  public struct SelectedContent: Equatable, Sendable {
    public var groupId: Playlist.Group.ID
    public var variantId: Playlist.Group.Variant.ID
    public var pageId: PagingID
    public var itemId: Playlist.Item.ID
    public var sourceId: Playlist.EpisodeSource.ID?
    public var serverId: Playlist.EpisodeServer.ID?
    public var linkId: Playlist.EpisodeServer.Link.ID?

    public init(
      groupId: Playlist.Group.ID,
      variantId: Playlist.Group.Variant.ID,
      pageId: PagingID,
      itemId: Playlist.Item.ID,
      sourceId: Playlist.EpisodeSource.ID? = nil,
      serverId: Playlist.EpisodeServer.ID? = nil,
      linkId: Playlist.EpisodeServer.Link.ID? = nil
    ) {
      self.groupId = groupId
      self.variantId = variantId
      self.pageId = pageId
      self.itemId = itemId
      self.sourceId = sourceId
      self.serverId = serverId
      self.linkId = linkId
    }
  }

  public struct Loadables: Equatable, Sendable {
    public var playlistItemSourcesLoadables = [Playlist.Item.ID: Loadable<[Playlist.EpisodeSource]>]()
    public var serverResponseLoadables = [Playlist.EpisodeServer.ID: Loadable<Playlist.EpisodeServerResponse>]()

    subscript(episodeId episodeId: Playlist.Item.ID) -> Loadable<[Playlist.EpisodeSource]> {
      get { playlistItemSourcesLoadables[episodeId] ?? .pending }
      set { playlistItemSourcesLoadables[episodeId] = newValue }
    }

    subscript(serverId serverId: Playlist.EpisodeServer.ID) -> Loadable<Playlist.EpisodeServerResponse> {
      get { serverResponseLoadables[serverId] ?? .pending }
      set { serverResponseLoadables[serverId] = newValue }
    }

    public init(
      playlistItemSourcesLoadables: [Playlist.Item.ID: Loadable<[Playlist.EpisodeSource]>] = [:],
      serverResponseLoadables: [Playlist.EpisodeServer.ID: Loadable<Playlist.EpisodeServerResponse>] = [:]
    ) {
      self.playlistItemSourcesLoadables = playlistItemSourcesLoadables
      self.serverResponseLoadables = serverResponseLoadables
    }

    public mutating func update(
      with episodeId: Playlist.Item.ID,
      response: Loadable<[Playlist.EpisodeSource]>
    ) {
      playlistItemSourcesLoadables[episodeId] = response
    }

    public mutating func update(
      with serverId: Playlist.EpisodeServer.ID,
      response: Loadable<Playlist.EpisodeServerResponse>
    ) {
      serverResponseLoadables[serverId] = response
    }
  }
}

// MARK: - VideoPlayerFeature.View.SkipActionViewState

extension VideoPlayerFeature.View {
  struct SkipActionViewState: Equatable {
    @CasePathable
    @dynamicMemberLookup
    enum Action: Hashable, CustomStringConvertible {
      case times(Playlist.EpisodeServer.SkipTime)
      case next(Double, Playlist.Group.ID, Playlist.Group.Variant.ID, PagingID, Playlist.Item.ID)

      var isEnding: Bool {
        self.times?.type == .ending
      }

      var action: VideoPlayerFeature.Action {
        switch self {
        case let .next(_, group, variant, paging, itemId):
          .internal(.content(.didTapPlaylistItem(group, variant, paging, id: itemId, shouldReset: true)))
        case let .times(time):
          .view(.didSkipTo(time: time.endTime))
        }
      }

      var description: String {
        switch self {
        case let .times(time):
          time.type.description
        case let .next(number, _, _, _, _):
          "Play E\(number.withoutTrailingZeroes)"
        }
      }

      var image: String {
        switch self {
        case .next:
          "play.fill"
        default:
          "forward.fill"
        }
      }

      var textColor: Color {
        if case .next = self {
          return .black
        }
        return .white
      }

      var background: Color {
        if case .next = self {
          return .white
        }
        return .init(white: 0.25)
      }
    }

    var actions: [Action]
    var playbackIsInProgress: Bool

    var visible: Bool {
      playbackIsInProgress && !actions.isEmpty
    }

    init(_ state: VideoPlayerFeature.State) {
      guard let playback = state.player.playback else {
        self.actions = []
        self.playbackIsInProgress = false
        return
      }

      self.playbackIsInProgress = playback.totalDuration != .zero
      self.actions = state.selectedServerResponse.value?.skipTimes
        .filter { $0.startTime <= playback.duration && playback.duration <= $0.endTime }
        .sorted(by: \.startTime)
        .compactMap { .times($0) } ?? []

      if let currentEpisode = state.selectedItem.value,
         let episodes = state.selectedPage.value?.items.value,
         let index = episodes.firstIndex(where: \.id == currentEpisode.id),
         (index + 1) < episodes.endIndex {
        let nextEpisode = episodes[index + 1]

        if let ending = actions.first(where: \.isEnding), case let .times(type) = ending {
          if playback.duration >= type.startTime {
            actions.append(
              .next(
                nextEpisode.number,
                state.selected.groupId,
                state.selected.variantId,
                state.selected.pageId,
                nextEpisode.id
              )
            )
          }
        } else if playback.duration >= (0.92 * playback.totalDuration) {
          actions.append(
            .next(
              nextEpisode.number,
              state.selected.groupId,
              state.selected.variantId,
              state.selected.pageId,
              nextEpisode.id
            )
          )
        }
      }
    }
  }
}
