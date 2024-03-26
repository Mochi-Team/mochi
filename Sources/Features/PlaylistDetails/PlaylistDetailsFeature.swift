//
//  PlaylistDetailsFeature.swift
//
//
//  Created ErrorErrorError on 5/19/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import ContentCore
import DatabaseClient
import LoggerClient
import ModuleClient
import RepoClient
import SharedModels
import Styling
import SwiftUI
import ViewComponents

public struct PlaylistDetailsFeature: Feature {
  public struct Destination: ComposableArchitecture.Reducer {
    public enum State: Equatable, Sendable {
      case readMore(ReadMore.State)
    }

    public enum Action: Equatable, Sendable {
      case readMore(ReadMore.Action)
    }

    public var body: some ReducerOf<Self> {
      Scope(state: /State.readMore, action: /Action.readMore) {
        ReadMore()
      }
    }

    public struct ReadMore: ComposableArchitecture.Reducer {
      public struct State: Equatable, Sendable {
        public let title: String
        public let description: String

        public init(
          title: String,
          description: String
        ) {
          self.title = title
          self.description = description
        }
      }

      public enum Action: Equatable, Sendable {}

      public var body: some ReducerOf<Self> { EmptyReducer() }
    }
  }

  public struct State: FeatureState {
    public var content: ContentCore.State
    public var playlist: Playlist { content.playlist }
    public var details: Loadable<Playlist.Details>

    @PresentationState public var destination: Destination.State?

    public var playlistHistory: Loadable<PlaylistHistory> { content.playlistHistory }

    var playlistInfo: Loadable<PlaylistInfo> {
      details.map { .init(playlist: playlist, details: $0) }
    }

    public var resumableState: Resumable {
      // TODO: Show start based on last resumed or selected content?
      if playlist.status == .upcoming {
        return .upcoming
      }
      if let group = content.groups.value?.first(where: { $0.default ?? false }) ?? content.groups.value?.first,
         let variant = group.variants.value?.first {
        if let epId = playlistHistory.value?.epId {
          if let page = variant.pagings.value?.first(where: { $0.items.value!.contains(where: { $0.id.rawValue == epId }) }),
             let item = page.items.value?.first(where: { $0.id.rawValue == epId }) {
            return .resume(group.id, variant.id, page.id, item.id, item.title ?? "", playlistHistory.value?.timestamp ?? 0.0)
          }
        }
        if let page = variant.pagings.value?.first,
           let item = page.items.value?.first {
          return .start(group.id, variant.id, page.id, item.id)
        }
        return content.groups.didFinish ? .unavailable : .loading
      } else {
        return content.groups.didFinish ? .unavailable : .loading
      }
    }

    public init(
      content: ContentCore.State,
      details: Loadable<Playlist.Details> = .pending,
      destination: Destination.State? = nil
    ) {
      self.content = content
      self.details = details
      self.destination = destination
    }

    public enum Resumable: Equatable, Sendable {
      case upcoming
      case loading
      case start(Playlist.Group.ID, Playlist.Group.Variant.ID, PagingID, Playlist.Item.ID)
      case resume(Playlist.Group.ID, Playlist.Group.Variant.ID, PagingID, Playlist.Item.ID, String, Double)
      case unavailable

      var image: Image? {
        switch self {
        case .upcoming:
          .init(systemName: "calendar")
        case .loading:
          nil
        case .start:
          .init(systemName: "play.fill")
        case .resume:
          .init(systemName: "play.fill")
        case .unavailable:
          nil
        }
      }

      var action: Action? {
        switch self {
        case let .start(groupId, variantId, pagingId, itemId):
          .internal(.content(.didTapPlaylistItem(groupId, variantId, pagingId, id: itemId)))
        case let .resume(groupId, variantId, pagingId, itemId, _, _):
          .internal(.content(.didTapPlaylistItem(groupId, variantId, pagingId, id: itemId)))
        default:
          nil
        }
      }

      var description: String {
        switch self {
        case .upcoming:
          "Upcoming"
        case .loading:
          "Loading..."
        case .start:
          "Start"
        case .resume:
          "Resume"
        case .unavailable:
          "Unavailable"
        }
      }
    }
  }

  @CasePathable
  public enum Action: FeatureAction {
    @CasePathable
    public enum ViewAction: SendableAction, BindableAction {
      case onTask
      case didTappedBackButton
      case didTapToRetryDetails
      case didTapOnReadMore
      case binding(BindingAction<State>)
    }

    @CasePathable
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
    public enum InternalAction: SendableAction {
      case playlistDetailsResponse(Loadable<Playlist.Details>)
      case content(ContentCore.Action)
      case destination(PresentationAction<Destination.Action>)
    }

    case view(ViewAction)
    case delegate(DelegateAction)
    case `internal`(InternalAction)
  }

  @MainActor
  public struct View: FeatureView {
    public let store: StoreOf<PlaylistDetailsFeature>

    @Environment(\.openURL) var openURL
    @SwiftUI.State var imageDominatColor: Color?
    @Environment(\.theme) var theme

    @MainActor
    public init(store: StoreOf<PlaylistDetailsFeature>) {
      self.store = store
    }
  }

  @Dependency(\.moduleClient) var moduleClient
  @Dependency(\.databaseClient) var databaseClient
  @Dependency(\.repoClient) var repoClient
  @Dependency(\.dismiss) var dismiss

  public init() {}
}
