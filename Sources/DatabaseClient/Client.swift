//
//  Client.swift
//  
//
//  Created ErrorErrorError on 4/8/23.
//  Copyright © 2023. All rights reserved.
//

import Dependencies
import Foundation
import XCTestDynamicOverlay

public struct DatabaseClient: Sendable {
    // TODO: Add client interface types
}

extension DatabaseClient: TestDependencyKey {
    public static var testValue: Self {
        .init()
    }
}

extension DependencyValues {
    public var database: DatabaseClient {
        get { self[DatabaseClient.self] }
        set { self[DatabaseClient.self] = newValue }
    }
}
