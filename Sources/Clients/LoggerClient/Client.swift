//
//  Client.swift
//
//
//  Created ErrorErrorError on 5/30/23.
//  Copyright © 2023. All rights reserved.
//

import ComposableArchitecture
import Dependencies
import Foundation
import Logging
import XCTestDynamicOverlay

// Global App Logger
public let logger = Logger(label: "dev.errorerrorerror.mochi.app")

// TODO: Allow viewing logs using logger client
public struct LoggerClient {}

// MARK: - LoggerClientKey

extension DependencyValues {
    var logger: Logger {
        get { self[Logger.self] }
        set { self[Logger.self] = newValue }
    }
}

extension Logger: DependencyKey {
    public static var previewValue: Logger { Logger(label: "debug") }
    public static var testValue: Logger { Logger(label: "test") }
    public static var liveValue: Logger { logger }
}

extension Logger {
    // TODO: Add support for viewing logs when toggled. This should stay in memory only.
    subscript<T: Reducer>(reducer reducer: T.Type) -> Logger {
        .init(label: String(describing: reducer))
    }
}

public extension _ReducerPrinter {
    static func swiftLogger<R: Reducer>(_ reducerType: R.Type = R.self) -> Self where R.State == State, R.Action == Action {
        Self { receivedAction, oldState, newState in
            var target = ""
            target.write("received action:\n")
            CustomDump.customDump(receivedAction, to: &target, indent: 2)
            target.write("\n")
            target.write(diff(oldState, newState).map { "\($0)\n" } ?? "  (No state changes)\n")
            @Dependency(\.logger)
            var logger
            logger[reducer: reducerType].debug(.init(stringLiteral: target))
        }
    }
}
