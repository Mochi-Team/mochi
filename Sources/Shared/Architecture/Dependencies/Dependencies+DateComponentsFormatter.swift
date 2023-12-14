//
//  Dependencies+DateComponentsFormatter.swift
//
//
//  Created by ErrorErrorError on 6/11/23.
//
//

import ComposableArchitecture
import Foundation

// MARK: - DateComponentsFormatterClient

public struct DateComponentsFormatterClient {
  let formatter: @Sendable () -> DateComponentsFormatter
}

extension DateComponentsFormatterClient {
  private static let lock = NSRecursiveLock()

  public func withFormatter<V>(_ callback: @Sendable (DateComponentsFormatter) -> V) -> V {
    Self.lock.lock()
    defer { Self.lock.unlock() }
    return callback(formatter())
  }
}

// MARK: DependencyKey

extension DateComponentsFormatterClient: DependencyKey {
  public static let liveValue: DateComponentsFormatterClient = {
    let formatter = DateComponentsFormatter()
    return .init { formatter }
  }()
}

extension DependencyValues {
  public var dateComponentsFormatter: DateComponentsFormatterClient {
    get { self[DateComponentsFormatterClient.self] }
    set { self[DateComponentsFormatterClient.self] = newValue }
  }
}
