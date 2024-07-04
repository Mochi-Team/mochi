//
//  Live.swift
//
//
//  Created by MochiTeam on 10/6/23.
//
//

import ComposableArchitecture
import Foundation
import CoreData

// MARK: - FileClient + DependencyKey

extension FileClient: DependencyKey {
  public enum Error: Swift.Error {
    case FileNotFound
  }

  public static var liveValue: FileClient = Self { searchPathDir, mask, url, create in
    try FileManager.default.url(
      for: searchPathDir,
      in: mask,
      appropriateFor: url,
      create: create
    )
  } fileExists: { path in
    FileManager.default.fileExists(atPath: path)
  } create: { url in
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
  } remove: { url in
    try FileManager.default.removeItem(at: url)
  } observeDirectory: { url in
    let monitoredDirectoryFileDescriptor = open((url as NSURL).fileSystemRepresentation, O_EVTONLY)
    if monitoredDirectoryFileDescriptor == -1 {
      throw Error.FileNotFound
    }
    let directoryMonitorQueue =  DispatchQueue(label: "directorymonitor", attributes: .concurrent)
    let directoryMonitorSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: monitoredDirectoryFileDescriptor, eventMask: DispatchSource.FileSystemEvent.write, queue: directoryMonitorQueue) as? DispatchSource
    return .init { continuation in
      let values = try? FileManager.default.contentsOfDirectory(atPath: url.path)
      continuation.yield(values ?? [])
      directoryMonitorSource?.setEventHandler {
        let values = try? FileManager.default.contentsOfDirectory(atPath: url.path)
        continuation.yield(values ?? [])
      }
      directoryMonitorSource?.resume()
      
      continuation.onTermination = { _ in
        directoryMonitorSource?.cancel()
      }
    }
  }
}

// MARK: - FileManager + Sendable

extension FileManager: @unchecked Sendable {}
