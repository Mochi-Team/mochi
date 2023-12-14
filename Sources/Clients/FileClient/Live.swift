//
//  Live.swift
//
//
//  Created by ErrorErrorError on 10/6/23.
//
//

import ComposableArchitecture
import Foundation

// MARK: - FileClient + DependencyKey

extension FileClient: DependencyKey {
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
  }
}

// MARK: - FileManager + Sendable

extension FileManager: @unchecked Sendable {}
