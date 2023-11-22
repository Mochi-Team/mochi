//
//  ContentCore+View.swift
//
//
//  Created by ErrorErrorError on 7/13/23.
//
//

import Architecture
import ComposableArchitecture
import SharedModels
import Styling
import SwiftUI
import ViewComponents

// MARK: - ContentCore+View

public extension ContentCore {
    @MainActor
    struct View: FeatureView {
        public let store: StoreOf<ContentCore>

        @ObservedObject
        private var viewStore: ViewStoreOf<ContentCore>
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

        @Environment(\.theme)
        var theme

        @SwiftUI.State
        private var _selectedGroupId: Playlist.Group.ID?

        @SwiftUI.State
        private var _selectedVariantId: Playlist.Group.Variant.ID?

        @SwiftUI.State
        private var _selectedPagingId: PagingID?

        private let selectedItemId: Playlist.Item.ID?

        private var groupLoadable: Loadable<Playlist.Group> {
            viewStore.groups.map { groups in _selectedGroupId.flatMap { groups[id: $0] } ?? groups.first }
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

        @MainActor
        public var body: some SwiftUI.View {
            HeaderWithContent {
                VStack {
                    HStack(alignment: .center) {
                        /// Groups
                        Menu {
                            if hasMultipleGroups {
                                ForEach(viewStore.groups.value ?? [], id: \.id) { group in
                                    Button {
                                        _selectedGroupId = group.id
                                        store.send(.view(.didTapContent(.group(group.id))))
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
                                    Text(selectedGroup.altTitle ?? .init(
                                        format: contentType.multiGroupsDefaultTitle,
                                        selectedGroup.number.withoutTrailingZeroes)
                                    )
                                    Image(systemName: "chevron.compact.down")
                                    Spacer()
                                }
                            } else {
                                Text(groupLoadable.value?.altTitle ?? contentType.oneGroupDefaultTitle)
                            }
                        }
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
                                            store.send(.view(.didTapContent(.page(groupId, variantId, paging.id))))
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

                            if let selectedPage = pageLoadable.value, let index = variantLoadable.value?.pagings.value?.firstIndex(where: \.id == selectedPage.id) {
                                textView(selectedPage.title ?? "Page \(index + 1)")
                            } else {
                                textView("Not Selected")
                            }
                        }
                        .font(.footnote.weight(.semibold))
                        .shimmering(active: !variantLoadable.didFinish)
                        .animation(.easeInOut, value: _selectedPagingId)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)

                    // TODO: Allow variations to also be a menu
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
                                                    store.send(.view(.didTapContent(.variant(groupId, variant.id))))
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
                .frame(maxWidth: .infinity)
                .foregroundColor(theme.textColor)
            } content: {
                let items = pageLoadable.flatMap(\.items)
                ZStack {
                    if items.error != nil {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.16))
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity)
                            .frame(height: 125)
                            .overlay {
                                Text("There was an error loading content.")
                                    .font(.callout.weight(.semibold))

                                Button {
//                                    viewStore.send(.view(.didTapRetry(items)))
                                } label: {
                                    Text("Retry")
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                    } else if items.didFinish, (items.value?.count ?? 0) == 0 {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.12))
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity)
                            .frame(height: 125)
                            .overlay {
                                Text("There is no content available.")
                                    .font(.callout.weight(.medium))
                            }
                    } else {
                        ScrollViewReader { proxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(alignment: .top, spacing: 12) {
                                    ForEach(items.value ?? Self.placeholderItems, id: \.id) { item in
                                        VStack(alignment: .leading, spacing: 0) {
                                            FillAspectImage(url: item.thumbnail ?? viewStore.playlist.posterImage)
                                                .aspectRatio(16 / 9, contentMode: .fit)
                                                .cornerRadius(12)

                                            Spacer()
                                                .frame(height: 8)

                                            Text(String(format: contentType.itemTypeWithNumber, item.number.withoutTrailingZeroes))
                                                .font(.footnote.weight(.semibold))
                                                .foregroundColor(.init(white: 0.4))

                                            Spacer()
                                                .frame(height: 4)

                                            Text(item.title ?? String(format: contentType.itemTypeWithNumber, item.number.withoutTrailingZeroes))
                                                .font(.body.weight(.semibold))
                                        }
                                        .frame(width: 228)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            if let groupId = groupLoadable.value?.id,
                                               let variantId = variantLoadable.value?.id,
                                               let pageId = pageLoadable.value?.id {
                                                store.send(.view(.didTapPlaylistItem(groupId, variantId, pageId, id: item.id)))
                                            }
                                        }
                                        .id(item.id)
                                    }
                                    .frame(maxHeight: .infinity, alignment: .top)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal)
                            }
                            .onAppear {
                                proxy.scrollTo(selectedItemId, anchor: .center)
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
            }
            .onChange(of: _selectedGroupId) { _ in
                _selectedVariantId = nil
                _selectedPagingId = nil
            }
            .onChange(of: _selectedVariantId) { _ in
                _selectedPagingId = nil
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

@MainActor
private struct HeaderWithContent<Label: View, Content: View>: View {
    let label: () -> Label
    let content: () -> Content

    @MainActor
    var body: some View {
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

private extension Playlist.PlaylistType {
    var multiGroupsDefaultTitle: String {
        switch self {
        case .video:
            "Season %@"
        case .image, .text:
            "Volume %@"
        }
    }

    var oneGroupDefaultTitle: String {
        switch self {
        case .video:
            "Episodes"
        case .image, .text:
            "Chapters"
        }
    }

    var itemTypeWithNumber: String {
        switch self {
        case .video:
            "Episode %@"
        case .image, .text:
            "Chanpter %@"
        }
    }
}

// MARK: - ContentListingView_Previews

#Preview {
    ContentCore.View(
        store: .init(
            initialState: .init(
                repoModuleId: Repo().id(.init("")),
                playlist: .empty
            ),
            reducer: { EmptyReducer() }
        )
    )
}
