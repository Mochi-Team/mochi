//
//  Logger.swift
//
//
//  Created by ErrorErrorError on 11/29/23.
//
//

import Combine
import Dependencies
import FileClient
import Foundation
import LoggerClient
import Parsing
import SharedModels

// MARK: - ModuleLoggerLevel

public enum ModuleLoggerLevel: String, CaseIterable, Sendable, Equatable {
  case log
  case info
  case debug
  case warn
  case error

  init(rawValueWithDefault: String) {
    self = Self(rawValue: rawValueWithDefault) ?? .log
  }
}

// MARK: - ModuleLoggerEventParser

struct ModuleLoggerEventParser: ParserPrinter {
  let id: RepoModuleID

  @ParserBuilder<Substring> var body: some ParserPrinter<Substring.UTF8View, ModuleLoggerEvent> {
    ParsePrint(.memberwise(ModuleLoggerEvent.init(timestamp:level:body:))) {
      ParsePrint(.memberwise(Date.init(timeIntervalSince1970:))) {
        Double.parser()
      }
      ": ".utf8
      Skip { PrefixUpTo(" ".utf8) }
        .printing("".utf8)
      " [".utf8
      ModuleLoggerLevel.parser()
      "] ".utf8
      Rest()
        .map(.string)
    }
  }
}

// MARK: - ModuleLoggerEvent

public struct ModuleLoggerEvent: Equatable, Sendable, Parser {
  public let timestamp: Date
  public let level: ModuleLoggerLevel
  public let body: String

  init(
    timestamp: Date = .init(),
    level: ModuleLoggerLevel,
    body: String
  ) {
    self.timestamp = timestamp
    self.level = level
    self.body = body
  }
}

// MARK: - ModuleLogger

final class ModuleLogger {
  let id: RepoModuleID

  let events: CurrentValueSubject<[ModuleLoggerEvent], Never>

  private let logFileURL: URL
  private let queue: DispatchQueue

  @Dependency(\.fileClient) var fileClient

  init(
    id: RepoModuleID,
    directory: URL
  ) throws {
    self.id = id
    self.queue = .init(label: "\(id.description)-logger")

    @Dependency(\.fileClient) var fileClient

    self.logFileURL = try fileClient.retrieveModuleDirectory(directory)
      .appendingPathComponent("logs")
      .appendingPathExtension("log")

    if !fileClient.fileExists(logFileURL.absoluteString) {
      try Data().write(to: logFileURL)
    }

    // This is per session, not per file
    self.events = .init([])
  }

  func log(_ msg: String) {
    append(.init(level: .log, body: msg))
  }

  func debug(_ msg: String) {
    append(.init(level: .debug, body: msg))
  }

  func error(_ msg: String) {
    append(.init(level: .error, body: msg))
  }

  func info(_ msg: String) {
    append(.init(level: .info, body: msg))
  }

  func warn(_ msg: String) {
    append(.init(level: .warn, body: msg))
  }

  private func append(_ event: ModuleLoggerEvent) {
    let parser = ModuleLoggerEventParser(id: id)
    queue.async { [id, logFileURL, weak self] in
      self?.events.withValue { $0.append(event) }
      do {
        let msgString = try parser.print(event)
        let handle = try FileHandle(forWritingTo: logFileURL)
        defer {
          try? handle.synchronize()
          try? handle.close()
        }
        try handle.seekToEnd()
        try handle.write(contentsOf: [UInt8](msgString))
        try handle.seekToEnd()
        try handle.write(contentsOf: [UInt8]("\n".utf8))
      } catch {
        logger.error("Failed to log message for \(id.description). Error: \(error)")
      }
    }
  }
}

extension CurrentValueSubject {
  @inlinable
  func withValue<T>(_ callback: @escaping (inout Output) -> T) -> T {
    var currentValue = value
    let returnValue = callback(&currentValue)
    send(currentValue)
    return returnValue
  }
}
