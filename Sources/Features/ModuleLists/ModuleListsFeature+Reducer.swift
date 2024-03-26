//
//  ModuleListsFeature+Reducer.swift
//
//
//  Created ErrorErrorError on 4/23/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import DatabaseClient
import Foundation
import RepoClient

let defaults = UserDefaults.standard

extension ModuleListsFeature {
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .view(.onTask):
        return .run { send in
          for await items in databaseClient.observe(Request<Repo>.all) {
            await send(.internal(.fetchRepos(.success(items))))
          }
        }

      case .view(.didTapToDismiss):
        return .run {
          await dismiss()
        }

      case let .view(.didSelectModule(repoId, moduleId)):
        guard let module = state.repos[id: repoId]?.modules[id: moduleId]?.manifest else {
          break
        }
        defaults.set(moduleId.rawValue, forKey: "LastSelectedModuleId")
        defaults.set(repoId.rawValue, forKey: "LastSelectedRepoId")
        return .concatenate(.send(.delegate(.selectedModule(.init(repoId: repoId, module: module)))))

      case let .internal(.fetchRepos(.success(repos))):
        state.repos = repos

      case .internal(.fetchRepos(.failure)):
        state.repos = []

      case .delegate:
        break
      }
      return .none
    }
  }
}
