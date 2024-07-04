//
//  Client.swift
//
//
//  Created by MochiTeam on 06.04.2024.
//

import FileClient
import Dependencies
@_exported
import Foundation
import SharedModels
import Tagged
import XCTestDynamicOverlay

// MARK: - OfflineManagerClient

public struct OfflineManagerClient {
  public var download: @Sendable (DownloadAsset) async throws -> Void
  public var cache: @Sendable (CacheAsset) async throws -> Void
  public var remove: @Sendable (RemoveType, String, String?) async throws -> Void
  public var togglePause: @Sendable (Int) async throws -> Void
  public var cancel: @Sendable (Int) async throws -> Void
  public var observeDownloading: @Sendable () -> AsyncStream<[DownloadingItem]>
}

// MARK: TestDependencyKey

extension OfflineManagerClient: TestDependencyKey {
  public static let testValue = Self(
    download: unimplemented("\(Self.self).download"),
    cache: unimplemented("\(Self.self).cache"),
    remove: unimplemented("\(Self.self).remove"),
    togglePause: unimplemented("\(Self.self).togglePause"),
    cancel: unimplemented("\(Self.self).cancel"),
    observeDownloading: unimplemented("\(Self.self).observeDownloading")
  )
}

extension DependencyValues {
  public var offlineManagerClient: OfflineManagerClient {
    get { self[OfflineManagerClient.self] }
    set { self[OfflineManagerClient.self] = newValue }
  }
}
