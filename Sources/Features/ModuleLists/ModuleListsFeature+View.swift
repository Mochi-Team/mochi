//
//  ModuleListsFeature+View.swift
//
//
//  Created ErrorErrorError on 4/23/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import NukeUI
import SharedModels
import SwiftUI

// MARK: - ModuleListsFeature.View + View

extension ModuleListsFeature.View: View {
  @MainActor public var body: some View {
    WithViewStore(store, observe: \.repos) { viewStore in
      ScrollView(.vertical) {
        if viewStore.isEmpty {
          Spacer()
            .frame(height: 12)

          StatusView(
            title: "No Repos Added",
            description: "Make sure you add a repo in the Repos tab.",
            assetImage: "package.badge.questionmark.fill"
          )
        } else {
          VStack(spacing: 24) {
            ForEach(viewStore.state) { repo in
              repoSection(repo)
            }
          }
        }
      }
      .safeAreaInset(edge: .top) {
        VStack {
          Capsule()
            .frame(width: 48, height: 4)
            .foregroundColor(.gray.opacity(0.26))
            .padding(.top, 8)

          HStack {
            Text(localizable: "Module Selection")
              .font(.title3.bold())
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal)

            Button {
              store.send(.view(.didTapToDismiss))
            } label: {
              Image(systemName: "xmark")
            }
            .buttonStyle(.materialToolbarItem)
            .padding(.horizontal)
          }

          Divider()
        }
        .background(.thinMaterial)
      }
      .frame(maxWidth: .infinity)
      .task { await viewStore.send(.onTask).finish() }
    }
    .frame(maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
  }
}

extension ModuleListsFeature.View {
  @MainActor
  func repoSection(_ repo: Repo) -> some View {
    VStack(spacing: 12) {
      HStack {
        LazyImage(url: repo.iconURL) { state in
          if let image = state.image {
            image.resizable()
              .aspectRatio(contentMode: .fit)
          } else if state.error != nil {
            EmptyView()
          } else {
            Color.gray
          }
        }
        .squircle()

        VStack(alignment: .leading) {
          Text(repo.name)
            .font(.headline)

          Text(repo.author)
            .font(.subheadline)
            .opacity(0.6)

          Spacer()
            .frame(height: 4)
            .fixedSize(horizontal: false, vertical: true)

          Text(repo.id.displayIdentifier)
            .font(.footnote)
            .foregroundColor(.gray.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .fixedSize(horizontal: true, vertical: false)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal)

      Divider()
        .padding(.horizontal)

      VStack(spacing: 8) {
        if repo.modules.isEmpty {
          StatusView(
            title: "No Modules Added",
            description: "No modules have been added for this repo.",
            assetImage: "package.badge.questionmark.fill"
          )
        } else {
          ForEach(repo.modules.sorted { $0.name < $1.name }, id: \.id) { module in
            Button {
              store.send(.view(.didSelectModule(repo.id, module.id)))
            } label: {
              moduleRow(repo, module)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .disabled(!module.isValid)
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  @MainActor
  func moduleRow(
    _ repo: Repo,
    _ module: Module
  ) -> some View {
    HStack {
      LazyImage(url: module.manifest.iconURL(repoURL: repo.remoteURL)) { state in
        if let image = state.image {
          image.resizable()
            .scaledToFit()
        } else if state.error != nil {
          EmptyView()
        } else {
          Color.gray // Acts as a placeholder
        }
      }
      .frame(width: 42, height: 42)
      .squircle()

      VStack(alignment: .leading, spacing: 4) {
        Text(module.name)
          .font(.body.weight(.medium))

        Text("v\(module.version.description)")
          .font(.footnote.weight(.medium))
          .foregroundColor(.gray)
      }

      Spacer()

      if !module.isValid {
        Image(systemName: "exclamationmark.triangle.fill")
          .foregroundColor(.red)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 8)
  }
}

extension View {
  @MainActor
  public func moduleListsSheet(
    _ store: Store<PresentationState<ModuleListsFeature.State>, PresentationAction<ModuleListsFeature.Action>>
  ) -> some View {
    sheet(
      store: store,
      content: ModuleListsFeature.View.init
    )
  }
}

import Styling

// MARK: - ModuleListsFeatureView_Previews

#Preview {
  ModuleListsFeature.View(
    store: .init(
      initialState: .init(
        repos: [
          Repo(
            remoteURL: .init(string: "/").unsafelyUnwrapped,
            manifest: .init(
              name: "Local Repo",
              author: "errorerrorerror",
              description: "This is a local repo"
            ),
            modules: [
              .init(
                directory: URL(string: "/").unsafelyUnwrapped,
                installDate: .init(),
                manifest: .init()
              )
            ]
          )
        ],
        selected: nil
      ),
      reducer: { EmptyReducer() }
    )
  )
  .previewLayout(.sizeThatFits)
}

extension Module {
  fileprivate var isValid: Bool {
    @Dependency(\.fileClient) var fileClient
    if let file = try? fileClient.retrieveModuleDirectory(mainJSFile) {
      return fileClient.fileExists(file.path)
    } else {
      return false
    }
  }
}
