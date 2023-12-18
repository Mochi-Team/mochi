//
//  SearchFeature.swift
//
//
//  Created ErrorErrorError on 4/18/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import ModuleClient
import ModuleLists
import OrderedCollections
import PlaylistDetails
import RepoClient
import SharedModels
import Styling
import SwiftUI
import Tagged
import ViewComponents

public struct SearchFeature: Feature {
  public struct SearchResult: Equatable, Sendable {
    private let initial: Paging<Playlist>
    private var loadables: OrderedDictionary<PagingID, Loadable<Paging<Playlist>>> = .init()

    public var items: [Playlist] {
      initial.items + loadables.values.flatMap(\.value?.items ?? [])
    }

    public var nextPage: Loadable<PagingID>? {
      initial.nextPage.flatMap { loadables[$0] == nil ? .loaded($0) : nil } ??
        loadables.values.last?.optionalMap(\.nextPage)
    }

    public init(
      initial: Paging<Playlist>,
      loadables: OrderedDictionary<PagingID, Loadable<Paging<Playlist>>> = .init()
    ) {
      self.initial = initial
      self.loadables = loadables
    }

    mutating func update(_ id: PagingID, loadable: Loadable<Paging<Playlist>>) {
      loadables[id] = loadable
    }

    func pagingExists(_ id: PagingID) -> Bool {
      initial.id == id || loadables[id] != nil
    }
  }

  public struct State: FeatureState {
    @BindingState public var query: String
    @BindingState public var selectedFilters: [SearchFilter]

    public let repoModuleId: RepoModuleID
    public var allFilters: [SearchFilter]
    public var searchResult = Loadable<SearchResult>.pending

    public init(
      repoModuleId: RepoModuleID,
      query: String = "",
      selectedFilters: [SearchFilter] = [],
      allFilters: [SearchFilter] = [],
      searchResult: Loadable<SearchResult> = .pending
    ) {
      self.repoModuleId = repoModuleId
      self.query = query
      self.selectedFilters = selectedFilters
      self.allFilters = allFilters
      self.searchResult = searchResult
    }
  }

  @CasePathable
  public enum Action: FeatureAction {
    @CasePathable
    public enum ViewAction: SendableAction, BindableAction {
      case didAppear
      case didTapClearQuery
      case didTapClearFilters
      case didTapBackButton
      case didTapFilter(SearchFilter, SearchFilter.Option)
      case didTapPlaylist(Playlist)
      case didShowNextPageIndicator(PagingID)
      case binding(BindingAction<State>)
    }

    @CasePathable
    public enum DelegateAction: SendableAction {
      case playlistTapped(RepoModuleID, Playlist)
    }

    @CasePathable
    public enum InternalAction: SendableAction {
      case loadedSearchFilters(TaskResult<[SearchFilter]>)
      case loadedItems(Loadable<Paging<Playlist>>)
      case loadedPageResult(PagingID, Loadable<Paging<Playlist>>)
    }

    case view(ViewAction)
    case delegate(DelegateAction)
    case `internal`(InternalAction)
  }

  @MainActor
  public struct View: FeatureView {
    public let store: StoreOf<SearchFeature>

    @SwiftUI.State var showStatusBarBackground = false
    @Environment(\.theme) var theme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @MainActor
    public init(store: StoreOf<SearchFeature>) {
      self.store = store
    }
  }

  @Dependency(\.dismiss) var dismiss
  @Dependency(\.moduleClient) var moduleClient
  @Dependency(\.repoClient) var repoClient

  public init() {}
}
