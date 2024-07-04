//
//  Client+.swift
//
//
//  Created by MochiTeam on 11/12/23.
//
//

import Foundation
import SharedModels

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
  
  private func createDirectory(_ root: String, _ directory: String) throws -> URL {
    var folderPath = try self.url(.documentDirectory, .userDomainMask, nil, true)
      .LibraryDir()
    if (!fileExists(folderPath.path)) {
      try create(folderPath)
    }
    folderPath = folderPath.appendingPathComponent(root)
    if (!fileExists(folderPath.path)) {
      try create(folderPath)
    }
    folderPath = folderPath.appendingPathComponent(directory)
    if (!fileExists(folderPath.path)) {
      try create(folderPath)
    }
    return folderPath
  }
  
  public func shouldCreateLibraryDirectory<T: Encodable>(_ root: LibraryDirectory, _ directory: String, _ metadata: T) throws {
    let folderPath = try createDirectory(root.rawValue, directory)
    let metadataPath = folderPath.appendingPathComponent("metadata.json")
    //    if !fileExists(metadataPath.path) {
    try JSONEncoder().encode(metadata).write(to: metadataPath)
    //    }
  }
  public func shouldCreateLibraryDirectory(_ root: LibraryDirectory, _ directory: String) throws {
    let _ = try createDirectory(root.rawValue, directory)
  }
  
  public func initializeLibrary() throws {
    var folderPath = try self.url(.documentDirectory, .userDomainMask, nil, true)
      .LibraryDir()
    if (!fileExists(folderPath.path)) {
      try create(folderPath)
    }
    if (!fileExists(folderPath.appendingPathComponent(LibraryDirectory.playlistCache.rawValue).path)) {
      try create(folderPath.appendingPathComponent(LibraryDirectory.playlistCache.rawValue))
    }
    if (!fileExists(folderPath.appendingPathComponent(LibraryDirectory.downloaded.rawValue).path)) {
      try create(folderPath.appendingPathComponent(LibraryDirectory.downloaded.rawValue))
    }
  }
  
  public func retrieveLibraryDirectory() throws -> URL {
    return try self.url(.documentDirectory, .userDomainMask, nil, false)
    .LibraryDir()
  }
  public func retrieveLibraryDirectory(root: LibraryDirectory, playlist: String? = nil, episode: String? = nil) throws -> URL {
    var url = try self.url(.documentDirectory, .userDomainMask, nil, false)
    .LibraryDir()
    .appendingPathComponent(root.rawValue)
    if let playlist = playlist {
      url = url.appendingPathComponent(playlist.sanitized)
    }
    if let episode = episode {
      url = url.appendingPathComponent(episode.sanitized)
    }
    return url
  }
  
  public func removePlaylistFromLibrary(_ root: LibraryDirectory, _ playlist: String, _ episode: String? = nil) throws {
    var url = try self.url(.documentDirectory, .userDomainMask, nil, false)
    .LibraryDir()
    .appendingPathComponent(root.rawValue)
    .appendingPathComponent(playlist.sanitized)
    
    if let episode = episode {
      url = url.appendingPathComponent(episode.sanitized)
    }
    
    if (fileExists(url.path)) {
      try remove(url)
    }
  }
  
  public func getLibraryPlaylistImage(playlist: String) -> URL? {
     return try? self.url(.documentDirectory, .userDomainMask, nil, false)
      .LibraryDir()
      .appendingPathComponent(LibraryDirectory.playlistCache.rawValue)
      .appendingPathComponent(playlist.sanitized)
      .appendingPathComponent("posterImage.jpeg")
  }
  
  public func libraryEpisodeExists(folder: String, file: String) -> Bool {
    guard let url = try? self.url(.documentDirectory, .userDomainMask, nil, false)
      .LibraryDir()
      .appendingPathComponent(LibraryDirectory.downloaded.rawValue)
      .appendingPathComponent(folder.sanitized)
      .appendingPathComponent(file.sanitized)
        .appendingPathComponent("data")
        .appendingPathExtension("movpkg") else {
      return false
    }
    return fileExists(url.path)
  }
  
  public func retrieveLibraryMetadata(root: LibraryDirectory, playlist: String, episode: String? = nil) throws -> Data? {
    var url = try self.url(.documentDirectory, .userDomainMask, nil, false)
    .LibraryDir()
    .appendingPathComponent(root.rawValue)
    .appendingPathComponent(playlist.sanitized)
    if let episode = episode {
      url = url.appendingPathComponent(episode.sanitized)
    }
    return FileManager.default.contents(atPath: url.appendingPathComponent("metadata.json").relativePath)
  }
  public func retrieveLibraryMetadata(root: LibraryDirectory, encodedPlaylist: String, episode: String? = nil) throws -> Data? {
    var url = try self.url(.documentDirectory, .userDomainMask, nil, false)
    .LibraryDir()
    .appendingPathComponent(root.rawValue)
    .appendingPathComponent(encodedPlaylist)
    if let episode = episode {
      url = url.appendingPathComponent(episode.sanitized)
    }
    return FileManager.default.contents(atPath: url.appendingPathComponent("metadata.json").relativePath)
  }
}

extension URL {
  fileprivate func reposDir() -> URL {
    appendingPathComponent("Repos", isDirectory: true)
  }
  fileprivate func LibraryDir() -> URL {
    appendingPathComponent("Library", isDirectory: true)
  }
}

extension String {
  var sanitized: String {
    replacingOccurrences(of: "/", with: "\\")
  }
}
