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
    var getModule: @Sendable (_ repoModuleID: RepoModuleID) async throws -> Self.Instance
}

public extension ModuleClient {
    func withModule<R>(id: RepoModuleID, work: @Sendable (Self.Instance) async throws -> R) async throws -> R {
        try await work(getModule(id))
    }
}

// MARK: ModuleClient.Error

public extension ModuleClient {
    enum Error: Swift.Error, Equatable, Sendable {
        case client(ClientError)
        case jsRuntime(JSRuntimeError)
    }
}

public extension ModuleClient.Error {
    enum ClientError: Equatable, Sendable {
        case moduleNotFound
    }
}

public extension ModuleClient.Error {
    enum JSRuntimeError: Equatable, Sendable {
        case promiseValueError
        case retrievingInstanceFailed
        case instanceCreationFailed
        case instanceCall(function: String, msg: String)
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
        getModule: unimplemented()
    )
}

public extension DependencyValues {
    var moduleClient: ModuleClient {
        get { self[ModuleClient.self] }
        set { self[ModuleClient.self] = newValue }
    }
}
