//
//  ReposFeature+View.swift
//
//
//  Created ErrorErrorError on 4/18/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import NukeUI
import RepoClient
import SharedModels
import Styling
import SwiftUI
import ViewComponents

// MARK: - ReposFeature.View + View

extension ReposFeature.View: View {
  @MainActor public var body: some View {
    NavStack(
      store.scope(
        state: \.path,
        action: \.internal.path
      )
    ) {
      ScrollView(.vertical, showsIndicators: false) {
        LazyVStack(spacing: 0) {
          #if os(iOS)
          repoUrlTextInput
            .padding(.horizontal)
          #endif

          WithViewStore(store, observe: \.repos) { viewStore in
            Spacer()
              .frame(height: 24)

            Text("\(viewStore.count) Installed Repos")
              .font(.footnote.weight(.medium))
              .foregroundColor(.gray)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal)

            Spacer()
              .frame(height: 8)

            ZStack {
              if !viewStore.isEmpty {
                ForEach(viewStore.state) { repo in
                  repoRow(repo)
                    .padding(.horizontal)
                    .background(theme.backgroundColor)
                    .contentShape(Rectangle())
                    .onTapGesture {
                      self.store.send(.view(.didTapRepo(repo.id)))
                    }
                    .contextMenu {
                      Button {
                        self.store.send(.view(.didTapCopyRepoURL(repo.id)))
                      } label: {
                        Label("Copy Repo URL", systemImage: "doc.on.clipboard")
                      }
                      .buttonStyle(.plain)

                      Divider()

                      Button(role: .destructive) {
                        self.store.send(.view(.didTapDeleteRepo(repo.id)))
                      } label: {
                        Label("Delete Repo", systemImage: "trash.fill")
                          .foregroundColor(.red)
                      }
                      .buttonStyle(.plain)
                    }

                  if viewStore.last?.id != repo.id {
                    Divider()
                      .padding(.horizontal)
                  }
                }
              } else {
                StatusView(
                  title: "No Repos Added",
                  description: "Add repos to view and install modules.",
                  image: .asset("package.badge.plus.fill", hasBadge: true)
                )
              }
            }
            .animation(.easeInOut, value: viewStore.state)
          }
        }
      }
      .initialTask {
        _ = await MainActor.run {
          store.send(.view(.onTask))
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .navigationTitle("Repos")
      #if os(iOS)
      .navigationBarTitleDisplayMode(.large)
      #elseif os(macOS)
      .toolbar {
        ToolbarItem(placement: .automatic) {
          repoUrlTextInput
        }
      }
      #endif
    } destination: { store in
      RepoPackagesFeature.View(store: store)
    }
  }
}

extension ReposFeature.View {
  struct RepoURLInputViewState: Equatable, @unchecked Sendable {
    @BindingViewState var url: String
    let searchedRepo: Loadable<RepoClient.RepoPayload>
    let canAddRepo: Bool

    init(_ state: BindingViewStore<ReposFeature.State>) {
      self._url = state.$url
      self.searchedRepo = state.searchedRepo
      if let value = state.searchedRepo.value {
        self.canAddRepo = !state.repos.ids.contains(.init(value.remoteURL))
      } else {
        self.canAddRepo = false
      }
    }
  }
}

extension ReposFeature.View {
  @MainActor
  func repoRow(_ repo: Repo) -> some View {
    HStack(alignment: .top, spacing: 16) {
      LazyImage(url: repo.iconURL) { state in
        Group {
          if let image = state.image {
            image
              .resizable()
              .aspectRatio(contentMode: .fit)
          } else {
            Image(systemName: "questionmark.square.dashed")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .font(.body.weight(.light))
          }
        }
        .frame(width: 38, height: 38)
      }
      .squircle()

      VStack(alignment: .leading, spacing: 2) {
        Text(repo.name)
          .font(.callout.weight(.medium))

        HStack(spacing: 0) {
          Text(repo.id.displayIdentifier)
            .font(.footnote)
        }
        .lineLimit(1)
        .foregroundColor(.gray)
      }

      Spacer()
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 14)
  }
}

// MARK: - ReposFeatureView_Previews

#Preview {
  ReposFeature.View(
    store: .init(
      initialState: .init(),
      reducer: { EmptyReducer() }
    )
  )
}
