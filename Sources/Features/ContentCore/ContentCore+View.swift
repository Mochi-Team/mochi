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

// MARK: - ContentListingView

public extension ContentCore {
    @MainActor
    struct View: FeatureView {
        public let store: StoreOf<ContentCore>

        @MainActor
        public init(store: StoreOf<ContentCore>) {
            self.store = store
        }

        @Environment(\.theme)
        var theme

        @SwiftUI.State
        private var selectedGroupId: Playlist.Group.ID?

        @SwiftUI.State
        private var selectedVariantId: Playlist.Group.Variant.ID?

        @SwiftUI.State
        private var selectedPagingId: PagingID?

        private static let placeholderItems = [
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

        @MainActor
        public var body: some SwiftUI.View {
            WithViewStore(store, observe: \.`self`) { viewStore in
                LoadableView(loadable: viewStore.state) { groups in
                    content(groups)
                } failedView: { _ in
                    content([])
                } waitingView: {
                    content([])
                }
                .shimmering(active: !viewStore.didFinish)
                .disabled(!viewStore.didFinish)
                .onChange(of: selectedGroupId) { _ in
                    selectedVariantId = nil
                    selectedPagingId = nil
                }
                .onChange(of: selectedVariantId) { _ in
                    selectedPagingId = nil
                }
            }
        }

        @MainActor
        @ViewBuilder
        private func content(_ groups: [Playlist.Group]) -> some SwiftUI.View {
            let defaultSelectedGroupId = selectedGroupId ?? groups.first?.id
            let group = defaultSelectedGroupId.flatMap { groups[id: $0] }
            let groupLoadable = groups.group(id: defaultSelectedGroupId)
            
            let defaultSelectedVariantId = selectedVariantId ?? group?.variants.value?.first?.id
            let variant = defaultSelectedVariantId.flatMap { group?.variants.value?[id: $0] }
            let variantLoadable = groupLoadable.flatMap { $0.variant(variantId: defaultSelectedVariantId) }
            
            let defaultSelectedPagingId = selectedPagingId ?? variant?.pagings.value?.first?.id
            let page = defaultSelectedPagingId.flatMap { variant?.pagings.value?[id: $0] }
            let pageLoadable = variantLoadable.flatMap { $0.page(pageId: defaultSelectedPagingId) }
            
            let hasMultipleGroups = groups.count > 1
            
            HeaderWithContent {
                VStack {
                    HStack(alignment: .center) {
                        /// Groups
                        Menu {
                            if hasMultipleGroups {
                                ForEach(groups, id: \.id) { group in
                                    Button {
                                        selectedGroupId = group.id
                                        //                                    store.send(.view(.didTapContent(.group(group.id))))
                                    } label: {
                                        Text(group.altTitle ?? "Season \(group.number.withoutTrailingZeroes)")
                                    }
                                }
                            }
                        } label: {
                            if let group, hasMultipleGroups {
                                HStack {
                                    Text(group.altTitle ?? "Season \(group.number.withoutTrailingZeroes)")
                                    Image(systemName: "chevron.compact.down")
                                    Spacer()
                                }
                            } else if let group {
                                Text(group.altTitle ?? "Episodes")
                            } else {
                                Text("Episodes")
                            }
                        }
                        .animation(.easeInOut, value: defaultSelectedGroupId)
                        
                        Spacer()
                        
                        // TODO: Add option to show/hide pagings with infinie scroll
                        /// Pagings
                        Menu {
                            if let pagings = variant?.pagings.value {
                                ForEach(Array(zip(pagings.indices, pagings)), id: \.1.id) { index, paging in
                                    Button {
                                        selectedPagingId = paging.id
                                        if let groupId = defaultSelectedGroupId, let variantId = defaultSelectedVariantId {
                                            //                                        store.send(.view(.didTapContent(.page(groupId, variantId, paging.id))))
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
                            
                            if let page, let index = variant?.pagings.value?.firstIndex(where: \.id == page.id) {
                                textView(page.title ?? "Page \(index + 1)")
                            } else {
                                textView("Not Selected")
                            }
                        }
                        .font(.footnote.weight(.semibold))
                        .shimmering(active: !variantLoadable.didFinish)
                        .animation(.easeInOut, value: defaultSelectedPagingId)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // TODO: Allow variations to also be a menu
                    ScrollView(.horizontal) {
                        HStack(spacing: 6) {
                            if let variant {
                                ChipView(text: variant.title)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                            }
                            
                            if let variants = group?.variants.value {
                                ForEach(variants, id: \.id) { variant in
                                    if variant.id != defaultSelectedVariantId {
                                        ChipView(text: variant.title)
                                            .onTapGesture {
                                                if let defaultSelectedGroupId {
                                                    selectedVariantId = variant.id
                                                    //                                                store.send(.view(.didTapContent(.variant(defaultSelectedGroupId, variant.id))))
                                                }
                                            }
                                    }
                                }
                            }
                        }
                    }
                    .font(.footnote.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .shimmering(active: !groupLoadable.didFinish)
                    .animation(.easeInOut, value: defaultSelectedVariantId)
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
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 12) {
                                ForEach(items.value ?? Self.placeholderItems, id: \.id) { item in
                                    VStack(alignment: .leading, spacing: 0) {
                                        FillAspectImage(url: item.thumbnail)
                                            .aspectRatio(16 / 9, contentMode: .fit)
                                            .cornerRadius(12)
                                        
                                        Spacer()
                                            .frame(height: 8)
                                        
                                        Text("Episode \(item.number.withoutTrailingZeroes)")
                                            .font(.footnote.weight(.semibold))
                                            .foregroundColor(.init(white: 0.4))
                                        
                                        Spacer()
                                            .frame(height: 4)
                                        
                                        Text(item.title ?? "Episode \(item.number.withoutTrailingZeroes)")
                                            .font(.body.weight(.semibold))
                                    }
                                    .frame(width: 228)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if let groupId = defaultSelectedGroupId,
                                           let variantId = defaultSelectedVariantId,
                                           let pageId = defaultSelectedPagingId {
                                            //                                        store.send(.view(.didTapVideoItem(groupId, variantId, pageId, item.id)))
                                        }
                                    }
                                }
                                .frame(maxHeight: .infinity, alignment: .top)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity)
                        .shimmering(active: !items.didFinish)
                        .disabled(!items.didFinish)
                    }
                }
                .animation(.easeInOut, value: defaultSelectedGroupId)
                .animation(.easeInOut, value: defaultSelectedVariantId)
                .animation(.easeInOut, value: defaultSelectedPagingId)
            }
        }
    }
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
                .padding(.horizontal)
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

// MARK: - ContentListingView_Previews

#Preview {
    ContentCore.View(
        store: .init(
            initialState: .pending,
            reducer: { EmptyReducer() }
        )
    )
}
