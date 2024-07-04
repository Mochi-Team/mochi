//
//  DownloadQueueFeature+Reducer.swift
//
//
//  Created by MochiTeam on 17.05.2024.
//

import Architecture
import ComposableArchitecture
import Foundation

extension DownloadQueueFeature: Reducer {
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
        case .view(.didAppear):
          return .run { send in
            for await items in offlineManagerClient.observeDownloading() {
              await send(.internal(.updateDownloadingItems(items)))
            }
          }
          
        case let .view(.didTapCancelDownload(item)):
          return .run { send in
            try await offlineManagerClient.cancel(item.taskId)
          }
        
        case let .view(.pause(item)):
          return .run { send in
            try await offlineManagerClient.togglePause(item.taskId)
          }
          
        case let .internal(.updateDownloadingItems(items)):
          state.downloadQueue = items
      }
      return .none
    }
  }
}
