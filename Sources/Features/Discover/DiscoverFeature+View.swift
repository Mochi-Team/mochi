//
//  DiscoverFeature+View.swift
//
//
//  Created by ErrorErrorError on 4/5/23.
//
//

import Architecture
import ComposableArchitecture
import ModuleLists
import Nuke
import NukeUI
import PlaylistDetails
import Search
import SharedModels
import Styling
import SwiftUI
import ViewComponents

// MARK: - DiscoverFeature.View + View

extension DiscoverFeature.View: View {
  @MainActor
  public var body: some View {
    NavStack(
      store.scope(
        state: \.path,
        action: \.internal.path
      )
    ) {
      WithViewStore(store, observe: \.section) { viewStore in
        ZStack {
          switch viewStore.state {
          case .home:
            // TODO: Create home listing
            VStack {
              Spacer()
              Text("Coming soon!")
              Spacer()
            }
          case let .module(moduleState):
            buildModuleView(moduleState: moduleState)
          }
        }
        .animation(.easeInOut(duration: 0.25), value: viewStore.state)
        .navigationTitle("")
        #if os(iOS)
          .navigationBarTitleDisplayMode(.inline)
        #endif
          .toolbar {
            ToolbarItem(placement: .navigation) {
              Button {
                viewStore.send(.didTapOpenModules)
              } label: {
                HStack(spacing: 8) {
                  if let url = viewStore.icon {
                    LazyImage(url: url) { state in
                      if let image = state.image {
                        image
                          .resizable()
                          .scaledToFit()
                          .frame(width: 22, height: 22)
                      } else {
                        EmptyView()
                      }
                    }
                    .transition(.opacity)
                  }

                  Text(viewStore.title)

                  Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.gray)
                }
                #if os(iOS)
                .font(.title.bold())
                #else
                .font(.title3.bold())
                #endif
                .contentShape(Rectangle())
                .scaleEffect(1.0)
                .transition(.opacity)
                .animation(.easeInOut, value: viewStore.icon)
              }
              #if os(macOS)
              .buttonStyle(.bordered)
              #else
              .buttonStyle(.plain)
              #endif
            }

            ToolbarItem(placement: .automatic) {
              Button {
                viewStore.send(.didTapSearchButton)
              } label: {
                Image(systemName: "magnifyingglass")
              }
              #if os(iOS)
              .buttonStyle(.materialToolbarItem)
              #endif
            }
          }
      }
      .ignoresSafeArea(.keyboard)
      .frame(
        maxWidth: .infinity,
        maxHeight: .infinity
      )
      .onAppear { store.send(.view(.didAppear)) }
      .stackDestination(
        store: store.scope(
          state: \.$search,
          action: \.internal.search
        )
      ) { store in
        SearchFeature.View(store: store)
      }
      .moduleListsSheet(
        store.scope(
          state: \.$moduleLists,
          action: \.internal.moduleLists
        )
      )
    } destination: { store in
      SwitchStore(store) { state in
        switch state {
        case .playlistDetails:
          CaseLet(
            /DiscoverFeature.Path.State.playlistDetails,
            action: DiscoverFeature.Path.Action.playlistDetails,
            then: { store in PlaylistDetailsFeature.View(store: store) }
          )
        case .viewMoreListing:
          CaseLet(
            /DiscoverFeature.Path.State.viewMoreListing,
            action: DiscoverFeature.Path.Action.viewMoreListing,
            then: { store in ViewMoreListing.View(store: store) }
          )
        }
      }
    }
  }
}

extension DiscoverFeature.View {
  @MainActor
  func buildModuleView(moduleState: DiscoverFeature.Section.ModuleListingState) -> some View {
    LoadableView(loadable: moduleState.listings) { listings in
      Group {
        if listings.isEmpty {
          VStack(spacing: 12) {
            Spacer()
            Text(localizable: "Listings Empty")
              .font(.title2.weight(.medium))
            Text(localizable: "There are no listings for this module")
            Spacer()
          }
          .foregroundColor(.gray)
        } else {
          buildListingsView(listings)
        }
      }
      .transition(.opacity)
    } failedView: { _ in
      VStack(spacing: 12) {
        Spacer()

        Text(localizable: "Module Error")
          .font(.title2.weight(.medium))
        Text(String(localizable: "There was an error retrieving content"))
        Button {
          // TODO: Allow retrying
        } label: {
          Text(localizable: "Retry")
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
              RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.gray.opacity(0.25))
            }
        }
        .buttonStyle(.plain)

        Spacer()
      }
      .transition(.opacity)
    } waitingView: {
      let placeholders: [Playlist] = (0..<10).map { .placeholder($0) }

      // TODO: Make it localizable?
      buildListingsView(
        [
          .init(
            id: "0",
            title: "placeholder title 1",
            type: .featured,
            paging: .init(
              id: "demo-1",
              items: placeholders
            )
          ),
          .init(
            id: "1",
            title: "placeholder title 2",
            type: .default,
            paging: .init(
              id: "demo-1",
              items: placeholders
            )
          ),
          .init(
            id: "2",
            title: "placeholder title 3",
            type: .rank,
            paging: .init(
              id: "demo-1",
              items: placeholders
            )
          ),
          .init(
            id: "3",
            title: "placeholder title 4",
            type: .default,
            paging: .init(
              id: "demo-1",
              items: placeholders
            )
          )
        ]
      )
      .shimmering()
      .disabled(true)
      .transition(.opacity)
    }
  }
}

extension DiscoverFeature.View {
  @MainActor
  func buildListingsView(_ listings: [DiscoverListing]) -> some View {
    ScrollView(.vertical, showsIndicators: false) {
      VStack(spacing: 24) {
        ForEach(listings, id: \.id) { listing in
          switch listing.type {
          case .default:
            rowListing(listing)
          case .rank:
            rankListing(listing)
          case .featured:
            featuredListing(listing)
          }
        }
      }
    }
  }
}

extension DiscoverFeature.View {
  @MainActor
  func rowListing(_ listing: DiscoverListing) -> some View {
    LazyVStack(alignment: .leading) {
      HStack {
        Text(listing.title)
          .font(.system(size: 18, weight: .semibold))

        Spacer()

        if listing.paging.nextPage != nil {
          Button {
            store.send(.view(.didTapViewMoreListing(listing.id)))
          } label: {
            Text(localizable: "View More")
              .font(.system(size: 13, weight: .bold))
              .foregroundColor(.gray)
              .opacity(listing.items.isEmpty ? 0 : 1.0)
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal)

      if listing.items.isEmpty {
        Color.gray.opacity(0.2)
          .frame(maxWidth: .infinity)
          .frame(height: 128)
          .cornerRadius(12)
          .padding(.horizontal)
          .overlay(
            Text(localizable: "No content available")
              .font(.callout.weight(.medium))
          )
      } else {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(alignment: .top, spacing: 12) {
            ForEach(listing.items) { playlist in
              VStack(alignment: .leading, spacing: 6) {
                LazyImage(
                  url: playlist.posterImage,
                  transaction: .init(animation: .easeInOut(duration: 0.16))
                ) { state in
                  if let image = state.image {
                    image.resizable()
                  } else {
                    Color.gray
                      .opacity(0.35)
                  }
                }
                .aspectRatio(5 / 7, contentMode: .fit)
                .cornerRadius(12)

                Text(playlist.title ?? "No Title")
                  .lineLimit(3)
                  .font(.subheadline.weight(.medium))
                  .multilineTextAlignment(.leading)
                  .fixedSize(horizontal: false, vertical: true)
              }
              .frame(width: 124)
              .contentShape(Rectangle())
              .onTapGesture {
                store.send(.view(.didTapPlaylist(playlist)))
              }
            }
          }
          .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
      }
    }
    .frame(maxWidth: .infinity)
  }

  @MainActor
  func rankListing(_ listing: DiscoverListing) -> some View {
    LazyVStack(alignment: .leading) {
      HStack {
        Text(listing.title)
          .font(.title3.weight(.semibold))

        Spacer()

        if listing.paging.nextPage != nil {
          Button {
            store.send(.view(.didTapViewMoreListing(listing.id)))
          } label: {
            Text(localizable: "View More")
              .font(.footnote.weight(.bold))
              .foregroundColor(.gray)
              .opacity(listing.items.isEmpty ? 0 : 1.0)
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal)

      if listing.items.isEmpty {
        Color.gray.opacity(0.2)
          .frame(maxWidth: .infinity)
          .frame(height: 128)
          .cornerRadius(12)
          .padding(.horizontal)
          .overlay(
            Text(localizable: "No content available")
              .font(.callout.weight(.medium))
          )
      } else {
        let rowCount = 3
        let sections: Int = (listing.items.count - 1) / rowCount
        SnapScroll(
          alignment: .top,
          spacing: 20,
          edgeInsets: .init(trailing: 40),
          items: Array(0...sections)
        ) { col in
          let start = col * rowCount
          let end = start + min(rowCount, listing.items.count - start)

          VStack(alignment: .leading, spacing: 6) {
            ForEach(start..<end, id: \.self) { idx in
              let playlist = listing.items[idx]
              HStack(alignment: .center, spacing: 8) {
                Text("\(idx + 1)")
                  .font(.body.monospacedDigit().weight(.bold))

                LazyImage(
                  url: playlist.posterImage,
                  transaction: .init(animation: .easeInOut(duration: 0.16))
                ) { state in
                  if let image = state.image {
                    image.resizable()
                  } else {
                    Color.gray
                      .opacity(0.35)
                  }
                }
                .aspectRatio(5 / 7, contentMode: .fill)
                .frame(width: 64)
                .cornerRadius(12)

                Text(playlist.title ?? "No Title")
                  .lineLimit(3)
                  .font(.subheadline.weight(.medium))
                  .multilineTextAlignment(.leading)
                  .fixedSize(horizontal: false, vertical: true)

                Spacer()
              }
              .frame(maxWidth: .infinity)
              .fixedSize(horizontal: false, vertical: true)
              .contentShape(Rectangle())
              .onTapGesture {
                store.send(.view(.didTapPlaylist(playlist)))
              }

              if idx < (end - 1) {
                Divider()
              }
            }
            .frame(maxWidth: .infinity)
          }
          .frame(maxWidth: .infinity)
        }
        .aspectRatio(1.5, contentMode: .fill)
        .frame(maxWidth: .infinity)
      }
    }
    .frame(maxWidth: .infinity)
  }

  @MainActor
  @ViewBuilder
  func featuredListing(_ listing: DiscoverListing) -> some View {
    VStack {
      HStack {
        Text(listing.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No Title" : listing.title)
          .font(.title3.weight(.semibold))

        Spacer()

        if listing.paging.nextPage != nil {
          Button {
            store.send(.view(.didTapViewMoreListing(listing.id)))
          } label: {
            Text(localizable: "View More")
              .font(.footnote.weight(.bold))
              .foregroundColor(.gray)
              .opacity(listing.items.isEmpty ? 0 : 1.0)
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal)

      // TODO: Make size based on listing's size type
      // TODO: Make it snap for devices lower than iOS 17 (other platforms too)
      // TODO: Show indicators for macOS
      GeometryReader { proxy in
        let maxWidthPerItem = proxy.size.width * 0.8
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHStack {
            ForEach(listing.items) { playlist in
              ZStack(alignment: .bottom) {
                FillAspectImage(url: playlist.posterImage ?? playlist.bannerImage)
                  // TODO: Make gradient with blur
                  .overlay {
                    LinearGradient(
                      gradient: .init(
                        colors: [
                          .black.opacity(0),
                          .black.opacity(0.4)
                        ],
                        easing: .easeIn
                      ),
                      startPoint: .top,
                      endPoint: .bottom
                    )
                  }

                Text(playlist.title ?? "No Title")
                  .font(.title3.weight(.medium))
                  .foregroundColor(.white)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .padding(.horizontal)
                  .padding(.bottom)
              }
              .cornerRadius(12)
              .onTapGesture {
                store.send(.view(.didTapPlaylist(playlist)))
              }
              .frame(width: maxWidthPerItem)
              .frame(maxHeight: .infinity)
            }
          }
          .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .aspectRatio(listing.orientation == .portrait ? 6 / 7 : 16 / 10, contentMode: .fit)
    }
  }
}

// MARK: - DiscoverView_Previews

#Preview {
  DiscoverFeature.View(
    store: .init(
      initialState: .init(section: .home()),
      reducer: { DiscoverFeature() }
    )
  )
}

#if os(macOS)
extension ToolbarItemPlacement {
  static var topBarTrailing = Self.automatic
}
#endif
