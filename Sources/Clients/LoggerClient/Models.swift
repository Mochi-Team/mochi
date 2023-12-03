//
//  Models.swift
//
//
//  Created by ErrorErrorError on 11/29/23.
//  
//

import Combine
import Foundation
import Logging

public struct SystemLogEvent: Equatable, Sendable {
    public let level: Logger.Level
    public let timestamp: Date
    public let message: String

    public static func stubs(count: Int) -> [Self] {
        var arr: [Self] = []
        for i in 0..<count {
            arr.append(.init(level: .critical, timestamp: .init(), message: "\(i)"))
        }
        return arr
    }
}

// swiftlint:disable function_parameter_count
struct ConsumableLogsHandler: LogHandler {
    var metadata = Logger.Metadata()
    var logLevel = Logger.Level.info

    private let lock = NSLock()

    static let event = CurrentValueSubject<[SystemLogEvent], Never>([])

    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        lock.lock()
        defer { lock.unlock() }
        var values = Self.event.value
        values.append(.init(level: level, timestamp: .init(), message: message.description))
        Self.event.send(values)
    }
}
// swiftlint:enable function_parameter_count
