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
    @MainActor
    public var body: some View {
        NavStack(
            store.scope(
                state: \.path,
                action: { .internal(.path($0)) }
            )
        ) {
            WithViewStore(store, observe: \.repos) { viewStore in
                ScrollView(
                    viewStore.isEmpty ? [] : .vertical,
                    showsIndicators: false
                ) {
                    LazyVStack(spacing: 0) {
                        repoUrlTextInput
                            .padding(.horizontal)

                        Spacer()
                            .frame(height: 24)

                        if !viewStore.isEmpty {
                            Text("Installed Repos")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)

                            ForEach(viewStore.state) { repo in
                                repoRow(repo)
                                    .padding(.horizontal)
                                    .background(Color.theme.backgroundColor)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        self.store.send(.view(.didTapRepo(repo.id)))
                                    }
                                    .contextMenu {
                                        Button {
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
                        }
                    }
                    .animation(.easeInOut, value: viewStore.state)
                }
                .overlay {
                    if viewStore.isEmpty {
                        noReposView
                    }
                }
            }
            .topBar(title: "Repos") {
                Button {
                    store.send(.view(.didTapRefreshRepos(nil)))
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.materialToolbarImage)
            } bottomAccessory: {
                EmptyView()
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .onAppear {
                store.send(.view(.didAppear))
            }
        } destination: { store in
            RepoPackagesFeature.View(store: store)
        }
    }
}

extension ReposFeature.View {
    @MainActor
    var noReposView: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 4)

            repoUrlTextInput
                .hidden()

            Spacer()

            Text("No repos installed")
                .font(.callout)

            Spacer()
        }
    }

    private struct RepoURLInputViewState: Equatable, @unchecked Sendable {
        @BindingViewState
        var url: String
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

    @MainActor
    var repoUrlTextInput: some View {
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
                    .font(.system(size: 16, weight: .regular))
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
                    .foregroundColor(.gray.opacity(0.1))
            )
            .animation(.easeInOut(duration: 0.2), value: viewStore.searchedRepo)
            .animation(.easeInOut(duration: 0.2), value: viewStore.url.count)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

extension ReposFeature.View {
    @MainActor
    func repoRow(_ repo: Repo) -> some View {
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
            .squircle()

            VStack(alignment: .leading, spacing: 2) {
                Text(repo.name)
                    .font(.callout.weight(.medium))

                HStack(spacing: 0) {
                    Text(repo.remoteURL.host ?? repo.author)
                        .font(.footnote)
                }
                .lineLimit(1)
                .foregroundColor(.gray)
            }

            Spacer()

//            WithViewStore(store, observe: \.repoModules[repo.id] ?? .pending) { viewStore in
//                ZStack {
//                    LoadableView(loadable: viewStore.state) { _ in
//                        Image(systemName: "checkmark.circle.fill")
//                            .foregroundColor(.green)
//                    } failedView: { _ in
//                        Image(systemName: "exclamationmark.triangle.fill")
//                            .foregroundColor(.red)
//                    } waitingView: {
//                        ProgressView()
//                            .controlSize(.small)
//                    }
//                    .frame(width: 34, height: 34)
//                    .transition(.opacity.combined(with: .scale))
//                }
//                .animation(.easeInOut(duration: 0.25), value: viewStore.state)
//            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
}

// MARK: - ReposFeatureView_Previews

struct ReposFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        ReposFeature.View(
            store: .init(
                initialState: .init(),
                reducer: { ReposFeature() }
            )
        )
    }
}
