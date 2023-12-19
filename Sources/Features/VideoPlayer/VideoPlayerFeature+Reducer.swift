//
//  VideoPlayerFeature+Reducer.swift
//
//
//  Created ErrorErrorError on 5/26/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import ContentCore
import LoggerClient
import ModuleClient
import PlayerClient
import SharedModels

// MARK: - Cancellables

private enum Cancellables: Hashable, CaseIterable {
  case delayCloseTab
  case fetchingSources
  case fetchingServer
}

// MARK: - VideoPlayerFeature + Reducer

extension VideoPlayerFeature: Reducer {
  public var body: some ReducerOf<Self> {
    Scope(state: \.content, action: \.internal.content) {
      ContentCore()
    }

    Reduce { state, action in
      switch action {
      case .view(.didAppear):
        return .merge(
          state.content.fetchContent(.page(state.selected.groupId, state.selected.variantId, state.selected.pageId))
            .map { .internal(.content($0)) },
          .run { send in
            for await status in playerClient.observe() {
              await send(.internal(.playerStatusUpdate(status)))
            }
          }
        )

      case .view(.didTapBackButton):
        return state.dismiss()

      case .view(.didTapMoreButton):
        state.overlay = .more(.episodes)
        return .cancel(id: Cancellables.delayCloseTab)

      case let .view(.didSelectMoreTab(tab)):
        state.overlay = .more(tab)
        return .cancel(id: Cancellables.delayCloseTab)

      case .view(.didTapPlayer):
        state.overlay = state.overlay == nil ? .tools : nil
        return state.delayDismissOverlayIfNeeded()

      case .view(.didTapCloseMoreOverlay):
        state.overlay = .tools
        return state.delayDismissOverlayIfNeeded()

      case let .view(.didTapSource(sourceId)):
        return state.clearForChangedSourceIfNeeded(sourceId)

      case let .view(.didTapServer(serverId)):
        return state.clearForChangedServerIfNeeded(serverId)

      case let .view(.didTapLink(linkId)):
        return state.clearForChangedLinkIfNeeded(linkId)

      case let .view(.didSeekTo(time)):
        return .merge(
          state.delayDismissOverlayIfNeeded(),
          .run { await playerClient.seek(time) }
        )

      case let .view(.didSkipTo(time)):
        if let totalDuration = state.player.playback?.totalDuration, totalDuration != .zero {
          let progress = time / totalDuration
          return .merge(
            state.delayDismissOverlayIfNeeded(),
            .run {  await playerClient.seek(progress) }
          )
        }

      case .view(.didTogglePlayback):
        let isPlaying = state.player.playback?.state == .playing
        let playRate = state.playerSettings.speed
        return .merge(
          state.delayDismissOverlayIfNeeded(),
          .run { _ in
            if isPlaying {
              await playerClient.pause()
            } else {
              await playerClient.play()
              await playerClient.setRate(.init(playRate))
            }
          }
        )

      case let .view(.didChangePlaybackRate(rate)):
        state.playerSettings.speed = rate
        return .run { _ in
          await playerClient.setRate(.init(rate))
        }

      case .view(.didSkipForward):
        let skipTime = state.playerSettings.skipTime // In seconds
        let currentProgress = state.player.playback?.progress ?? .zero
        let totalDuration = state.player.playback?.totalDuration ?? 1
        let newProgress = min(1.0, max(0, currentProgress + (skipTime / totalDuration)))
        return .merge(
          state.delayDismissOverlayIfNeeded(),
          .run { _ in
            await playerClient.seek(newProgress)
          }
        )

      case .view(.didSkipBackwards):
        let skipTime = state.playerSettings.skipTime // In seconds
        let currentProgress = state.player.playback?.progress ?? .zero
        let totalDuration = state.player.playback?.totalDuration ?? 1
        let newProgress = min(1.0, max(0, currentProgress - (skipTime / totalDuration)))
        return .merge(
          state.delayDismissOverlayIfNeeded(),
          .run { _ in
            await playerClient.seek(newProgress)
          }
        )

      case let .view(.didTapGroupOption(option, group)):
        return .run { _ in
          await playerClient.setOption(option, group)
        }

      case .internal(.hideToolsOverlay):
        state.overlay = state.overlay == .tools ? nil : state.overlay

      case let .internal(.content(.didTapPlaylistItem(group, variant, page, itemId))):
        state.overlay = .tools
        return state.clearForNewEpisodeIfNeeded(group, variant, page, itemId)

      case .internal(.content(.update(_, .loaded))):
        // TODO: Decide if it should fetch sources or not
        return state.fetchSourcesIfNecessary()

      case let .internal(.sourcesResponse(episodeId, .loaded(response))):
        state.loadables.update(with: episodeId, response: .loaded(response))

        // TODO: Select preferred quality or first link if available
        if state.selected.sourceId == nil {
          state.selected.sourceId = response.first?.id
        }

        if state.selected.serverId == nil {
          state.selected.serverId = response.first?.servers.first?.id
        }
        return state.fetchServerIfNecessary()

      case let .internal(.sourcesResponse(episodeId, response)):
        state.loadables.update(with: episodeId, response: response)

      case let .internal(.serverResponse(serverId, response)):
        state.loadables.update(with: serverId, response: response)

        if case let .loaded(response) = response, state.selected.serverId == serverId {
          // TODO: Select preferred quality or first link if available
          if let id = response.links.first?.id {
            return state.clearForChangedLinkIfNeeded(id)
          }
        } else if case let .failed(error) = response {
          logger.warning("There was an error retrieving video server response: \(error.localizedDescription)")
        }

      case let .internal(.playerStatusUpdate(status)):
        state.player = status

      case .internal(.content):
        break

      case .delegate:
        break
      }
      return .none
    }
  }
}

extension VideoPlayerFeature.State {
  func delayDismissOverlayIfNeeded() -> Effect<VideoPlayerFeature.Action> {
    if overlay == .tools {
      .run { send in
        try await withTaskCancellation(id: Cancellables.delayCloseTab, cancelInFlight: true) {
          try await Task.sleep(nanoseconds: 1_000_000_000 * 5)
          await send(.internal(.hideToolsOverlay))
        }
      }
    } else {
      .cancel(id: Cancellables.delayCloseTab)
    }
  }
}

extension VideoPlayerFeature.State {
  public func dismiss() -> Effect<VideoPlayerFeature.Action> {
    @Dependency(\.playerClient) var playerClient
    @Dependency(\.dismiss) var dismiss

    return .merge(
      .merge(Cancellables.allCases.map { .cancel(id: $0) }),
      .run { _ in await dismiss() }
    )
  }

  public mutating func clearForNewPlaylistIfNeeded(
    repoModuleId: RepoModuleID,
    playlist: Playlist,
    groupId: Playlist.Group.ID,
    variantId: Playlist.Group.Variant.ID,
    pageId: PagingID,
    episodeId: Playlist.Item.ID
  ) -> Effect<VideoPlayerFeature.Action> {
    @Dependency(\.playerClient) var playerClient

    var shouldClearContents = false
    var shouldClearSources = false

    if repoModuleId != content.repoModuleId {
      content.repoModuleId = repoModuleId
      shouldClearSources = true
      shouldClearContents = true
    }

    if playlist.id != self.playlist.id {
      self.playlist = playlist
      shouldClearSources = true
      shouldClearContents = true
    }

    if groupId != selected.groupId {
      selected.groupId = groupId
      shouldClearSources = true
    }

    if variantId != selected.variantId {
      selected.variantId = variantId
      shouldClearSources = true
    }

    if pageId != selected.pageId {
      selected.pageId = pageId
      shouldClearSources = true
    }

    if episodeId != selected.itemId {
      selected.itemId = episodeId
      shouldClearSources = true
    }

    if shouldClearSources {
      selected.serverId = nil
      selected.linkId = nil
      selected.sourceId = nil

      loadables.serverResponseLoadables.removeAll()
      loadables.playlistItemSourcesLoadables.removeAll()

      return .merge(
        shouldClearContents ? content.clear() : .none, content.fetchContent(.page(groupId, variantId, pageId)).map { .internal(.content($0)) },
        .run { await playerClient.clear() }
      )
    }

    return .none
  }

  fileprivate mutating func clearForNewEpisodeIfNeeded(
    _ groupId: Playlist.Group.ID,
    _ variantId: Playlist.Group.Variant.ID,
    _ pageId: PagingID,
    _ episodeId: Playlist.Item.ID
  ) -> Effect<VideoPlayerFeature.Action> {
    @Dependency(\.playerClient) var playerClient

    if selected.groupId != groupId ||
      selected.variantId != variantId ||
      selected.pageId != pageId ||
      selected.itemId != episodeId {
      selected.groupId = groupId
      selected.variantId = variantId
      selected.pageId = pageId
      selected.itemId = episodeId
      selected.sourceId = nil
      selected.serverId = nil
      selected.linkId = nil
      loadables.serverResponseLoadables.removeAll()
      loadables.playlistItemSourcesLoadables.removeAll()
      return .merge(
        fetchSourcesIfNecessary(),
        .run { await playerClient.clear() }
      )
    }
    return .none
  }

  public mutating func clearForChangedSourceIfNeeded(_ sourceId: Playlist.EpisodeSource.ID) -> Effect<VideoPlayerFeature.Action> {
    @Dependency(\.playerClient) var playerClient

    if selected.sourceId != sourceId {
      selected.sourceId = sourceId

      if let sources = loadables[episodeId: selected.itemId].value {
        selected.serverId = sources.first { $0.id == sourceId }?.servers.first?.id
      } else {
        selected.serverId = nil
      }
      selected.linkId = nil
      loadables.serverResponseLoadables.removeAll()

      return .merge(
        fetchSourcesIfNecessary(),
        .run {
          await playerClient.clear()
        }
      )
    }
    return .none
  }

  public mutating func clearForChangedServerIfNeeded(_ serverId: Playlist.EpisodeServer.ID) -> Effect<VideoPlayerFeature.Action> {
    @Dependency(\.playerClient) var playerClient

    if serverId != selected.serverId {
      selected.serverId = serverId
      selected.linkId = nil
      selected.serverId.flatMap { loadables.serverResponseLoadables[$0] = nil }

      return .merge(
        fetchServerIfNecessary(),
        .run {
          await playerClient.clear()
        }
      )
    }

    return .none
  }

  public mutating func clearForChangedLinkIfNeeded(_ linkId: Playlist.EpisodeServer.Link.ID) -> Effect<VideoPlayerFeature.Action> {
    @Dependency(\.playerClient) var playerClient

    if selected.linkId != linkId {
      selected.linkId = linkId

      if let server = selected.serverId.flatMap({ loadables[serverId: $0] })?.value,
         let link = server.links[id: linkId] {
        let playlist = playlist
        let episode = selectedItem.value.flatMap { $0 }
        let loadItem = PlayerClient.VideoCompositionItem(
          link: link.url,
          headers: server.headers,
          subtitles: server.subtitles.map { subtitle in
            .init(
              name: subtitle.name,
              default: subtitle.default,
              autoselect: subtitle.autoselect,
              forced: false,
              link: subtitle.url
            )
          },
          metadata: .init(
            title: episode.flatMap { $0.title ?? "Episode \($0.number.withoutTrailingZeroes)" },
            artworkImage: episode?.thumbnail ?? playlist.posterImage,
            author: playlist.title
          )
        )

        return .run { _ in
          await playerClient.clear()
          try await playerClient.load(loadItem)
          await playerClient.play()
        }
      } else {
        return .run {
          await playerClient.clear()
        }
      }
    }
    return .none
  }

  public mutating func fetchSourcesIfNecessary(forced: Bool = false) -> Effect<VideoPlayerFeature.Action> {
    @Dependency(\.moduleClient) var moduleClient

    let repoModuleId = content.repoModuleId
    let playlist = playlist
    let episodeId = selected.itemId

    if forced || !loadables[episodeId: episodeId].hasInitialized {
      loadables.update(with: episodeId, response: .loading)
      return .run { send in
        try await withTaskCancellation(id: Cancellables.fetchingSources, cancelInFlight: true) {
          let value = try await moduleClient.withModule(id: repoModuleId) { module in
            try await module.playlistEpisodeSources(
              .init(
                playlistId: playlist.id,
                episodeId: episodeId
              )
            )
          }

          await send(.internal(.sourcesResponse(episodeId, .loaded(value))))
        }
      } catch: { error, send in
        await send(.internal(.sourcesResponse(episodeId, .failed(error))))
      }
    }

    return fetchServerIfNecessary()
  }

  public mutating func fetchServerIfNecessary(forced: Bool = false) -> Effect<VideoPlayerFeature.Action> {
    @Dependency(\.moduleClient) var moduleClient

    let repoModuleId = content.repoModuleId
    let playlist = playlist
    let episodeId = selected.itemId
    let sourceId = selected.sourceId
    let serverId = selected.serverId

    guard let sourceId else { return .none }
    guard let serverId else { return .none }

    if forced || !loadables[serverId: serverId].hasInitialized {
      loadables.update(with: serverId, response: .loading)
      return .run { send in
        try await withTaskCancellation(id: Cancellables.fetchingServer, cancelInFlight: true) {
          let value = try await moduleClient.withModule(id: repoModuleId) { module in
            try await module.playlistEpisodeServer(
              .init(
                playlistId: playlist.id,
                episodeId: episodeId,
                sourceId: sourceId,
                serverId: serverId
              )
            )
          }

          await send(.internal(.serverResponse(serverId, .loaded(value))))
        }
      } catch: { error, send in
        await send(.internal(.serverResponse(serverId, .failed(error))))
      }
    }

    return .none
  }
}
