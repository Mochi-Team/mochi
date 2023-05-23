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

public struct AnalyticsClient: Sendable {
    public var sendAnalytics: @Sendable (Action) -> Void
}

extension AnalyticsClient: TestDependencyKey {
    public static let testValue = Self(
        sendAnalytics: unimplemented()
    )
}

extension DependencyValues {
    public var analyticsClient: AnalyticsClient {
        get { self[AnalyticsClient.self] }
        set { self[AnalyticsClient.self] = newValue }
    }
}
