//
//  ViewMoreListing.swift
//
//
//  Created by ErrorErrorError on 12/13/23.
//
//

import Architecture
import ComposableArchitecture
import Foundation
import LocalizableClient
import LoggerClient
import ModuleClient
import OrderedCollections
import SharedModels
import Styling
import SwiftUI
import Tagged
import ViewComponents

// MARK: - ViewMoreListing

@Reducer
public struct ViewMoreListing: Reducer {
  enum Error: Swift.Error {
    case contentTypeMissing(expected: PagingID, found: PagingID?, listingId: DiscoverListing.ID)
  }

  public struct State: Equatable, Sendable {
    public let repoModuleId: RepoModuleID
    public let listing: DiscoverListing
    public var items: Items

    public typealias Items = OrderedDictionary<PagingID, Loadable<Paging<Playlist>>>

    public init(
      repoModuleId: RepoModuleID,
      listing: DiscoverListing,
      items: Items = [:]
    ) {
      self.repoModuleId = repoModuleId
      self.listing = listing
      self.items = .init(dictionaryLiteral: (listing.paging.id, .loaded(listing.paging)))
      self.items.merge(items, uniquingKeysWith: { _, new in new })
    }
  }

  public enum Action: Equatable, Sendable {
    case didTapBackButton
    case didTapPlaylist(Playlist)
    case didShowNextPageIndicator(id: PagingID)
    case update(id: PagingID, loadable: Loadable<Paging<Playlist>>)
  }

  @Dependency(\.dismiss)
  var dismiss

  @Dependency(\.moduleClient)
  var moduleClient

  public init() {}

  @ReducerBuilder<State, Action>
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .didTapBackButton:
        return .run { await dismiss() }
      case let .didShowNextPageIndicator(pageId):
        let id = state.repoModuleId
        let listingId = state.listing.id

        guard !(state.items[pageId]?.hasInitialized ?? false) else {
          break
        }

        state.items[pageId] = .loading

        return .run { send in
          let listings = try await moduleClient.withModule(id: id) { instance in
            try await instance.discoverListings(.init(listingId: listingId, page: pageId))
          }

          guard let listing = listings[id: listingId], listing.paging.id == pageId else {
            throw Error.contentTypeMissing(expected: pageId, found: listings[id: listingId]?.paging.id, listingId: listingId)
          }

          await send(.update(id: pageId, loadable: .loaded(listing.paging)))
        } catch: { error, send in
          if let error = error as? Error {
            logger.error("failed to retrieve discover listing: \(error.localizedDescription)")
          }

          await send(.update(id: pageId, loadable: .failed(error)))
        }
      case let .update(id, loadable):
        state.items[id] = loadable

      case .didTapPlaylist:
        break
      }
      return .none
    }
  }
}

extension ViewMoreListing {
  private struct ViewState: Equatable {
    let items: ViewMoreListing.State.Items
    let orientation: DiscoverListing.OrientationType
    let title: String

    init(state: ViewMoreListing.State) {
      self.items = state.items
      self.orientation = state.listing.orientation
      self.title = state.listing.title
    }
  }

  public struct View: SwiftUI.View {
    let store: StoreOf<ViewMoreListing>

    private let columns = 2

    @Dependency(\.localizableClient.localize)
    var localize

    public init(store: StoreOf<ViewMoreListing>) {
      self.store = store
    }

    public var body: some SwiftUI.View {
      WithViewStore(store, observe: ViewState.init) { viewStore in
        ScrollView(.vertical) {
          LazyVGrid(
            columns: .init(
              repeating: .init(
                .adaptive(minimum: 120),
                alignment: .top
              ),
              count: columns
            ),
            alignment: .leading
          ) {
            let allItems = viewStore.items.values.flatMap { $0.value?.items ?? [] }
            ForEach(allItems) { item in
              VStack(alignment: .leading) {
                FillAspectImage(url: item.posterImage)
                  .aspectRatio(viewStore.orientation == .portrait ? 2 / 3 : 16 / 9, contentMode: .fit)
                  .cornerRadius(12)

                Text(item.title ?? localize("Title Unavailable"))
                  .font(.footnote)
              }
              .contentShape(Rectangle())
              .onTapGesture {
                viewStore.send(.didTapPlaylist(item))
              }
            }
          }
          .padding(.horizontal)

          if let lastPage = viewStore.items.values.last {
            LoadableView(loadable: lastPage) { page in
              LazyView {
                Spacer()
                  .frame(height: 1)
                  .onAppear {
                    if let nextPageId = page.nextPage {
                      store.send(.didShowNextPageIndicator(id: nextPageId))
                    }
                  }
              }
            } failedView: { _ in
              Text(localizable: "Failed to retrieve content")
                .foregroundColor(.red)
            } waitingView: {
              ProgressView()
                .padding(.vertical, 8)
            }
          }
        }
        .navigationTitle(viewStore.state.title)
        #if os(iOS)
          .navigationBarTitleDisplayMode(.inline)
          .navigationBarBackButtonHidden()
          .toolbar {
            ToolbarItem(placement: .navigation) {
              Button {
                viewStore.send(.didTapBackButton)
              } label: {
                Image(systemName: "chevron.left")
              }
              .buttonStyle(.materialToolbarItem)
            }
          }
        #endif
      }
    }
  }
}
