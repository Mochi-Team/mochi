//
//  RepoURLTextField+iOS.swift
//
//
//  Created by ErrorErrorError on 12/15/23.
//
//

import ComposableArchitecture
import Foundation
import NukeUI
import SwiftUI
import ViewComponents

#if os(iOS)
extension ReposFeature.View {
  @MainActor var repoUrlTextInput: some View {
    WithViewStore(store, observe: RepoURLInputViewState.init) { viewStore in
      VStack(spacing: 0) {
        HStack(spacing: 12) {
          Group {
            switch viewStore.searchedRepo {
            case .failed:
              Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            case .loading:
              ProgressView()
                .fixedSize(horizontal: true, vertical: true)
                .controlSize(.small)
            default:
              Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            }
          }

          TextField(
            "Enter or paste a repo url...",
            text: viewStore.$url
              .removeDuplicates()
          )
          .textFieldStyle(.plain)
          .autocorrectionDisabled(true)
          .textInputAutocapitalization(.never)
          .keyboardType(.URL)
          .font(.callout)
          .frame(maxWidth: .infinity)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .frame(maxHeight: .infinity)

        LoadableView(loadable: viewStore.searchedRepo) { repo in
          Divider()

          HStack(alignment: .center) {
            LazyImage(url: repo.iconURL) { state in
              if let image = state.image {
                image
              } else {
                EmptyView()
              }
            }

            VStack(alignment: .leading, spacing: 4) {
              Text(repo.name)
                .font(.callout)

              Text(repo.author)
                .font(.caption)
                .foregroundColor(.gray)
            }

            Spacer()

            if viewStore.canAddRepo {
              Button {
                viewStore.send(.didTapAddNewRepo(repo))
              } label: {
                Image(systemName: "plus.circle.fill")
                  .font(.system(size: 18).weight(.semibold))
                  .contentShape(Rectangle())
              }
              .buttonStyle(.plain)
              .transition(.scale.combined(with: .opacity))
            } else {
              Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18).weight(.semibold))
            }
          }
          .padding(.vertical, 12)
        }
        .padding(.horizontal)
      }
      .background(
        RoundedRectangle(cornerRadius: 12)
          .style(withStroke: .gray.opacity(0.16), fill: .gray.opacity(0.1))
      )
      .animation(.easeInOut(duration: 0.2), value: viewStore.searchedRepo)
      .animation(.easeInOut(duration: 0.2), value: viewStore.url.count)
      .fixedSize(horizontal: false, vertical: true)
    }
  }
}
#endif
