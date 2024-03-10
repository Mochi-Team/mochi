//
//  SettingsFeature+Reducer.swift
//
//
//  Created ErrorErrorError on 4/8/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import PlaylistHistoryClient
import UserSettingsClient

extension SettingsFeature {
  @ReducerBuilder<State, Action> public var body: some ReducerOf<Self> {
    Scope(state: \.self, action: \.view) {
      BindingReducer()
        .onChange(of: \.userSettings) { _, userSettings in
          Reduce { _, _ in
            .run { await userSettingsClient.set(userSettings) }
          }
        }
    }

    Reduce { state, action in
      switch action {
      case .view(.didTapViewLogs):
        state.path.append(.logs(.init()))
      case .view(.clearHistory):
        @Dependency(\.playlistHistoryClient) var playlistHistoryClient
        return .run {
          try? await playlistHistoryClient.clearHistory()
        }
      case .view(.onTask):
        break
      case .view(.binding):
        break
      case .internal:
        break
      }
      return .none
    }
    .forEach(\.path, action: \.internal.path) {
      Path()
    }
  }
}
