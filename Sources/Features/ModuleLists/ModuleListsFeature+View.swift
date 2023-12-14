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
      VStack {
        if viewStore.isEmpty {
          VStack(spacing: 12) {
            Text("No modules installed")
              .font(.headline.bold())

            Text("Make sure you have modules installed in the repos tab.")
              .font(.callout)
              .multilineTextAlignment(.center)
              .font(.body)
          }
          .padding()
        } else {
          ScrollView(.vertical) {
            VStack(spacing: 24) {
              ForEach(viewStore.state) { repo in
                repoSection(repo)
              }
            }
            .padding()
          }
        }
      }
      .frame(maxWidth: .infinity)
      .task {
        await viewStore.send(.onTask).finish()
      }
    }
    .frame(maxWidth: .infinity, minHeight: 300)
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
            .font(.title3.bold())

          Text(repo.author)
            .font(.subheadline.bold())
            .opacity(0.8)

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

      Divider()

      VStack(spacing: 8) {
        if repo.modules.isEmpty {
          VStack(spacing: 8) {
            Text("No modules installed")
              .font(.headline.bold())

            Text("This repo does not contained any installed modules.")
              .font(.callout)
              .multilineTextAlignment(.center)
          }
          .padding(12)
          .frame(maxWidth: .infinity)
          .background(Color.gray.opacity(0.16).cornerRadius(12))
        } else {
          ForEach(repo.modules.sorted { $0.name < $1.name }, id: \.id) { module in
            Button {
              store.send(.view(.didSelectModule(repo.id, module.id)))
            } label: {
              moduleRow(repo, module.manifest)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  @MainActor
  func moduleRow(
    _ repo: Repo,
    _ module: Module.Manifest
  ) -> some View {
    HStack {
      LazyImage(url: module.iconURL(repoURL: repo.remoteURL)) { state in
        if let image = state.image {
          image.resizable()
            .aspectRatio(contentMode: .fit)
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

        // Text(module.id.rawValue)
        //   .font(.footnote.weight(.medium))
        //   .foregroundColor(.gray)

        Text("v\(module.version.description)")
          .font(.footnote.weight(.medium))
          .foregroundColor(.gray)
      }

      Spacer()
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
    #if os(iOS)
    sheet(
      store: store,
      detents: [.medium(), .large()],
      content: ModuleListsFeature.View.init
    )
    #else
    sheet(
      store: store,
      content: ModuleListsFeature.View.init
    )
    #endif
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
            )
          )
        ],
        selected: nil
      ),
      reducer: { EmptyReducer() }
    )
  )
  .previewLayout(.sizeThatFits)
}
