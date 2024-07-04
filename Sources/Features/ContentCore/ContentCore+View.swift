//
//  ContentCore+View.swift
//
//
//  Created by MochiTeam on 7/13/23.
//
//

import Architecture
import ComposableArchitecture
import SharedModels
import Styling
import SwiftUI
import ViewComponents

// MARK: - ContentCore.View

extension ContentCore {
  @MainActor
  public struct View: SwiftUI.View {
    public let store: StoreOf<ContentCore>

    @ObservedObject private var viewStore: ViewStoreOf<ContentCore>
    private let contentType: Playlist.PlaylistType
      
    @MainActor
    public init(
      store: StoreOf<ContentCore>,
      contentType: Playlist.PlaylistType = .video,
      selectedGroupId: Playlist.Group.ID? = nil,
      selectedVariantId: Playlist.Group.Variant.ID? = nil,
      selectedPageId: PagingID? = nil,
      selectedItemId: Playlist.Item.ID? = nil
    ) {
      self.store = store
      self.contentType = contentType
      self._viewStore = .init(wrappedValue: .init(store, observe: \.`self`))
      self.__selectedGroupId = .init(wrappedValue: selectedGroupId)
      self.__selectedVariantId = .init(wrappedValue: selectedVariantId)
      self.__selectedPagingId = .init(wrappedValue: selectedPageId)
      self.selectedItemId = selectedItemId
    }

    @Environment(\.theme) var theme

    @SwiftUI.State private var _selectedGroupId: Playlist.Group.ID?
    @SwiftUI.State private var _selectedVariantId: Playlist.Group.Variant.ID?
    @SwiftUI.State private var _selectedPagingId: PagingID?

    private let selectedItemId: Playlist.Item.ID?

    private var groupLoadable: Loadable<Playlist.Group> {
      viewStore.groups.map { groups in _selectedGroupId.flatMap { groups[id: $0] } ?? groups.first { $0.default ?? false } ?? groups.first }
        .flatMap(Loadable.init)
    }

    private var variantLoadable: Loadable<Playlist.Group.Variant> {
      groupLoadable.flatMap(\.variants)
        .map { variants in _selectedVariantId.flatMap { variants[id: $0] } ?? variants.first }
        .flatMap(Loadable.init)
    }

    private var pageLoadable: Loadable<LoadablePaging<Playlist.Item>> {
      variantLoadable.flatMap(\.pagings)
        .map { pagings in _selectedPagingId.flatMap { pagings[id: $0] } ?? pagings.first }
        .flatMap(Loadable.init)
    }

    private var hasMultipleGroups: Bool {
      (viewStore.groups.value?.count ?? 0) > 1
    }

    @MainActor public var body: some SwiftUI.View {
      HeaderWithContent {
        VStack {
          HStack(alignment: .center) {
            /// Groups
            Menu {
              if hasMultipleGroups {
                ForEach(viewStore.groups.value ?? [], id: \.id) { group in
                  Button {
                    _selectedGroupId = group.id
                    store.send(.didTapContent(.group(group.id)))
                  } label: {
                    Text(group.altTitle ?? .init(
                      format: contentType.multiGroupsDefaultTitle,
                      group.number.withoutTrailingZeroes
                    ))
                  }
                }
              }
            } label: {
              if let selectedGroup = groupLoadable.value, hasMultipleGroups {
                HStack {
                  Text(
                    selectedGroup.altTitle ?? .init(
                      format: contentType.multiGroupsDefaultTitle,
                      selectedGroup.number.withoutTrailingZeroes
                    )
                  )
                  Image(systemName: "chevron.compact.down")
                  Spacer()
                }
              } else {
                Text(groupLoadable.value?.altTitle ?? contentType.oneGroupDefaultTitle)
              }
            }
            .menuStyle(.automatic)
            .buttonStyle(.plain)
            .animation(.easeInOut, value: _selectedGroupId)

            Spacer()

            // TODO: Add option to show/hide pagings with infinie scroll
            /// Pagings
            Menu {
              if let pagings = variantLoadable.value?.pagings.value {
                ForEach(Array(zip(pagings.indices, pagings)), id: \.1.id) { index, paging in
                  Button {
                    _selectedPagingId = paging.id

                    if let groupId = groupLoadable.value?.id, let variantId = variantLoadable.value?.id {
                      store.send(.didTapContent(.page(groupId, variantId, paging.id)))
                    }
                  } label: {
                    Text(paging.title ?? "Page \(index + 1)")
                  }
                }
              }
            } label: {
              let textView: (String) -> some SwiftUI.View = { text in
                Text(text)
                  .padding(.horizontal, 8)
                  .padding(.vertical, 6)
                  .background(.thinMaterial, in: Capsule())
              }

              if let selectedPage = pageLoadable.value,
                 let index = variantLoadable.value?.pagings.value?.firstIndex(where: \.id == selectedPage.id) {
                textView(selectedPage.title ?? "Page \(index + 1)")
              } else {
                textView("Not Selected")
              }
            }
            .menuStyle(.automatic)
            .buttonStyle(.plain)
            .font(.footnote.weight(.semibold))
            .shimmering(active: !variantLoadable.didFinish)
            .animation(.easeInOut, value: _selectedPagingId)
          }
          .frame(maxWidth: .infinity)
          .padding(.horizontal)

          // TODO: Allow variations to also be a menu?
          if groupLoadable.value?.variants.value?.count != 1 {
            ScrollView(.horizontal) {
              HStack(spacing: 6) {
                if let selectedVariant = variantLoadable.value {
                  ChipView(text: selectedVariant.title)
                    .background(Color.blue)
                    .foregroundColor(.white)
                }

                if let variants = groupLoadable.value?.variants.value {
                  ForEach(variants, id: \.id) { variant in
                    if variant.id != variantLoadable.value?.id {
                      ChipView(text: variant.title)
                        .onTapGesture {
                          if let groupId = groupLoadable.value?.id {
                            _selectedVariantId = variant.id
                            store.send(.didTapContent(.variant(groupId, variant.id)))
                          }
                        }
                    }
                  }
                }
              }
              .padding(.horizontal)
            }
            .font(.footnote.weight(.semibold))
            .frame(maxWidth: .infinity)
            .shimmering(active: !groupLoadable.didFinish)
            .animation(.easeInOut, value: _selectedVariantId)
          }
        }
        .frame(maxWidth: .infinity)
        .foregroundColor(theme.textColor)
      } content: {
        let items = pageLoadable.flatMap(\.items)
        ZStack {
          if items.error != nil {
            StatusView(
              title: "Content Error",
              description: "There was an error loading content.",
              foregroundColor: .red
            )
          } else if items.didFinish, (items.value?.count ?? 0) == 0 {
            StatusView(
              title: "Content List Empty",
              description: "There is no content available."
            )
          } else {
            ScrollViewReader { proxy in
              ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                  ForEach(items.value ?? Self.placeholderItems, id: \.number) { item in
                    let isDownloaded = viewStore.downloadedEpisodes.contains(item.id.rawValue.replacingOccurrences(of: "/", with: "\\"))
                    VStack(alignment: .leading, spacing: 0) {
                        ZStack {
                            FillAspectImage(url: item.thumbnail ?? viewStore.playlist.posterImage)
                                .aspectRatio(16 / 9, contentMode: .fit)
                                .cornerRadius(12)
                            
                            VStack {
                                HStack {
                                    Spacer()
                                    if isDownloaded == true {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 20, weight: .black))
                                            .foregroundColor(.white)
                                            .padding(7)
                                            .background(.green)
                                            .clipShape(Circle())
                                            .padding(.top, 7.5)
                                            .padding(.trailing, 7.5)
                                        
                                    }
                                    else if isDownloaded == false{
                                        Button(action: {
                                            store.send(.didTapDownloadPlaylist(item))
                                            
                                        }) {
                                            Image(systemName: "arrow.down")
                                                .font(.system(size: 20, weight: .black))
                                                .foregroundColor(.black)
                                                .padding(7)
                                                .background(.white)
                                                .clipShape(Circle())
                                        }
                                        .padding(.top, 7.5)
                                        .padding(.trailing, 7.5)
                                        
                                    }
                                }
                                Spacer()
                            }
                        }
                        .contextMenu {
                          if isDownloaded {
                            Button(role: .destructive) {
                              store.send(.didTapRemoveDownloadedPlaylist(item))
                            } label: {
                              Label("Remove episode", systemImage: "trash")
                            }
                            .buttonStyle(.plain)
                          }
                        }

                      Spacer()
                        .frame(height: 8)
                        
                      HStack {
                        Text(String(format: contentType.itemTypeWithNumber, item.number.withoutTrailingZeroes))
                          .font(.footnote.weight(.semibold))
                          .foregroundColor(.init(white: 0.4))
                        if isDownloaded {
                          Image(systemName: "cloud.fill")
                            .foregroundColor(.init(white: 0.4))
                        }
                      }
                      
                      Spacer()
                        .frame(height: 4)
                      
                      Text(item.title ?? String(format: contentType.itemTypeWithNumber, item.number.withoutTrailingZeroes))
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.primary)
                        .multilineTextAlignment(.leading)
                    }
                    .frame(width: 228)
                    .contentShape(Rectangle())
                    .onTapGesture {
                      if let groupId = groupLoadable.value?.id,
                         let variantId = variantLoadable.value?.id,
                         let pageId = pageLoadable.value?.id {
                        store.send(.didTapPlaylistItem(groupId, variantId, pageId, id: item.id, shouldReset: true))
                      }
                    }
                    .id(item.id)
                  }
                  .frame(maxHeight: .infinity, alignment: .top)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.bottom)
              }
              .onAppear {
                proxy.scrollTo(selectedItemId, anchor: .center)
                if items == .pending {
                  guard let groupId = groupLoadable.value?.id else {
                    return
                  }

                  guard let variantId = variantLoadable.value?.id else {
                    viewStore.send(.didRequestLoadingPendingContent(.group(groupId)))
                    return
                  }

                  guard let pagingId = pageLoadable.value?.id else {
                    viewStore.send(.didRequestLoadingPendingContent(.variant(groupId, variantId)))
                    return
                  }

                  viewStore.send(.didRequestLoadingPendingContent(.page(groupId, variantId, pagingId)))
                }
              }
            }
            .frame(maxWidth: .infinity)
            .shimmering(active: !items.didFinish)
            .disabled(!items.didFinish)
          }
        }
        .animation(.easeInOut, value: items.didFinish)
        .animation(.easeInOut, value: _selectedGroupId)
        .animation(.easeInOut, value: _selectedVariantId)
        .animation(.easeInOut, value: _selectedPagingId)
        .sheet(
          store: store.scope(
            state: \.$downloadSelection,
            action: \.downloadSelection
          ),
          state: /DownloadSelection.State.selection,
          action: DownloadSelection.Action.selection
        ) { store in
          VStack {
            Capsule()
              .frame(width: 48, height: 4)
              .foregroundColor(.gray.opacity(0.26))
              .padding(.top, 8)
            
            WithViewStore(store, observe: \.`self`) { viewStore in
              List {
                LoadableView(loadable: viewStore.state.sources) { sources in
                  Section("Sources") {
                    ForEach(sources) { source in
                      Button {
                        store.send(.selectSource(source))
                      } label: {
                        HStack(alignment: .center) {
                          Text(source.displayName)
                          Spacer()
                          if (viewStore.state.selectedSource?.id == source.id) { Image(systemName: "checkmark").foregroundColor(.blue) }
                        }
                      }
                      .foregroundColor(Color.primary)
                    }
                  }
                  
                  if let selectedSource = viewStore.state.selectedSource {
                    Section("Servers") {
                      ForEach(sources.first(where: { $0.id.rawValue == selectedSource.id.rawValue })?.servers ?? []) { server in
                        Button {
                          store.send(.selectServer(server))
                        } label: {
                          HStack(alignment: .center) {
                            Text(server.displayName)
                            Spacer()
                            if (viewStore.state.selectedServer?.id == server.id) {
                              if case .loading = viewStore.state.serverResponse {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: Color.blue))
                              } else {
                                Image(systemName: "checkmark").foregroundColor(.blue)
                              }
                            }
                          }
                        }
                        .foregroundColor(Color.primary)
                      }
                    }
                  }
                }
                
                LoadableView(loadable: viewStore.serverResponse) { serverResponse in
                  Section("Quality") {
                    ForEach(serverResponse.links) { link in
                      Button {
                        store.send(.selectQuality(link))
                      } label: {
                        HStack(alignment: .center) {
                          Text(link.quality.description)
                          Spacer()
                          if (viewStore.state.selectedQuality?.id == link.id) { Image(systemName: "checkmark").foregroundColor(.blue) }
                        }
                      }
                      .foregroundColor(Color.primary)
                    }
                  }
                  Section("Subtitles") {
                    ForEach(serverResponse.subtitles) { subtitle in
                      Button {
                        store.send(.selectSubtitle(subtitle))
                      } label: {
                      HStack(alignment: .center) {
                          Text(subtitle.name)
                          Spacer()
                          if (viewStore.state.selectedSubtitle?.id == subtitle.id) { Image(systemName: "checkmark").foregroundColor(.blue) }
                        }
                      }
                      .foregroundColor(Color.primary)
                    }
                  }
                  if let selectedQuality = viewStore.state.selectedQuality {
                    Button {
                      store.send(.download(viewStore.selectedSource!, viewStore.selectedServer!, selectedQuality, viewStore.selectedSubtitle != nil ? [viewStore.selectedSubtitle!] : [], serverResponse.skipTimes, viewStore.state.episode, serverResponse.headers))
                    } label: {
                      Text("Download")
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                  }
                }
              }
              .animation(.easeInOut, value: viewStore.state.selectedSource)
              .animation(.easeInOut, value: viewStore.serverResponse.value)
              .animation(.easeInOut, value: viewStore.state.selectedQuality)
            }
          }
          .onAppear {
            store.send(.didAppear)
          }
        }
      }
      .onChange(of: _selectedGroupId) { _ in
        _selectedVariantId = nil
        _selectedPagingId = nil
      }
      .onChange(of: _selectedVariantId) { _ in
        _selectedPagingId = nil
      }
      .onAppear {
        store.send(.didAppear)
      }
    }
  }
}

extension ContentCore.View {
  static let placeholderItems = [
    Playlist.Item(
      id: "/1",
      title: "Placeholder",
      description: "Placeholder",
      number: 1,
      timestamp: "May 12, 2023",
      tags: []
    ),
    Playlist.Item(
      id: "/2",
      title: "Placeholder",
      description: "Placeholder",
      number: 2,
      timestamp: "May 12, 2023",
      tags: []
    ),
    Playlist.Item(
      id: "/3",
      title: "Placeholder",
      description: "Placeholder",
      number: 3,
      timestamp: "May 12, 2023",
      tags: []
    )
  ]
}

// MARK: - HeaderWithContent

@MainActor
private struct HeaderWithContent<Label: View, Content: View>: View {
  let label: () -> Label
  let content: () -> Content

  @MainActor var body: some View {
    LazyVStack(alignment: .leading, spacing: 12) {
      label()
        .font(.title3.bold())
      content()
    }
    .frame(maxWidth: .infinity)
  }

  @MainActor
  init(
    @ViewBuilder label: @escaping () -> Label,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.label = label
    self.content = content
  }

  @MainActor
  init(
    title: String = "",
    @ViewBuilder content: @escaping () -> Content
  ) where Label == Text {
    self.init {
      Text(title)
    } content: {
      content()
    }
  }
}

// TODO: Move these to translatable content

extension Playlist.PlaylistType {
  fileprivate var multiGroupsDefaultTitle: String {
    switch self {
    case .video:
      "Season %@"
    case .image, .text:
      "Volume %@"
    }
  }

  fileprivate var oneGroupDefaultTitle: String {
    switch self {
    case .video:
      "Episodes"
    case .image, .text:
      "Chapters"
    }
  }

  fileprivate var itemTypeWithNumber: String {
    switch self {
    case .video:
      "Episode %@"
    case .image, .text:
      "Chanpter %@"
    }
  }
}

// MARK: - ContentListingView_Previews
