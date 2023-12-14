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

    public init(
      repoModuleId: RepoModuleID,
      playlist: Playlist,
      groups: Loadable<[Playlist.Group]> = .pending
    ) {
      self.repoModuleId = repoModuleId
      self.playlist = playlist
      self.groups = groups
    }
  }

  @CasePathable
  @dynamicMemberLookup
  public enum Action: SendableAction {
    case update(option: Playlist.ItemsRequestOptions?, Loadable<Playlist.ItemsResponse>)
    case didTapContent(Playlist.ItemsRequestOptions)
    case didTapPlaylistItem(
      Playlist.Group.ID,
      Playlist.Group.Variant.ID,
      PagingID,
      id: Playlist.Item.ID
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

      case .didTapPlaylistItem:
        break

      case let .update(option, response):
        guard case var .loaded(value) = state.groups, let option, var group = value[id: option.groupId] else {
          state.groups = response.flatMap { .loaded($0) }
          break
        }

        let variantsResponse = response
          .flatMap { .init(expected: $0[id: group.id]) }
          .flatMap { .init(expected: $0.variants.value) }

        if case .group = option {
          group = .init(
            id: group.id,
            number: group.number,
            altTitle: group.altTitle,
            variants: variantsResponse
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
              }
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
              }
            )
          }
        }
        value[id: option.groupId] = group
        state.groups = .loaded(value)
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
    @Dependency(\.moduleClient)
    var moduleClient

    let playlistId = playlist.id
    let repoModuleId = repoModuleId

    // TODO: Force should modify the respective group/variant/paging

    if forced || !groups.hasInitialized {
      groups = .loading
    }

    return .run { send in
      try await withTaskCancellation(id: Cancellable.fetchContent, cancelInFlight: true) {
        let value = try await moduleClient.withModule(id: repoModuleId) { module in
          try await module.playlistEpisodes(playlistId, option)
        }

        await send(.update(option: option, .loaded(value)))
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
