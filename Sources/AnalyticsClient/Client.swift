//
//  Client.swift
//
//
//  Created ErrorErrorError on 5/19/23.
//  Copyright © 2023. All rights reserved.
//

import Dependencies
import Foundation
import XCTestDynamicOverlay

// MARK: - AnalyticsClient

public struct AnalyticsClient: Sendable {
    public var sendAnalytics: @Sendable (Action) -> Void
}

// MARK: TestDependencyKey

extension AnalyticsClient: TestDependencyKey {
    public static let testValue = Self(
        sendAnalytics: unimplemented()
    )
}

public extension DependencyValues {
    var analyticsClient: AnalyticsClient {
        get { self[AnalyticsClient.self] }
        set { self[AnalyticsClient.self] = newValue }
    }
}
