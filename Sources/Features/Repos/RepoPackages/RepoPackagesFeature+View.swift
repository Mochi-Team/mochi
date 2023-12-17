//
//  RepoPackagesFeature+View.swift
//
//
//  Created ErrorErrorError on 5/4/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import DatabaseClient
import NukeUI
import RepoClient
import SharedModels
import Styling
import SwiftUI
import ViewComponents

// MARK: - RepoPackagesFeature.View + View

extension RepoPackagesFeature.View: View {
  @MainActor public var body: some View {
    ScrollViewTracker(.vertical) {
      LazyVStack(spacing: 12) {
        repoHeader

        Divider()
          .padding(.horizontal)

        WithViewStore(store, observe: \.installedModules) { viewStore in
          Group {
            if !viewStore.isEmpty {
              LazyVStack(spacing: 8) {
                Text("Installed Modules")
                  .font(.footnote.weight(.medium))
                  .foregroundColor(.gray)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .padding(.horizontal)

                LazyVStack(spacing: 8) {
                  ForEach(viewStore.state) { module in
                    packageRow([module.manifest])
                  }
                }
              }
              .transition(.opacity)
            }
          }
          .animation(.easeInOut, value: viewStore.state.count)
        }

        WithViewStore(store, observe: \.packages) { viewStore in
          LazyVStack(spacing: 8) {
            Text("All Modules")
              .font(.footnote.weight(.medium))
              .foregroundColor(.gray)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal)
              .transition(.opacity)

            LoadableView(loadable: viewStore.state) { packages in
              Group {
                if packages.isEmpty || !packages.contains(where: !\.isEmpty) {
                  StatusView(.noModulesFound)
                    .transition(.opacity)
                } else {
                  LazyVStack(spacing: 8) {
                    ForEach(packages, id: \.self) { package in
                      if !package.isEmpty {
                        packageRow(package)
                      }
                    }
                  }
                }
              }
              .transition(.opacity)
            } failedView: { _ in
              StatusView(.failedToFetch)
                .transition(.opacity)
            } waitingView: {
              StatusView(.fetchingModules)
                .transition(.opacity)
            }
          }
          .animation(.easeInOut, value: viewStore.state)
        }
        .frame(maxWidth: .infinity)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(theme.backgroundColor.ignoresSafeArea().edgesIgnoringSafeArea(.all))
    .task { await store.send(.view(.onTask)).finish() }
    .navigationTitle("")
    #if os(iOS)
      .refreshable { await store.send(.view(.didTapToRefreshRepo)).finish() }
      .navigationBarTitleDisplayMode(.inline)
    #elseif os(macOS)
      .toolbar {
        ToolbarItem(placement: .automatic) {
          Button {
            store.send(.view(.didTapToRefreshRepo))
          } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
          }
        }
      }
    #endif
  }
}

extension RepoPackagesFeature.View {
  @MainActor var repoHeader: some View {
    WithViewStore(store, observe: \.repo) { viewStore in
      VStack(alignment: .leading, spacing: 0) {
        Spacer()
          .frame(height: 12)

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
        .squircle()
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

    var details: String {
      switch self {
      case .failedToFetch:
        "There was an error communicating with the repo."
      case .noModulesFound:
        "Check your internet connection."
      case .fetchingModules:
        "Currently attempting to retrieve modules from repo."
      }
    }

    var packageIconColor: Color {
      switch self {
      case .fetchingModules:
        .gray
      case .noModulesFound:
        .orange
      case .failedToFetch:
        .red
      }
    }

    var icon: String {
      switch self {
      case .noModulesFound:
        "package.badge.questionmark.fill"
      case .fetchingModules:
        "package.badge.clock.fill"
      case .failedToFetch:
        "package.trianglebadge.exclamationmark.fill"
      }
    }
  }

  struct PackageDownloadState: Equatable {
    let repo: Repo
    let installedModule: Module?
    let downloadState: RepoClient.RepoModuleDownloadState?
  }

  @MainActor
  @ViewBuilder
  func packageRow(_ modules: [Module.Manifest]) -> some View {
    let latestModule = modules.latestModule
    WithViewStore(store) { state in
      PackageDownloadState(
        repo: state.repo,
        installedModule: state.repo.modules.first(where: \.id == latestModule.id),
        downloadState: state.downloadStates.first(where: \.key == latestModule.id)?.value
      )
    } content: { viewStore in
      HStack(alignment: .center, spacing: 16) {
        LazyImage(url: latestModule.iconURL(repoURL: viewStore.repo.remoteURL)) { state in
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
              viewStore.send(.didTapRemoveModule(latestModule.id))
            }
          } else if let installedModule = viewStore.installedModule {
            if installedModule.version < latestModule.version {
              Button {
                viewStore.send(.didTapAddModule(latestModule.id))
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
              viewStore.send(.didTapAddModule(latestModule.id))
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
            viewStore.send(.didTapRemoveModule(installed.id))
          } label: {
            Label("Remove module", systemImage: "trash.fill")
          }
          .buttonStyle(.plain)
        }
      }
    }
    .background(theme.backgroundColor)
  }
}

// MARK: - RefreshableState

enum RefreshableState {
  case pulling(CGPoint)
  case released(CGPoint)
}

extension StatusView {
  init(_ status: RepoPackagesFeature.View.PackagesStatusState) {
    self.init(
      title: status.rawValue,
      description: status.details,
      image: .asset(status.icon),
      foregroundColor: status.packageIconColor
    )
  }
}

// MARK: - RepoPackagesFeatureView_Previews

#Preview {
  NavigationView {
    RepoPackagesFeature.View(
      store: .init(
        initialState: .init(
          repo: .init(
            remoteURL: .init(string: "/").unsafelyUnwrapped,
            manifest: .init(name: "Repo 1", author: "errorerrorerror")
          )
        ),
        reducer: { EmptyReducer() }
      )
    )
  }
}
