//
//  DownloadQueueFeature.swift
//
//
//  Created by MochiTeam on 16.05.2024.
//

import Architecture
import ComposableArchitecture
import Foundation
import OfflineManagerClient

// MARK: - DownloadQueueFeature

public struct DownloadQueueFeature: Feature {
  public struct State: FeatureState {
    public var downloadQueue: [OfflineManagerClient.DownloadingItem]
    
    public init(
      downloadQueue: [OfflineManagerClient.DownloadingItem] = []
    ) {
      self.downloadQueue = downloadQueue
    }
  }
  
  @CasePathable
  @dynamicMemberLookup
  public enum Action: FeatureAction {
    @CasePathable
    @dynamicMemberLookup
    public enum ViewAction: SendableAction {
      case didAppear
      case didTapCancelDownload(OfflineManagerClient.DownloadingItem)
      case pause(OfflineManagerClient.DownloadingItem)
    }

    @CasePathable
    @dynamicMemberLookup
    public enum DelegateAction: SendableAction {}

    @CasePathable
    @dynamicMemberLookup
    public enum InternalAction: SendableAction {
      case updateDownloadingItems([OfflineManagerClient.DownloadingItem])
    }

    case view(ViewAction)
    case delegate(DelegateAction)
    case `internal`(InternalAction)
  }
  
  @MainActor
  public struct View: FeatureView {
    public let store: StoreOf<DownloadQueueFeature>
    @MainActor
    public init(store: StoreOf<DownloadQueueFeature>) {
      self.store = store
    }
  }
  
  @Dependency(\.offlineManagerClient) var offlineManagerClient
  
  public init() {}
}
