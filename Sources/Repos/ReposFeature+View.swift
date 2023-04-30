//
//  ReposFeature+View.swift
//  
//
//  Created ErrorErrorError on 4/18/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import NukeUI
import SharedModels
import SwiftUI
import ViewComponents

extension ReposFeature.View: View {
    @MainActor
    public var body: some View {
        WithViewStore(store.viewAction, observe: \.repos) { viewStore in
            if viewStore.state.isEmpty {
                VStack(spacing: 0) {
                    topBar

                    Spacer()
                        .frame(height: 4)

                    repoUrlTextInput
                        .padding(.horizontal)

                    Spacer()

                    VStack {
                        Text("No repos installed")
                            .font(.callout)
                    }

                    Spacer()
                }
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        Spacer()
                            .frame(height: topBarSize.size.height)

                        Spacer()
                            .frame(height: 4)

                        repoUrlTextInput

                        Spacer()
                            .frame(height: 24)

                        Text("Installed Repos")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(viewStore.state) { repo in
                            repoRow(repo, repo.id == viewStore.state.last?.id)
                            if repo.id != viewStore.state.last?.id {
                                Divider()
                            }
                        }

                        Spacer()
                            .frame(maxWidth: .infinity)
                            .frame(height: tabNavigationSize.height)
                    }
                    .padding(.horizontal)
                }
                .overlay(topBar, alignment: .top)
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
}

extension ReposFeature.View {
    @MainActor
    var repoUrlTextInput: some View {
        WithViewStore(
            store.viewAction,
            observe: \.`self`
        ) { viewStore in
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Group {
                        if let loadable = viewStore.urlRepoState {
                            LoadableView(loadable: loadable) { _ in
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } failedView: { _ in
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                            } loadingView: {
                                ProgressView()
                                    .fixedSize(horizontal: true, vertical: true)
                            }
                        } else {
                            Image(systemName: "magnifyingglass")
                        }
                    }

                    TextField(
                        "Enter or paste a repo url...",
                        text: viewStore.binding(\.$urlTextInput)
                            .removeDuplicates()
                    )
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.never)
                    .textContentType(UITextContentType.URL)
                    .keyboardType(.asciiCapable)
                    .autocorrectionDisabled(true)
                    .font(.callout)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())

                    Spacer()
                }

                if let loadable = viewStore.urlRepoState {
                    LoadableView(loadable: loadable) { repoState in
                        Divider()

                        HStack(alignment: .center) {
                            LazyImage(url: repoState.repo.icon) { state in
                                if let image = state.image {
                                    image
                                } else {
                                    EmptyView()
                                }
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(repoState.repo.name)
                                    .font(.callout)

                                Text(repoState.repo.author)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Button {
                                viewStore.send(.addNewRepo(repoState.repo))
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18).weight(.semibold))
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .transition(.opacity.combined(with: .scale))
                        }
                        .padding(.vertical, 10)
                    } failedView: { _ in

                    }
                }
            }
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .foregroundColor(.gray.opacity(0.1))
            )
            .animation(.easeInOut(duration: 0.2), value: viewStore.urlRepoState)
        }
    }
}

extension ReposFeature.View {
    @MainActor
    func repoRow(_ repo: Repo, _ lastItem: Bool) -> some View {
        HStack(spacing: 16) {
            LazyImage(url: repo.icon) { state in
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
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(repo.name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)

                Text(repo.author)
                    .font(.footnote)
                    .lineLimit(1)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
}

extension ReposFeature.View {
    @MainActor
    var topBar: some View {
        HStack(alignment: .bottom, spacing: 12) {
            Text("Repos")
                .font(.largeTitle.bold())

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .readSize { size in
            topBarSize = size
        }
        .background(Color(uiColor: .systemBackground))
    }
}

struct ReposFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        ReposFeature.View(
            store: .init(
                initialState: .init(
                    repos: [
                        .init(
                            repoURL: .init(string: "/").unsafelyUnwrapped,
                            manifest: .init(
                                id: "repo-1",
                                name: "Repo 1",
                                author: "errorerrorerror"
                            )
                        )
                    ]
                ),
                reducer: ReposFeature.Reducer()
            )
        )
    }
}
