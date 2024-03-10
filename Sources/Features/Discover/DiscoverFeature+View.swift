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
  @MainActor public var body: some View {
    NavStack(
      store.scope(
        state: \.path,
        action: \.internal.path
      )
    ) {
      WithViewStore(store, observe: \.section) { viewStore in
        ZStack {
          switch viewStore.state {
          case .empty:
            VStack {}
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
              WithViewStore(store) { state in
                !state.section.is(\.home)
              } content: { showMagnifyingGlass in
                Button {
                  viewStore.send(.didTapSearchButton)
                } label: {
                  Image(systemName: "magnifyingglass")
                }
                #if os(iOS)
                .buttonStyle(.materialToolbarItem)
                #endif
                .opacity(showMagnifyingGlass.state ? 1.0 : 0)
              }
            }
          }
      }
      .ignoresSafeArea(.keyboard)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .onAppear { store.send(.view(.didAppear)) }
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
        case .search:
          CaseLet(
            /DiscoverFeature.Path.State.search,
            action: DiscoverFeature.Path.Action.search,
            then: { store in SearchFeature.View(store: store) }
          )
        }
      }
    }
    .sheet(
      store: store.scope(
        state: \.$solveCaptcha,
        action: \.internal.solveCaptcha
      ),
      state: /DiscoverFeature.Captcha.State.solveCaptcha,
      action: DiscoverFeature.Captcha.Action.solveCaptcha
    ) { store in
      VStack {
        Capsule()
          .frame(width: 48, height: 4)
          .foregroundColor(.gray.opacity(0.26))
          .padding(.top, 8)

        WithViewStore(store, observe: \.`self`) { viewStore in
          WebView(html: viewStore.html, hostname: viewStore.hostname)
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
          store.send(.view(.didTapRetryLoadingModule))
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
        Spacer()
          .frame(height: 0)
          .fixedSize(horizontal: false, vertical: true)
        ForEach(listings, id: \.id) { listing in
          switch listing.type {
          case .default:
            rowListing(listing)
          case .rank:
            rankListing(listing)
          case .featured:
            featuredListing(listing)
          case .lastWatched:
            lastWatchedListing()
          }
        }
      }
    }
  }
}

extension DiscoverFeature.View {
  @MainActor
  func lastWatchedListing() -> some View {
    LazyVStack(alignment: .leading) {
      HStack {
        Text("Last Watched")
          .font(.title3.weight(.semibold))

        Spacer()

//        if listing.paging.nextPage != nil {
//          Button {
//            store.send(.view(.didTapViewMoreListing(listing.id)))
//          } label: {
//            Text(localizable: "View More")
//              .font(.footnote.weight(.bold))
//              .foregroundColor(.gray)
//              .opacity(listing.items.isEmpty ? 0 : 1.0)
//          }
//          .buttonStyle(.plain)
//        }
      }
      .padding(.horizontal)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(alignment: .top, spacing: 12) {
          WithViewStore(store, observe: \.`self`) { viewStore in
            ForEach(viewStore.lastWatched ?? [], id: \.self) { item in
              VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .bottom) {
                  FillAspectImage(url: item.thumbnail ?? URL(string: ""))
                    .aspectRatio(16 / 10, contentMode: .fit)
                    .overlay {
                      LinearGradient(
                        gradient: .init(
                          colors: [
                            .black.opacity(0),
                            .black.opacity(0.8)
                          ],
                          easing: .easeIn
                        ),
                        startPoint: .top,
                        endPoint: .bottom
                      )
                    }

                  VStack(alignment: .leading, spacing: 5) {
                    Text(item.playlistName ?? "No Title")
                      .lineLimit(3)
                      .font(.subheadline.weight(.medium))
                      .multilineTextAlignment(.leading)
                      .fixedSize(horizontal: false, vertical: true)
                      .foregroundColor(.white)
                      .padding(.horizontal)

                    GeometryReader { proxy in
                      Color(.white)
                        .opacity(0.8)
                        .frame(maxWidth: proxy.size.width * item.timestamp)
                    }
                    .clipShape(Capsule(style: .continuous))
                    .frame(maxWidth: .infinity)
                    .frame(height: 6)
                  }
                }
                .cornerRadius(12)
                .contextMenu {
                  Button(role: .destructive) {
                    viewStore.send(.view(.didTapRemovePlaylistHistory(item.repoId, item.moduleId, item.playlistID)))
                  } label: {
                    Label("Remove from history", systemImage: "trash.fill")
                  }
                  .buttonStyle(.plain)
                }

                Text(item.epName ?? "No Title")
                  .lineLimit(3)
                  .font(.subheadline.weight(.medium))
                  .multilineTextAlignment(.leading)
                  .fixedSize(horizontal: false, vertical: true)
              }
              .frame(width: 248)
              .contentShape(Rectangle())
              .onTapGesture {
                store.send(.view(.didTapContinueWatching(item)))
              }
              .animation(.easeInOut, value: viewStore.lastWatched)
            }
          }
        }
        .padding(.horizontal)
      }
      .frame(maxWidth: .infinity)
    }
  }

  @MainActor
  func rowListing(_ listing: DiscoverListing) -> some View {
    listingViewContainer(listing) {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(alignment: .top, spacing: 12) {
          ForEach(listing.items) { playlist in
            VStack(alignment: .leading, spacing: 6) {
              FillAspectImage(url: playlist.posterImage ?? playlist.bannerImage)
                .aspectRatio(listing.orientation.aspectRatio, contentMode: .fit)
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

  @MainActor
  func rankListing(_ listing: DiscoverListing) -> some View {
    listingViewContainer(listing) {
      let rowCount = 3
      let sections: Int = (listing.items.count - 1) / rowCount

      ReadableSizeView { size in
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHStack(alignment: .top) {
            ForEach(Array(0...sections), id: \.self) { col in
              VStack(alignment: .leading, spacing: 6) {
                let start = col * rowCount
                let end = start + min(rowCount, listing.items.count - start)

                ForEach(start..<end, id: \.self) { idx in
                  let playlist = listing.items[idx]
                  HStack(alignment: .center, spacing: 8) {
                    Text("\(idx + 1)")
                      .font(.body.monospacedDigit().weight(.bold))

                    FillAspectImage(
                      url: playlist.posterImage,
                      transaction: .init(animation: .easeInOut(duration: 0.16))
                    )
                    .aspectRatio(listing.orientation.aspectRatio, contentMode: .fit)
                    .frame(width: 80)
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
              .frame(width: horizontalSizeClass == .compact ? size.width * 0.8 : size.width * 0.9 / 3)
              .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
          }
          .frame(maxWidth: .infinity)
          .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
      }
      .frame(maxWidth: .infinity)
    }
  }

  @MainActor
  @ViewBuilder
  func featuredListing(_ listing: DiscoverListing) -> some View {
    listingViewContainer(listing) {
      ReadableSizeView { size in
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHStack(spacing: 16) {
            ForEach(listing.items) { playlist in
              ZStack(alignment: .bottom) {
                FillAspectImage(url: playlist.posterImage ?? playlist.bannerImage)
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
              .aspectRatio(listing.orientation.aspectRatio, contentMode: .fit)
              .frame(
                width: horizontalSizeClass == .compact ? size.width * 0.8 :
                  listing.orientation == .portrait ? min(178, size.width * 0.9 / 4) :
                  min(220, size.width * 0.9 / 4)
              )
              .frame(maxHeight: .infinity)
              .clipShape(RoundedRectangle(cornerRadius: 18))
              .onTapGesture { store.send(.view(.didTapPlaylist(playlist))) }
            }
          }
          .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
      }
      .frame(maxWidth: .infinity)
    }
  }
}

extension DiscoverFeature.View {
  @MainActor
  func listingViewContainer(_ listing: DiscoverListing, @ViewBuilder content: () -> some View) -> some View {
    LazyVStack(alignment: .leading) {
      HStack {
        Text(
          listing.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No Title" :
            listing.title.trimmingCharacters(in: .whitespacesAndNewlines)
        )
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
        content()
      }
    }
  }
}

extension DiscoverListing.OrientationType {
  var aspectRatio: Double {
    self == .portrait ? 3 / 4 : 16 / 10
  }
}

// MARK: - DiscoverView_Previews

#Preview {
  DiscoverFeature.View(
    store: .init(
      initialState: .init(
        section: .module(
          .init(
            module: .init(
              repoId: .init(rawValue: .init(string: "/").unsafelyUnwrapped),
              module: .init()
            ),
            listings: .pending
          )
        )
      ),
      reducer: { EmptyReducer() }
    )
  )
}

#if os(macOS)
extension ToolbarItemPlacement {
  static var topBarTrailing = Self.automatic
}
#endif
