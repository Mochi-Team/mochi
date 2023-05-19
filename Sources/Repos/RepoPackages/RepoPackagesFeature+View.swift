//
//  RepoPackagesFeature+View.swift
//
//
//  Created ErrorErrorError on 5/4/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import NukeUI
import RepoClient
import SharedModels
import Styling
import SwiftUI
import ViewComponents

extension RepoPackagesFeature.View: View {
    @MainActor
    public var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                repoHeader

                Spacer()
                    .frame(height: 12)

                Divider()
                    .padding(.horizontal)

                Spacer()
                    .frame(height: 12)

                WithViewStore(store.viewAction, observe: \.installedModules) { viewStore in
                    LazyVStack(spacing: 0) {
                        if !viewStore.isEmpty {
                            Text("Installed Modules")
                                .font(.footnote.bold())
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)

                            Spacer()
                                .frame(height: 8)

                            ForEach(viewStore.state) { module in
                                packageRow([module.manifest])

                                if viewStore.state.last?.id != module.id {
                                    Spacer()
                                        .frame(height: 12)
                                }
                            }

                            Spacer()
                                .frame(height: 8)
                        }
                    }
                    .transition(.opacity)
                    .animation(.easeInOut, value: viewStore.state.count)
                }

                WithViewStore(store.viewAction, observe: \.`self`) { viewStore in
                    LazyVStack(spacing: 0) {
                        Text("All Modules")
                            .font(.footnote.bold())
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .transition(.opacity)

                        Spacer()
                            .frame(height: 8)
                            .transition(.opacity)

                        LoadableView(loadable: viewStore.packages) { packages in
                            Group {
                                if packages.isEmpty || !packages.contains(where: !\.isEmpty) {
                                    packagesStatusView(.noModulesFound)
                                } else {
                                    ForEach(Array(zip(packages.indices, packages)), id: \.0) { _, package in
                                        if !package.isEmpty {
                                            packageRow(package)

                                            if packages.last?.latestModule.id != package.latestModule.id {
                                                Spacer()
                                                    .frame(height: 12)
                                            }
                                        }
                                    }
                                }
                            }
                            .transition(.opacity)
                        } failedView: { _ in
                            packagesStatusView(.failedToFetch)
                                .transition(.opacity)
                        } waitingView: {
                            packagesStatusView(.fetchingModules)
                                .transition(.opacity)
                        }
                    }
                    .animation(.easeInOut, value: viewStore.packages)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .safeAreaInset(edge: .top, content: topBar)
        .safeAreaInset(edge: .bottom) {
            Spacer()
                .frame(height: tabNavigationInset.height)
        }
        .onAppear {
            ViewStore(store.viewAction.stateless).send(.didAppear)
        }
        .background(Color(uiColor: .systemBackground).ignoresSafeArea().edgesIgnoringSafeArea(.all))
        .transition(.move(edge: .trailing).combined(with: .opacity))
        .screenDismissed {
            ViewStore(store.viewAction.stateless).send(.didTapBackButtonForOverlay)
        }
    }
}

extension RepoPackagesFeature.View {
    @MainActor
    func topBar() -> some View {
        TopBarView {
            ViewStore(store.viewAction.stateless).send(.didTapBackButtonForOverlay)
        }
        .readSize { sizeInset in
            topBarSizeInset = sizeInset
        }
    }

    @MainActor
    var repoHeader: some View {
        WithViewStore(store.viewAction, observe: \.repo) { viewStore in
            VStack(alignment: .leading, spacing: 0) {
                LazyImage(url: viewStore.iconURL) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Image(systemName: "questionmark.square.dashed")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }
                .frame(width: 58, height: 58)
                .padding(.bottom)

                Text(viewStore.name)
                    .font(.title2.weight(.semibold))

                Spacer()
                    .frame(height: 4)

                Text(viewStore.description ?? "Description unavailable for this repo.")
                    .font(.callout)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
    }
}

extension RepoPackagesFeature.View {
    enum PackagesStatusState: String {
        case fetchingModules = "Fetching Modules..."
        case noModulesFound = "No Modules Available"
        case failedToFetch = "Failed to Fetch Modules"

        var description: String? {
            switch self {
            case .failedToFetch:
                return "There was an error communicating with the repo."
            default:
                return nil
            }
        }

        var packageIconColor: Color {
            switch self {
            case .fetchingModules:
                return .gray
            case .noModulesFound:
                return .orange
            case .failedToFetch:
                return .red
            }
        }

        var backgroundColor: Color {
            switch self {
            case .fetchingModules:
                return .gray
            case .noModulesFound:
                return .gray
            case .failedToFetch:
                return .red
            }
        }
    }

    @MainActor
    func packagesStatusView(_ state: PackagesStatusState) -> some View {
        VStack(spacing: 0) {
            Image(systemName: "shippingbox.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(state.packageIconColor)
                .frame(width: 32)

            Spacer()
                .frame(height: 8)

            Text(state.rawValue)
                .font(.callout.weight(.semibold))

            if let description = state.description {
                Spacer()
                    .frame(height: 2)

                Text(description)
                    .font(.footnote)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(state.backgroundColor.opacity(0.12))
        .cornerRadius(12)
        .padding()
    }

    struct PackageDownloadState: Equatable {
        let repo: Repo
        let installedModule: Module?
        let downloadState: RepoClient.RepoModuleDownloadState?
    }

    @MainActor
    @ViewBuilder
    func moduleRow(_ module: Module) -> some View {

    }

    @MainActor
    @ViewBuilder
    func packageRow(_ modules: [Module.Manifest]) -> some View {
        let latestModule = modules.latestModule
        WithViewStore(store.viewAction) { state in
            PackageDownloadState(
                repo: state.repo,
                installedModule: state.repo.modules.first(where: \.id == latestModule.id),
                downloadState: state.installingModules.first(where: \.key == latestModule.id)?.value
            )
        } content: { viewStore in
            HStack(alignment: .center, spacing: 16) {
                LazyImage(url: latestModule.iconURL(repoURL: viewStore.repo.baseURL)) { state in
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
                    HStack(spacing: 2) {
                        Text(latestModule.name)
                            .font(.callout.weight(.medium))

                        Text("\u{2022}")
                            .foregroundColor(.gray)

                        Text("v\(latestModule.version.description)")
                            .font(.footnote.weight(.medium))
                            .foregroundColor(.gray)
                    }

                    HStack(spacing: 0) {
                        Text(latestModule.description ?? "Description unavailable")
                            .font(.footnote)
                    }
                    .lineLimit(1)
                    .foregroundColor(.gray)
                }

                Spacer()

                HStack(spacing: 0) {
                    if let downloadState = viewStore.downloadState, downloadState != .installed {
                        Group {
                            switch downloadState {
                            case .pending:
                                EmptyView()
                            case let .downloading(progress):
                                CircularProgressView(
                                    progress: progress,
                                    barStyle: .init(fill: .blue, width: 4, blurRadius: 1)
                                ) {
                                    Image(systemName: "stop.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(.blue)
                                        .padding(6)
                                }
                            case .installing:
                                ProgressView()
                                    .controlSize(.small)
                            case .installed:
                                EmptyView()
                            case .failed:
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.red)
                            }
                        }
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewStore.send(.didTapRemoveModule(viewStore.repo.id, latestModule.id))
                        }
                    } else if let installedModule = viewStore.installedModule {
                        if installedModule.version < latestModule.version {
                            Button {
                                viewStore.send(.didTapAddModule(viewStore.repo.id, latestModule.id))
                            } label: {
                                Image(systemName: "arrow.up.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(.plain)
                            .frame(width: 24, height: 24)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.green)
                                .frame(width: 24, height: 24)
                        }
                    } else {
                        Button {
                            viewStore.send(.didTapAddModule(viewStore.repo.id, latestModule.id))
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 24, height: 24)
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: viewStore.state)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal)
            .contentShape(Rectangle())
            .contextMenu {
                if let installed = viewStore.installedModule {
                    Button {
                        viewStore.send(.didTapRemoveModule(viewStore.repo.id, installed.id))
                    } label: {
                        Label("Remove module", systemImage: "trash.fill")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct RepoPackagesFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        RepoPackagesFeature.View(
            store: .init(
                initialState: .init(
                    repo: .init(
                        baseURL: .init(string: "/").unsafelyUnwrapped,
                        dateAdded: .init(),
                        lastRefreshed: nil,
                        manifest: .init(name: "Repo 1", author: "errorerrorerror")
                    )
//                    ,
//                    modules: .loaded([
//                        .init(
//                            id: "module-1",
//                            name: "Module 1",
//                            file: "/hello/test.wasm",
//                            version: .init(1, 0, 0),
//                            released: .init(),
//                            meta: [.video, .image, .text]
//                        )
//                    ])
                ),
                reducer: EmptyReducer()
            )
        )
    }
}
