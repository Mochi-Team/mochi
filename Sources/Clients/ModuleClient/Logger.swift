//
//  ModuleLogger.swift
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
import SharedModels

public enum ModuleLoggerLevel: String, CaseIterable, Sendable, Equatable {
    case log
    case info
    case debug
    case warn
    case error
}

public struct ModuleLoggerEvent: Equatable, Sendable {
    public let level: ModuleLoggerLevel
    public let timestamp: Date = .init()
    public let body: String
}

final class ModuleLogger {
    let id: RepoModuleID

    let events: CurrentValueSubject<[ModuleLoggerEvent], Never>

    private let logFileURL: URL
    private let queue: DispatchQueue

    @Dependency(\.fileClient)
    var fileClient

    init(
        id: RepoModuleID,
        directory: URL
    ) throws {
        self.id = id
        self.queue = .init(label: "\(id.description)-logger")

        @Dependency(\.fileClient)
        var fileClient

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
        queue.async { [id, logFileURL, weak self] in
            self?.events.withValue { $0.append(event) }
            let msgString = "\(event.timestamp.timeIntervalSince1970): \(id.description) [\(event.level.rawValue)] \(event.body)\n"
            do {
                let handle = try FileHandle(forWritingTo: logFileURL)
                defer {
                    try? handle.synchronize()
                    try? handle.close()
                }
                try handle.seekToEnd()
                try handle.write(contentsOf: msgString.data(using: .utf8) ?? .init())
            } catch {
                logger.error("Failed to log message for \(id.description). Error: \(error.localizedDescription)")
            }
        }
    }
}

extension CurrentValueSubject {
    @inlinable
    func withValue<T>(_ callback: @escaping (inout Output) -> T) -> T {
        var currentValue = self.value
        let returnValue = callback(&currentValue)
        self.send(currentValue)
        return returnValue
    }
}
