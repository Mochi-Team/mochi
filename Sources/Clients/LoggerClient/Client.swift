//
//  Client.swift
//
//
//  Created ErrorErrorError on 5/30/23.
//  Copyright © 2023. All rights reserved.
//

import Dependencies
import Foundation
import OSLog
import XCTestDynamicOverlay

// MARK: - LoggerClientKey

public struct LoggerClientKey: DependencyKey {
    public static var previewValue = Logger(category: "preview")
    public static var liveValue = Logger()
    public static let testValue = Logger(category: "test")
}

public extension DependencyValues {
    var logger: Logger {
        get { self[LoggerClientKey.self] }
        set { self[LoggerClientKey.self] = newValue }
    }
}

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier.unsafelyUnwrapped

    init(category: String) {
        self.init(subsystem: Self.subsystem, category: category)
    }
}
