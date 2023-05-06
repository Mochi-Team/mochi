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
import SharedModels
import Styling
import SwiftUI
import ViewComponents

extension RepoPackagesFeature.View: View {
    @MainActor
    public var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 12) {
                Spacer()
                    .frame(height: topBarSizeInset.size.height)

                repoHeader
                packagesView

                Spacer()
                    .frame(height: tabNavigationInset.height)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlay(alignment: .top, content: topBar)
        .onAppear {
            ViewStore(store.viewAction.stateless).send(.didAppear)
        }
        .background(Color(uiColor: .systemBackground).ignoresSafeArea().edgesIgnoringSafeArea(.all))
    }
}

extension RepoPackagesFeature.View {
    @MainActor
    func topBar() -> some View {
        TopBarView {
            ViewStore(store.viewAction.stateless).send(.didTapBackButton)
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

    @MainActor
    var packagesView: some View {
        WithViewStore(store.viewAction, observe: \.packages) { viewStore in
            Divider()
                .padding(.horizontal)

            LoadableView(loadable: viewStore.state) { packages in
                if packages.isEmpty || !packages.contains(where: !\.isEmpty) {
                    packagesStatusView(.noModulesFound)
                } else {
                    ForEach(Array(zip(packages.indices, packages)), id: \.0) { _, package in
                        if !package.isEmpty {
                            packageRow(package)
                                .padding(.horizontal)
                        }
                    }
                }
            } failedView: { _ in
                packagesStatusView(.failedToFetch)
            } waitingView: {
                packagesStatusView(.fetchingModules)
            }
        }
        .frame(maxWidth: .infinity)
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
        let downloadState: Double?
    }

    @MainActor
    @ViewBuilder
    func packageRow(_ modules: [Module.Manifest]) -> some View {
        let latestModule = modules.latestModule
        WithViewStore(store.viewAction) { state in
            PackageDownloadState(
                repo: state.repo,
                installedModule: state.installedModules.first(where: \.id == latestModule.id),
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

                // TODO: Add install module

                HStack(spacing: 0) {
                    if let downloadState = viewStore.downloadState {
                        CircularProgressView(
                            progress: downloadState,
                            barStyle: .init(fill: .blue, width: 4, blurRadius: 1)
                        ) {
                            Image(systemName: "stop.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.blue)
                                .padding(6)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewStore.send(.didTapRemoveModule(latestModule.id))
                        }
                    } else if let installedModule = viewStore.installedModule {
                        if installedModule.version < latestModule.version {
                            Button {
                                viewStore.send(.didTapInstallModule(latestModule.id))
                            } label: {
                                Image(systemName: "arrow.up.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.green)
                        }
                    } else {
                        Button {
                            viewStore.send(.didTapInstallModule(latestModule.id))
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: 24, height: 24)
                .animation(.easeInOut(duration: 0.25), value: viewStore.state)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
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
                    ,
                    packages: .loaded([
                        [
                            .init(
                                id: "module-1",
                                name: "Module 1",
                                file: "/hello/test.wasm",
                                version: .init(1, 0, 0),
                                released: .init(),
                                meta: [.video, .image, .text]
                            )
                        ]
                    ])
//                    ,
//                    installedModules: [
//                        .init(
//                            binaryModule: .init(),
//                            installDate: .init(),
//                            manifest: .init(
//                                id: "module-1",
//                                name: "Module 1",
//                                file: "/hello/test.wasm",
//                                version: .init(1, 0, 0),
//                                released: .init(),
//                                meta: [.video, .image, .text]
//                            )
//                        )
//                    ]
//                    ,
//                    installingModules: ["module-1": 0.2]
                ),
                reducer: EmptyReducer()
            )
        )
    }
}
