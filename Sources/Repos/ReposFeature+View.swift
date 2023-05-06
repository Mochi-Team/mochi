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
import Styling
import SwiftUI
import ViewComponents

extension ReposFeature.View: View {
    @MainActor
    public var body: some View {
        WithViewStore(store.viewAction, observe: \.repos) { viewStore in
            ScrollView(
                viewStore.state.isEmpty ? [] : .vertical,
                showsIndicators: false
            ) {
                LazyVStack(spacing: 0) {
                    Spacer()
                        .frame(height: topBarSize.size.height)

                    Spacer()
                        .frame(height: 4)

                    repoUrlTextInput
                        .padding(.horizontal)

                    Spacer()
                        .frame(height: 24)

                    if !viewStore.state.isEmpty {
                        Text("Installed Repos")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        ForEach(viewStore.state) { repo in
                            repoRow(repo, repo.id == viewStore.state.last?.id)
                                .padding(.horizontal)
                                .background(Color(uiColor: .systemBackground))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewStore.send(.didTapRepo(repo.id))
                                }
                                .contextMenu {
                                    Button {
                                        viewStore.send(.didTapToDeleteRepo(repo.id))
                                    } label: {
                                        Label("Delete Repo", systemImage: "trash.fill")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                }

                            if repo.id != viewStore.state.last?.id {
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }

                    Spacer()
                        .frame(height: tabNavigationSize.height)
                }
                .animation(.easeInOut, value: viewStore.state.count)
            }
            .overlay(topBar, alignment: .top)
            .overlay {
                if viewStore.state.isEmpty {
                    noReposView
                }
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .onAppear {
            ViewStore(store.viewAction.stateless).send(.didAppear)
        }
        .overlay {
            IfLetStore(
                store.internalAction.scope(
                    state: \.repoPackages,
                    action: Action.InternalAction.repoPackages
                ),
                then: RepoPackagesFeature.View.init
            )
        }
    }
}

extension ReposFeature.View {
    @MainActor
    var noReposView: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: topBarSize.size.height)

            Spacer()
                .frame(height: 4)

            repoUrlTextInput
                .hidden()

            Spacer()

            Text("No repos installed")
                .font(.callout)

            Spacer()

            Spacer()
                .frame(height: tabNavigationSize.height)
        }
    }

    @MainActor
    var repoUrlTextInput: some View {
        WithViewStore(
            store.viewAction,
            observe: \.`self`
        ) { viewStore in
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Group {
                        switch viewStore.urlRepoState.repo {
                        case .failed:
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                        case .loading:
                            ProgressView()
                                .fixedSize(horizontal: true, vertical: true)
                        default:
                            Image(systemName: "magnifyingglass")
                        }
                    }

                    TextField(
                        "Enter or paste a repo url...",
                        text: viewStore.binding(\.urlRepoState.$url)
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

                LoadableView(loadable: viewStore.urlRepoState.repo) { repo in
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

                        if !viewStore.repos.contains(where: \.id.rawValue == repo.remoteURL) {
                            Button {
                                viewStore.send(.didTapToAddNewRepo(repo))
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
                    .padding(.vertical, 10)
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
        WithViewStore(
            store.viewAction,
            observe: \.loadedModules[repo.id] ?? .pending
        ) { viewStore in
            HStack(alignment: .top, spacing: 16) {
                LazyImage(url: repo.iconURL) { state in
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

                VStack(alignment: .leading, spacing: 2) {
                    Text(repo.name)
                        .font(.callout.weight(.medium))

                    HStack(spacing: 0) {
                        Text(repo.baseURL.host ?? repo.author)
                            .font(.footnote)
                    }
                    .lineLimit(1)
                    .foregroundColor(.gray)
                }

                Spacer()

                ZStack {
                    LoadableView(loadable: viewStore.state) { _ in
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } failedView: { _ in
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    } waitingView: {
                        ProgressView()
                            .controlSize(.small)
                    }
                    .frame(width: 34, height: 34)
                    .transition(.opacity.combined(with: .scale))
                }
                .animation(.easeInOut(duration: 0.25), value: viewStore.state)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
    }
}

extension ReposFeature.View {
    @MainActor
    var topBar: some View {
        TopBarView(
            title: "Repos",
            buttons: [
                .init(style: .systemImage("arrow.triangle.2.circlepath")) {
                    ViewStore(store.viewAction.stateless).send(.didAskToRefreshModules)
                }
            ]
        )
        .readSize { size in
            topBarSize = size
        }
    }
}

struct ReposFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        ReposFeature.View(
            store: .init(
                initialState: .init(
                    repos: [
                        .init(
                            baseURL: .init(string: "http://192.168.86.35:3000").unsafelyUnwrapped,
                            dateAdded: .init(),
                            lastRefreshed: .init(),
                            manifest: .init(
                                name: "Repo 1",
                                author: "errorerrorerror"
                            )
                        ),
                        .init(
                            baseURL: .init(string: "/").unsafelyUnwrapped,
                            dateAdded: .init(),
                            lastRefreshed: .init(),
                            manifest: .init(
                                name: "Repo 2",
                                author: "lol",
                                description: nil,
                                icon: nil
                            )
                        )
                    ]
                ),
                reducer: ReposFeature.Reducer()
            )
        )
    }
}
