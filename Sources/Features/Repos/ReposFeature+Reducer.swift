//
//  ReposFeature+Reducer.swift
//
//
//  Created ErrorErrorError on 4/18/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ClipboardClient
import ComposableArchitecture
import Foundation
import LoggerClient
import RepoClient
import SharedModels
import Styling

extension ReposFeature {
  enum Cancellables: Hashable {
    case repoURLDebounce
    case refreshFetchingAllRemoteModules
    case loadRepos
    case observeInstallingModules
  }

  private enum Error: Swift.Error {
    case notValidRepo
  }

  @ReducerBuilder<State, Action> public var body: some ReducerOf<Self> {
    Case(/Action.view) {
      BindingReducer()
    }

    Reduce { state, action in
      switch action {
      case .view(.onTask):
        return .run { send in
          for await value in repoClient.repos(.all) {
            await send(.internal(.loadRepos(value)))
          }
        }

      case let .view(.didTapAddNewRepo(repoPayload)):
        state.url = ""
        state.searchedRepo = .pending

        return .run { try await repoClient.addRepo(repoPayload) }

      case let .view(.didTapCopyRepoURL(repoId)):
        return .run { clipboardClient.copyValue(repoId.rawValue.absoluteString) }

      case let .view(.didTapDeleteRepo(repoId)):
        return .merge(
          .run { _ in
            try await Task.sleep(nanoseconds: 1_000_000 * 500)
            try await repoClient.deleteRepo(repoId)
          },
          .run { try await moduleClient.removeCachedModules(repoId) }
        )

      case let .view(.didTapRepo(repoId)):
        guard let repo = state.repos[id: repoId] else {
          break
        }
        state.path.append(RepoPackagesFeature.State(repo: repo))

      case .view(.binding(\.$url)):
        guard let url = URL(sanitize: state.url) else {
          state.searchedRepo = .pending
          return .cancel(id: Cancellables.repoURLDebounce)
        }

        state.searchedRepo = .loading

        return .run { send in
          try await withTaskCancellation(id: Cancellables.repoURLDebounce, cancelInFlight: true) {
            await send(.internal(.validateRepoURL(.loading)))
            try await Task.sleep(nanoseconds: 1_000_000 * 1_250)
            try await send(.internal(.validateRepoURL(.loaded(repoClient.validate(url)))))
          }
        } catch: { error, send in
          logger.error("Failed to validate repo: \(error.localizedDescription)")
          await send(.internal(.validateRepoURL(.failed(Error.notValidRepo))))
        }

      case .view(.binding):
        break

      case let .internal(.validateRepoURL(loadable)):
        state.searchedRepo = loadable

      case let .internal(.loadRepos(repos)):
        state.repos = .init(uniqueElements: repos)

      case .internal(.path):
        break

      case .delegate:
        break
      }
      return .none
    }
    .forEach(\.path, action: \.internal.path) {
      RepoPackagesFeature()
    }
  }
}

extension URL {
  init?(sanitize string: String) {
    var components = URLComponents(string: string)
    // Lowercase host and schema since they're not case sensitive
    let host = components?.host?.lowercased()
    let schema = components?.scheme?.lowercased()
    components?.host = host
    components?.scheme = schema

    // Everything else is case sensitive, so check if there's a foward slash. If not, add it.

    guard var string = components?.string else {
      return nil
    }

    // Remove trailing slash
    if string.hasSuffix("/") {
      string = .init(string.dropLast())
    }

    self.init(string: string)
  }
}
