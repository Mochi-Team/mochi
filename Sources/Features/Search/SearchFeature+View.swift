//
//  SearchFeature+View.swift
//
//
//  Created ErrorErrorError on 4/18/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import ModuleLists
import NukeUI
import OrderedCollections
import PlaylistDetails
import SharedModels
import Styling
import SwiftUI
import ViewComponents

// MARK: - SearchFeature.View + View

extension SearchFeature.View: View {
  @MainActor public var body: some View {
    ScrollViewTracker(.vertical) { offset in
      showStatusBarBackground = offset.y <= -2.9 // FIXME: SafeAreaInset affects the offset of this
    } content: {
      WithViewStore(store, observe: \.searchResult) { viewStore in
        LoadableView(loadable: viewStore.state) { searchResult in
          if searchResult.items.isEmpty {
            WithViewStore(store, observe: \.query) { queryStore in
              StatusView(
                title: "No Results",
                description: "for \"\(queryStore.state)\"",
                assetImage: "search"
              )
            }
          } else {
            LazyVGrid(
              columns: [.init(.adaptive(minimum: 120), alignment: .top)],
              alignment: .leading
            ) {
              ForEach(searchResult.items) { item in
                VStack(alignment: .leading) {
                  FillAspectImage(url: item.posterImage)
                    .aspectRatio(2 / 3, contentMode: .fit)
                    .cornerRadius(12)

                  Text(item.title ?? "Title Unavailable")
                    .font(.footnote)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                  viewStore.send(.didTapPlaylist(item))
                }
              }
            }
            .padding(.horizontal)

            if let nextPage = searchResult.nextPage {
              LoadableView(loadable: nextPage) { nextPageId in
                LazyView {
                  Spacer()
                    .frame(height: 1)
                    .onAppear {
                      store.send(.view(.didShowNextPageIndicator(nextPageId)))
                    }
                }
              } failedView: { _ in
                Button {
                  // TODO: Allow refetch when paging failed
                } label: {
                  Image(systemName: "arrow.clockwise")
                    .font(.body)
                    .padding(4)
                }
                .contentShape(Rectangle())
              } waitingView: {
                ProgressView()
                  .padding(.vertical, 8)
              }
            }
          }
        } failedView: { _ in
          // TODO: Make error more explicit
          StatusView(
            title: .init(localizable: "Search Failed"),
            description: .init(localizable: "Failed to retrieve items."),
            image: .asset("search.trianglebadge.exclamationmark"),
            foregroundColor: .red
          )
        } loadingView: {
          WithViewStore(store, observe: \.query) { queryStore in
            StatusView(
              title: "Searching...",
              description: "for \"\(queryStore.state)\"",
              assetImage: "search.badge.clock"
            )
          }
        } pendingView: {
          StatusView(
            title: .init(localizable: "Search Empty"),
            description: "Type to start searching.",
            systemImage: "magnifyingglass"
          )
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .safeAreaInset(edge: .top, spacing: 0) { filters }
    .task { store.send(.view(.didAppear)) }
    #if os(iOS)
      .navigationTitle("")
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarBackButtonHidden()
      .toolbar {
        ToolbarItem(placement: .navigation) {
          SwiftUI.Button {
            store.send(.view(.didTapBackButton))
          } label: {
            Image(systemName: "chevron.left")
          }
          .buttonStyle(.materialToolbarItem)
        }

        ToolbarItem(placement: .principal) {
          WithViewStore(store, observe: \.`self`) { viewStore in
            HStack(spacing: 8) {
              Image(systemName: "magnifyingglass")
                .font(.caption)
                .foregroundColor(.gray)

              TextField("Search...", text: viewStore.$query.removeDuplicates())
                .textFieldStyle(.plain)
                .frame(maxWidth: .infinity)

              Button {
                viewStore.send(.didTapClearQuery)
              } label: {
                Image(systemName: "xmark.circle.fill")
                  .font(.caption)
                  .foregroundColor(.gray)
              }
              .opacity(viewStore.query.isEmpty ? 0 : 1.0)
              .animation(.easeInOut, value: viewStore.query.isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background {
              RoundedRectangle(cornerRadius: 12, style: .continuous)
                .style(
                  withStroke: Color.gray.opacity(0.16),
                  fill: .thickMaterial
                )
            }
            .frame(maxHeight: .infinity)
            .padding(.leading, 8)
            .fixedSize(horizontal: false, vertical: true)
          }
        }
      }
    #elseif os(macOS)
      .navigationTitle("Search")
      .toolbar {
        ToolbarItem(placement: .automatic) {
          WithViewStore(store, observe: \.`self`) { viewStore in
            TextField("Search...", text: viewStore.$query.removeDuplicates())
              .textFieldStyle(.roundedBorder)
              .frame(minWidth: 200)
          }
        }
      }
    #endif
  }
}

extension SearchFeature.View {
  private struct FilterView: View {
    @Environment(\.theme) var theme

    @Environment(\.colorScheme) var scheme

    let filter: SearchFilter
    let selectedOptions: [SearchFilter.Option]
    let tappedFilterOption: (SearchFilter.Option) -> Void

    var body: some View {
      Menu {
        ForEach(filter.options) { option in
          Button {
            tappedFilterOption(option)
          } label: {
            if selectedOptions[id: option.id] != nil {
              Label(option.displayName.capitalized, systemImage: "checkmark")
            } else {
              Text(option.displayName.capitalized)
            }
          }
        }
      } label: {
        HStack {
          if let option = selectedOptions.first, selectedOptions.count > 1 {
            Text("\(filter.displayName.capitalized): \(option.displayName.capitalized) +\(selectedOptions.count - 1)")
          } else if let option = selectedOptions.first {
            Text("\(filter.displayName.capitalized): \(option.displayName.capitalized)")
          } else {
            Text(filter.displayName.capitalized)
          }

          Image(systemName: "chevron.up.chevron.down")
            .font(.footnote.weight(.semibold))
        }
        .foregroundColor(selectedOptions.isEmpty ? nil : .white)
        .lineLimit(1)
        .font(.footnote)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule().style(
          withStroke: .gray.opacity(0.2),
          fill: selectedOptions.isEmpty ? buttonBackgroundColor : selectedColor
        ))
      }
      .buttonStyle(.plain)
    }

    var selectedColor: Color { Theme.pastelGreen }
    var buttonBackgroundColor: Color { scheme == .dark ? .init(white: 0.2) : .init(white: 0.94) }
  }

  private struct FiltersState: Equatable {
    let isThereFilters: Bool
    let selectedFilters: [SearchFilter]
    let sortedAllFilters: [SearchFilter]

    init(_ state: SearchFeature.State) {
      self.isThereFilters = !state.allFilters.isEmpty
      self.selectedFilters = state.selectedFilters
      var sorted: [SearchFilter] = []

      for selected in state.selectedFilters {
        if let filter = state.allFilters.first(where: \.id == selected.id) {
          sorted.append(filter)
        }
      }

      for filter in state.allFilters where !sorted.contains(where: \.id == filter.id) {
        sorted.append(filter)
      }

      self.sortedAllFilters = sorted
    }
  }

  var filters: some View {
    WithViewStore(store, observe: FiltersState.init) { viewStore in
      Group {
        if viewStore.isThereFilters {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
              if !viewStore.selectedFilters.isEmpty {
                Menu {
                  Section {
                    Button(role: .destructive) {
                      viewStore.send(.didTapClearFilters)
                    } label: {
                      Text("Clear all filters")
                        .foregroundColor(.red)
                    }
                  } header: {
                    Text("\(viewStore.selectedFilters.count) filters applied")
                  }
                } label: {
                  HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal.decrease")
                    Text(viewStore.selectedFilters.count.description)
                  }
                  .font(.footnote)
                  .padding(8)
                  .foregroundColor(.white)
                  .background(
                    Capsule()
                      .style(
                        withStroke: .gray.opacity(0.2),
                        fill: Theme.pastelGreen
                      )
                  )
                }
                .buttonStyle(.plain)
                .frame(maxHeight: .infinity)
              }

              ForEach(viewStore.sortedAllFilters) { filter in
                FilterView(
                  filter: filter,
                  selectedOptions: viewStore.selectedFilters[id: filter.id]?.options ?? []
                ) { option in
                  viewStore.send(.didTapFilter(filter, option))
                }
                .frame(maxHeight: .infinity)
              }
            }
            .frame(maxHeight: .infinity)
            .padding(.horizontal)
          }
          .fixedSize(horizontal: false, vertical: true)
          .frame(maxWidth: .infinity)
          .animation(.easeInOut(duration: 0.2), value: viewStore.selectedFilters.count)
          .padding(.vertical, 12)
        } else {
          Spacer()
            .frame(height: 24)
        }
      }
      .background {
        if showStatusBarBackground {
          Rectangle()
            .fill(.regularMaterial)
            .tint(theme.backgroundColor)
        } else {
          Rectangle()
            .fill(theme.backgroundColor)
        }
      }
      .animation(.easeInOut(duration: 0.3), value: viewStore.isThereFilters)
      .animation(.easeInOut(duration: 0.2), value: showStatusBarBackground)
    }
  }
}

// MARK: - SearchFeatureView_Previews

#Preview {
  NavigationView {
    SearchFeature.View(
      store: .init(
        initialState: .init(
          repoModuleId: Repo().id(.init(rawValue: "")),
          query: "demo",
          selectedFilters: .init([
            SearchFilter(
              id: .init("1"),
              displayName: "Filter",
              multiselect: true,
              required: false,
              options: [.init(id: .init("1"), displayName: "Option 1")]
            )
          ]),
          allFilters: .init([
            SearchFilter(
              id: .init("1"),
              displayName: "Filter",
              multiselect: true,
              required: false,
              options: [.init(id: .init("1"), displayName: "Option 1")]
            )
          ]),
          searchResult: .pending
        ),
        reducer: { EmptyReducer() }
      )
    )
  }
  .themeable()
}
