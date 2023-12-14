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
public let logger = Logger(label: "dev.errorerrorerror.mochi.app") { label in
  MultiplexLogHandler([
    StreamLogHandler.standardOutput(label: label),
    ConsumableLogsHandler()
  ])
}

// MARK: - LoggerClient

public struct LoggerClient {
  public var get: () -> [SystemLogEvent]
  public var observe: () -> AsyncStream<[SystemLogEvent]>
}

// MARK: DependencyKey

extension LoggerClient: DependencyKey {
  public static var liveValue: LoggerClient = .init {
    ConsumableLogsHandler.event.value
  } observe: {
    ConsumableLogsHandler.event.values.eraseToStream()
  }
}

extension DependencyValues {
  public var loggerClient: LoggerClient {
    get { self[LoggerClient.self] }
    set { self[LoggerClient.self] = newValue }
  }
}

extension _ReducerPrinter {
  public static func swiftLog<R: Reducer>(_: R.Type = R.self) -> Self where R.State == State, R.Action == Action {
    let logger = Logger(label: .init(describing: R.self))

    return Self { receivedAction, oldState, newState in
      var target = "received action:\n"
      CustomDump.customDump(receivedAction, to: &target, indent: 2)
      target.write("\n")
      target.write(diff(oldState, newState).map { "\($0)\n" } ?? "  (No state changes)\n")
      logger.debug(.init(stringLiteral: target))
    }
  }
}
