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
import WasmInterpreter
import XCTestDynamicOverlay

// MARK: - ModuleClient

public struct ModuleClient: Sendable {
    public var initialize: @Sendable () async throws -> Void
    var getModule: @Sendable (_ repoModuleID: RepoModuleID) async throws -> ModuleHandler
}

public extension ModuleClient {
    func withModule<R>(id: RepoModuleID, work: @Sendable (ModuleHandler) async throws -> R) async throws -> R {
        try await work(getModule(id))
    }
}

// MARK: ModuleClient.Error

public extension ModuleClient {
    enum Error: Swift.Error, Equatable, Sendable {
        case wasm3(WasmInstance.Error)
        case nullPtr(for: String = #function, message: String = "")
        case castError(for: String = #function, got: String = "", expected: String = "")
        case swiftSoup(for: String = #function, SwiftSoup.Exception)
        case indexOutOfBounds(for: String = #function)
        case unknown(for: String = #function, msg: String = "")
        case moduleNotFound
    }
}

// MARK: - SwiftSoup.Exception + Equatable

extension SwiftSoup.Exception: Equatable {
    public static func == (lhs: Exception, rhs: Exception) -> Bool {
        switch (lhs, rhs) {
        case let (.Error(typeOne, messageOne), .Error(typeTwo, messageTwo)):
            return typeOne == typeTwo && messageOne == messageTwo
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
