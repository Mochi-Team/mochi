//
//  Client+.swift
//
//
//  Created by ErrorErrorError on 11/12/23.
//
//

import Foundation

extension FileClient {
  public func createModuleDirectory(_ url: URL) throws {
    try create(
      self.url(.documentDirectory, .userDomainMask, nil, true)
        .reposDir()
        .appendingPathComponent(url.absoluteString)
    )
  }

  public func retrieveModuleDirectory(_ url: URL) throws -> URL {
    try self.url(.documentDirectory, .userDomainMask, nil, false)
      .reposDir()
      .appendingPathComponent(url.absoluteString)
  }
}

extension URL {
  fileprivate func reposDir() -> URL {
    appendingPathComponent("Repos", isDirectory: true)
  }
}
