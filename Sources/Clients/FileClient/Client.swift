//
//  Client.swift
//
//
//  Created by MochiTeam on 10/6/23.
//
//

import ComposableArchitecture
import Foundation

// MARK: - FileClient

public struct FileClient {
  public let url: @Sendable (
    _ search: FileManager.SearchPathDirectory,
    _ searchMask: FileManager.SearchPathDomainMask,
    _ appropriate: URL?,
    _ create: Bool
  ) throws -> URL
  public let fileExists: @Sendable (_ path: String) -> Bool
  public let create: @Sendable (_ url: URL) throws -> Void
  public let remove: @Sendable (_ url: URL) throws -> Void
  public let observeDirectory: @Sendable (_ url: URL) throws -> AsyncStream<[String]>
}

// MARK: TestDependencyKey

extension FileClient: TestDependencyKey {
  public static var testValue: FileClient = .init(
    url: unimplemented(".url"),
    fileExists: unimplemented(".remove"),
    create: unimplemented(".create"),
    remove: unimplemented(".remove"),
    observeDirectory: unimplemented(".observeDirectory")
  )
}

extension DependencyValues {
  public var fileClient: FileClient {
    get { self[FileClient.self] }
    set { self[FileClient.self] = newValue }
  }
}
