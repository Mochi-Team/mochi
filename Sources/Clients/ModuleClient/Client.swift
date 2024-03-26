//
//  Client.swift
//
//
//  Created ErrorErrorError on 4/10/23.
//  Copyright © 2023. All rights reserved.
//

import Dependencies
import Foundation
import SharedModels
import SwiftSoup
import XCTestDynamicOverlay

// MARK: - ModuleClient

public struct ModuleClient: Sendable {
  public var initialize: @Sendable () async throws -> Void
  var getModule: @Sendable (_ repoModuleId: RepoModuleID) async throws -> Self.Instance
  public var removeCachedModule: @Sendable (_ repoModuleId: RepoModuleID) async throws -> Void
  public var removeCachedModules: @Sendable (_ repoID: Repo.ID) async throws -> Void
}

extension ModuleClient {
  public func withModule<R>(id: RepoModuleID, work: @Sendable (Self.Instance) async throws -> R) async throws -> R {
    try await work(getModule(id))
  }
}

// MARK: ModuleClient.Error

extension ModuleClient {
  public enum Error: Swift.Error, Equatable, Sendable {
    case client(ClientError)
    case jsRuntime(JSRuntimeError)
  }
}

// MARK: - ModuleClient.Error.ClientError

extension ModuleClient.Error {
  public enum ClientError: Equatable, Sendable {
    case moduleNotFound
  }
}

// MARK: - ModuleClient.Error.JSRuntimeError

extension ModuleClient.Error {
  public enum JSRuntimeError: Equatable, Sendable {
    case promiseValueError
    case retrievingInstanceFailed
    case instanceCreationFailed
    case instanceCall(function: String, msg: String)
    case requestForbidden(data: String, hostname: String)
  }
}

// MARK: - SwiftSoup.Exception + Equatable

extension SwiftSoup.Exception: Equatable {
  public static func == (lhs: Exception, rhs: Exception) -> Bool {
    switch (lhs, rhs) {
    case let (.Error(typeOne, messageOne), .Error(typeTwo, messageTwo)):
      typeOne == typeTwo && messageOne == messageTwo
    }
  }
}

// MARK: - ModuleClient + TestDependencyKey

extension ModuleClient: TestDependencyKey {
  public static let testValue = Self(
    initialize: unimplemented(),
    getModule: unimplemented(),
    removeCachedModule: unimplemented(),
    removeCachedModules: unimplemented()
  )
}

extension DependencyValues {
  public var moduleClient: ModuleClient {
    get { self[ModuleClient.self] }
    set { self[ModuleClient.self] = newValue }
  }
}
