//
//  LibraryFeature+View.swift
//
//
//  Created by MochiTeam on 09.04.2024.
//

import Architecture
import ComposableArchitecture
import LocalizableClient
import Foundation
import SwiftUI
import ViewComponents
import Styling
import PlaylistDetails
import AVKit
import DownloadQueue

// MARK: - LibraryFeature + View

extension LibraryFeature.View: View {
  @MainActor public var body: some View {
    NavStack(
      store.scope(
        state: \.path,
        action: \.internal.path
      )
    ) {
      WithViewStore(store, observe: \.`self`) { viewStore in
        LoadableView(loadable: viewStore.state.playlists) { playlists in
          ScrollView(.vertical) {
            LazyVGrid(
              columns: [.init(.adaptive(minimum: 120), alignment: .top)],
              alignment: .leading
            ) {
              ForEach(viewStore.searchValue.isEmpty ? playlists : viewStore.searchedPlaylists, id: \.playlist.id) { item in
                VStack(alignment: .leading) {
                  FillAspectImage(url: item.playlist.posterImage ?? item.playlist.bannerImage ?? URL(string: "")!)
                    .aspectRatio(3 / 4, contentMode: .fit)
                    .cornerRadius(12)
                    .contextMenu {
                      Button(role: .destructive) {
                        viewStore.send(.didTapRemoveBookmark(item))
                      } label: {
                        Label("Remove Bookmark", systemImage: "bookmark.slash")
                      }
                    }
                  Text(item.playlist.title ?? "")
                    .font(.footnote)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                  viewStore.send(.didTapPlaylist(item))
                }
              }
            }
            .animation(.easeInOut, value: viewStore.searchedPlaylists)
            .animation(.easeInOut, value: playlists)
            .safeAreaInset(edge: .top) {
              ScrollView(.horizontal, showsIndicators: false) {
                WithViewStore(store, observe: \.showOfflineOnly) { viewStore in
                  Button {
                    viewStore.send(.didTapShowDownloadedOnly)
                  } label: {
                    Text("Downloaded")
                      .font(.footnote)
                      .foregroundStyle(viewStore.state ? Color.white : Theme.pastelRed)
                      .padding(8)
                      .background(
                        Capsule()
                          .style(
                            withStroke: Color.gray.opacity(0.2),
                            fill: viewStore.state ? Theme.pastelRed : buttonBackgroundColor
                          )
                      )
                  }
                }
              }
            }
            .padding(.horizontal)
          }
          .searchable(text: viewStore.$searchValue.removeDuplicates(), placement: .toolbar)
        }
      }
      .toolbar {
        ToolbarItem(placement: .navigation) {
          Button {
//                store.send(.view(.didtapOpenLibraryCollectionSheet))
          } label: {
            HStack(alignment: .center, spacing: 8) {
              Text(selectedDirectory ?? "Library")

//              Image(systemName: "chevron.down")
//                .font(.caption.weight(.bold))
//                .foregroundColor(.gray)
            }
            #if os(iOS)
            .font(.title.bold())
            #else
            .font(.title3.bold())
            #endif
            .contentShape(Rectangle())
            .scaleEffect(1.0)
            .transition(.opacity)
          }
          #if os(macOS)
          .buttonStyle(.bordered)
          #else
          .buttonStyle(.plain)
          #endif
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            store.send(.view(.didTapDownloadQueue))
          } label: {
            Image(systemName: "arrow.down.circle")
          }
          .foregroundColor(Theme.pastelRed)
        }
      }
      .navigationTitle("")
#if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
#endif
    } destination: { store in
      SwitchStore(store) { state in
        switch state {
        case .playlistDetails:
          CaseLet(
            /LibraryFeature.Path.State.playlistDetails,
            action: LibraryFeature.Path.Action.playlistDetails,
            then: { store in PlaylistDetailsFeature.View(store: store) }
          )
        case .downloadQueue:
          CaseLet(
            /LibraryFeature.Path.State.downloadQueue,
            action: LibraryFeature.Path.Action.downloadQueue,
            then: { store in DownloadQueueFeature.View(store: store) }
          )
        }
      }
    }
    .onAppear {
      store.send(.view(.didAppear))
    }
  }
}

#Preview {
  LibraryFeature.View(
    store: .init(
      initialState: .init(
        path: .init(),
        playlists: .loaded(.init())
      ),
      reducer: { EmptyReducer() }
    )
  )
}
