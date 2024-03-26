//
//  ContentCore.swift
//
//
//  Created by ErrorErrorError on 7/2/23.
//
//

import Architecture
import ComposableArchitecture
import Foundation
import FoundationHelpers
import LoggerClient
import ModuleClient
import OrderedCollections
import PlaylistHistoryClient
import SharedModels
import Tagged

// MARK: - Cancellable

private enum Cancellable: Hashable, CaseIterable {
  case fetchContent
}

// MARK: - ContentCore

public struct ContentCore: Reducer {
  public struct State: FeatureState {
    public var repoModuleId: RepoModuleID
    public var playlist: Playlist
    public var groups: Loadable<[Playlist.Group]>
    public var playlistHistory: Loadable<PlaylistHistory>

    public init(
      repoModuleId: RepoModuleID,
      playlist: Playlist,
      groups: Loadable<[Playlist.Group]> = .pending,
      playlistHistory: Loadable<PlaylistHistory> = .pending
    ) {
      self.repoModuleId = repoModuleId
      self.playlist = playlist
      self.groups = groups
      self.playlistHistory = playlistHistory
    }
  }

  @CasePathable
  @dynamicMemberLookup
  public enum Action: SendableAction {
    case update(option: Playlist.ItemsRequestOptions?, Loadable<Playlist.ItemsResponse>)
    case didRequestLoadingPendingContent(Playlist.ItemsRequestOptions?)
    case didTapContent(Playlist.ItemsRequestOptions)
    case playlistHistoryResponse(Loadable<PlaylistHistory>)
    case didTapPlaylistItem(
      Playlist.Group.ID,
      Playlist.Group.Variant.ID,
      PagingID,
      id: Playlist.Item.ID,
      shouldReset: Bool = false
    )
  }

  public enum Error: Swift.Error, Equatable, Sendable {
    case contentNotFound
  }

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .didTapContent(option):
        return state.fetchContent(option)

      case let .didTapPlaylistItem(groupId, variantId, pageId, itemId, shouldReset):
        @Dependency(\.playlistHistoryClient) var playlistHistoryClient
        let playlist = state.playlist
        let repoModuleId = state.repoModuleId
        let item = state.item(groupId: groupId, variantId: variantId, pageId: pageId, itemId: itemId).value
        return .run { _ in
          if let item {
            try? await playlistHistoryClient.updateEpId(.init(
              rmp: .init(repoId: repoModuleId.repoId.absoluteString, moduleId: repoModuleId.moduleId.rawValue, playlistId: playlist.id.rawValue),
              episode: item,
              playlistName: playlist.title,
              pageId: pageId.rawValue,
              groupId: groupId.rawValue,
              variantId: variantId.rawValue
            ))
            if shouldReset {
              try? await playlistHistoryClient.updateTimestamp(.init(repoId: repoModuleId.repoId.absoluteString, moduleId: repoModuleId.moduleId.rawValue, playlistId: playlist.id.rawValue), 0)
            }
          }
        }

      case let .playlistHistoryResponse(response):
        state.playlistHistory = response

      case let .didRequestLoadingPendingContent(options):
        return state.fetchContent(options)

      case let .update(option, response):
        state.update(option, response)
      }
      return .none
    }
  }
}

extension ContentCore.State {
  public mutating func clear<Action: FeatureAction>() -> Effect<Action> {
    groups = .pending
    return .merge(.cancel(id: Cancellable.fetchContent))
  }

  public mutating func fetchContent(
    _ option: Playlist.ItemsRequestOptions? = nil,
    forced: Bool = false
  ) -> Effect<ContentCore.Action> {
    @Dependency(\.moduleClient) var moduleClient
    @Dependency(\.playlistHistoryClient) var playlistHistoryClient

    let playlistId = playlist.id
    let repoModuleId = repoModuleId

    if !forced {
      // Do not submit request if loadable is not pending
      if let groupId = option?.groupId {
        if let variantId = option?.variantId {
          if let pagingId = option?.pagingId {
            if let loadable = groups.value?[id: groupId]?.variants.value?[id: variantId]?.pagings.value?[id: pagingId]?.items, loadable != .pending {
              return .none
            }
          } else if let loadable = groups.value?[id: groupId]?.variants.value?[id: variantId]?.pagings, loadable != .pending {
            return .none
          }
        } else if let loadable = groups.value?[id: groupId]?.variants, loadable != .pending {
          return .none
        }
      } else {
        if groups != .pending {
          return .none
        }
      }
    }

    update(option, .loading)

    return .run { send in
      try await withTaskCancellation(id: Cancellable.fetchContent, cancelInFlight: true) {
        let value = try await moduleClient.withModule(id: repoModuleId) { module in
          try await module.playlistEpisodes(playlistId, option)
        }

        await send(.update(option: option, .loaded(value)))
        for await playlistHistoryItems in playlistHistoryClient.observe(.init(repoId: repoModuleId.repoId.absoluteString, moduleId: repoModuleId.moduleId.rawValue, playlistId: playlistId.rawValue)) {
          if let playlistHistory = playlistHistoryItems.first {
            await send(.playlistHistoryResponse(.loaded(playlistHistory)))
          }
        }
      }
    } catch: { error, send in
      logger.error("\(#function) - \(error)")
      await send(.update(option: option, .failed(error)))
    }
  }
}

// MARK: Public methods for variants

extension ContentCore.State {
  public func group(id: Playlist.Group.ID) -> Loadable<Playlist.Group> {
    groups.flatMap { .init(expected: $0[id: id]) }
  }

  public func variant(
    groupId: Playlist.Group.ID,
    variantId: Playlist.Group.Variant.ID
  ) -> Loadable<Playlist.Group.Variant> {
    group(id: groupId)
      .flatMap(\.variants)
      .flatMap { .init(expected: $0[id: variantId]) }
  }

  public func page(
    groupId: Playlist.Group.ID,
    variantId: Playlist.Group.Variant.ID,
    pageId: PagingID
  ) -> Loadable<Playlist.Group.Variant.Pagings.Element> {
    variant(groupId: groupId, variantId: variantId)
      .flatMap(\.pagings)
      .flatMap { .init(expected: $0[id: pageId]) }
  }

  public func item(
    groupId: Playlist.Group.ID,
    variantId: Playlist.Group.Variant.ID,
    pageId: PagingID,
    itemId: Playlist.Item.ID
  ) -> Loadable<Playlist.Item> {
    page(groupId: groupId, variantId: variantId, pageId: pageId)
      .flatMap(\.items)
      .flatMap { .init(expected: $0[id: itemId]) }
  }

  mutating func update(_ option: Playlist.ItemsRequestOptions?, _ response: Loadable<Playlist.ItemsResponse>) {
    guard case var .loaded(value) = groups, let option, var group = value[id: option.groupId] else {
      groups = response.flatMap { .loaded($0) }
      return
    }

    let variantsResponse = response
      .flatMap { .init(expected: $0[id: group.id]) }
      .flatMap { .init(expected: $0.variants.value) }

    if case .group = option {
      group = .init(
        id: group.id,
        number: group.number,
        altTitle: group.altTitle,
        variants: variantsResponse,
        default: group.default ?? false
      )
    } else if let variantId = option.variantId {
      let pagingsResponse = variantsResponse
        .flatMap { .init(expected: $0[id: variantId]) }
        .flatMap { .init(expected: $0.pagings.value) }

      if let pageId = option.pagingId {
        // Update page's items
        group = .init(
          id: group.id,
          number: group.number,
          altTitle: group.altTitle,
          variants: group.variants.map { variants in
            var variants = variants

            variants[id: variantId] = variants[id: variantId].flatMap { variant in
              .init(
                id: variant.id,
                title: variant.title,
                pagings: variant.pagings.map { pagings in
                  var pagings = pagings

                  pagings[id: pageId] = pagings[id: pageId].flatMap { page in
                    .init(
                      id: page.id,
                      previousPage: page.previousPage,
                      nextPage: page.nextPage,
                      title: page.title,
                      items: pagingsResponse
                        .flatMap { .init(expected: $0[id: page.id]) }
                        .flatMap { .init(expected: $0.items.value) }
                    )
                  }

                  return pagings
                }
              )
            }
            return variants
          },
          default: group.default ?? false
        )
      } else {
        group = .init(
          id: group.id,
          number: group.number,
          altTitle: group.altTitle,
          variants: group.variants.map { variants in
            var variants = variants

            variants[id: variantId] = variants[id: variantId]
              .flatMap { .init(id: $0.id, title: $0.title, pagings: pagingsResponse) }

            return variants
          },
          default: group.default ?? false
        )
      }
    }
    value[id: option.groupId] = group
    groups = .loaded(value)
  }
}

// MARK: Helpers

extension Playlist.ItemsRequestOptions {
  fileprivate var groupId: Playlist.Group.ID {
    switch self {
    case let .group(id):
      id
    case let .variant(id, _):
      id
    case let .page(id, _, _):
      id
    }
  }

  fileprivate var variantId: Playlist.Group.Variant.ID? {
    switch self {
    case .group:
      nil
    case let .variant(_, id):
      id
    case let .page(_, id, _):
      id
    }
  }

  fileprivate var pagingId: PagingID? {
    switch self {
    case let .page(_, _, id):
      id
    default:
      nil
    }
  }
}

extension Loadable {
  init(expected value: T?) {
    if let value {
      self = .loaded(value)
    } else {
      self = .failed(ContentCore.Error.contentNotFound)
    }
  }
}
