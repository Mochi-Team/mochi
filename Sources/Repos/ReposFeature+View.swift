//
//  ReposFeature+View.swift
//
//
//  Created ErrorErrorError on 4/18/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import NukeUI
import SharedModels
import Styling
import SwiftUI
import ViewComponents

// MARK: - ReposFeature.View + View

extension ReposFeature.View: View {
    @MainActor
    public var body: some View {
        WithViewStore(store.viewAction, observe: \.repos) { viewStore in
            ScrollView(
                viewStore.state.isEmpty ? [] : .vertical,
                showsIndicators: false
            ) {
                LazyVStack(spacing: 0) {
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
                            repoRow(repo)
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
                }
                .animation(.easeInOut, value: viewStore.state.count)
            }
            .topBar(title: "Repos") {
                Button {
                    store.viewAction.send(.didAskToRefreshModules)
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.materialToolbarImage)
            } bottomAccessory: {
                EmptyView()
            }
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
            store.viewAction.send(.didAppear)
        }
        .overlay {
            IfLetStore(
                store.scope(
                    state: \.selected,
                    action: \.`self`
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
                .frame(height: 4)

            repoUrlTextInput
                .hidden()

            Spacer()

            Text("No repos installed")
                .font(.callout)

            Spacer()
        }
    }

    @MainActor
    var repoUrlTextInput: some View {
        WithViewStore(
            store.viewAction,
            observe: \.`self`
        ) { viewStore in
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Group {
                        switch viewStore.repo {
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

                LoadableView(loadable: viewStore.repo) { repo in
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
                    .padding(.vertical, 12)
                }
                .padding(.horizontal)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .foregroundColor(.gray.opacity(0.1))
            )
            .animation(.easeInOut(duration: 0.2), value: viewStore.repo)
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
                    Text(repo.baseURL.host ?? repo.author)
                        .font(.footnote)
                }
                .lineLimit(1)
                .foregroundColor(.gray)
            }

            Spacer()

            WithViewStore(store, observe: \.repoModules[repo.id] ?? .pending) { viewStore in
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
                reducer: { ReposFeature.Reducer() }
            )
        )
    }
}
