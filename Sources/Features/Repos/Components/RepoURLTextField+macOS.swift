//
//  RepoURLTextField+macOS.swift
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

#if os(macOS)
extension ReposFeature.View {
  @MainActor var repoUrlTextInput: some View {
    WithViewStore(store, observe: RepoURLInputViewState.init) { viewStore in
      HStack(spacing: 8) {
        Group {
          switch viewStore.searchedRepo {
          case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
              .resizable()
              .scaledToFit()
              .foregroundColor(.red)
          case .loading:
            ProgressView()
              .fixedSize(horizontal: true, vertical: true)
              .controlSize(.small)
          case let .loaded(repo):
            LazyImage(url: repo.iconURL) { state in
              if let image = state.image {
                image
                  .resizable()
                  .scaledToFit()
              } else {
                Image(systemName: "magnifyingglass")
                  .resizable()
                  .scaledToFit()
              }
            }
          default:
            Image(systemName: "magnifyingglass")
              .resizable()
              .scaledToFit()
          }
        }
        .foregroundColor(.gray)
        .aspectRatio(contentMode: .fit)
        .frame(maxHeight: .infinity)
        .frame(width: 12)

        TextField(
          "Enter or paste a repo url...",
          text: viewStore.$url
            .removeDuplicates()
        )
        .textFieldStyle(.plain)
        .autocorrectionDisabled(true)
        .font(.callout)
        .frame(maxHeight: .infinity)

        Group {
          if let repo = viewStore.searchedRepo.value, viewStore.canAddRepo {
            Button {
              viewStore.send(.didTapAddNewRepo(repo))
            } label: {
              Image(systemName: "plus.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .transition(.scale.combined(with: .opacity))
          } else if viewStore.searchedRepo.value != nil {
            Image(systemName: "checkmark.circle.fill")
              .resizable()
              .scaledToFit()
              .foregroundColor(.green)
          } else {
            Color.clear
          }
        }
        .aspectRatio(contentMode: .fit)
        .frame(maxHeight: .infinity)
        .fixedSize(horizontal: true, vertical: true)
        .frame(width: 12)
      }
      .frame(height: 12)
      .padding(.horizontal, 8)
      .padding(.vertical, 8)
      .background(
        RoundedRectangle(cornerRadius: 8)
          .style(withStroke: .gray.opacity(0.28), lineWidth: 0.5, fill: .clear)
      )
      .animation(.easeInOut(duration: 0.2), value: viewStore.searchedRepo)
      .animation(.easeInOut(duration: 0.2), value: viewStore.url.count)
      .frame(width: 220)
    }
  }
}
#endif
