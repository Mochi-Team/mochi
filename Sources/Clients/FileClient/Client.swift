//
//  Client.swift
//
//
//  Created by ErrorErrorError on 10/6/23.
//
//

import ComposableArchitecture
import Foundation

// MARK: - FileClient

public struct FileClient {
    public let url: @Sendable (FileManager.SearchPathDirectory, FileManager.SearchPathDomainMask, URL?, Bool) throws -> URL
    public let fileExists: @Sendable (String) -> Bool
    public let create: @Sendable (URL) throws -> Void
    public let remove: @Sendable (URL) throws -> Void
}

// MARK: TestDependencyKey

extension FileClient: TestDependencyKey {
    public static var testValue: FileClient = .init(
        url: unimplemented(".url"),
        fileExists: unimplemented(".remove"),
        create: unimplemented(".create"),
        remove: unimplemented(".remove")
    )
}

public extension DependencyValues {
    var fileClient: FileClient {
        get { self[FileClient.self] }
        set { self[FileClient.self] = newValue }
    }
}
