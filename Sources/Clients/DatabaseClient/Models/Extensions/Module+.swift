//
//  Module+.swift
//
//
//  Created by ErrorErrorError on 11/12/23.
//
//

import Foundation
@preconcurrency
import Semver
import Tagged

extension Module {
  public var mainJSFile: URL {
    directory.appendingPathComponent("main")
      .appendingPathExtension("js")
  }
}

// MARK: - Module + Identifiable

extension Module: Identifiable {
  public var id: Manifest.ID {
    get { manifest.id }
    set { manifest.id = newValue }
  }
}

// MARK: - Module.Manifest

extension Module {
  public struct Manifest: Hashable, Identifiable, Sendable, Codable {
    public var id: Tagged<Self, String> = ""
    public var name: String = ""
    public var description: String?
    public var file: String = ""
    public var version: Semver = .init(0, 0, 0)
    public var meta: [Meta] = []
    public var icon: String?

    public func iconURL(repoURL: URL) -> URL? {
      icon.flatMap { URL(string: $0) }
        .flatMap { url in
          if url.baseURL == nil {
            .init(string: url.relativeString, relativeTo: repoURL)
          } else {
            url
          }
        }
    }

    public init(
      id: Self.ID = "",
      name: String = "",
      description: String? = nil,
      file: String = "",
      version: Semver = .init(0, 0, 0),
      meta: [Meta] = [],
      icon: String? = nil
    ) {
      self.id = id
      self.name = name
      self.description = description
      self.file = file
      self.version = version
      self.icon = icon
      self.meta = meta
    }

    public enum Meta: String, Equatable, Sendable, Codable {
      case video
      case image
      case text
    }
  }

  public subscript<Value>(dynamicMember dynamicMember: WritableKeyPath<Manifest, Value>) -> Value {
    get { manifest[keyPath: dynamicMember] }
    set { manifest[keyPath: dynamicMember] = newValue }
  }
}

// MARK: - Semver + TransformableValue

extension Semver: TransformableValue {
  public func encode() throws -> String { description }
  public static func decode(value: String) throws -> Semver { try Semver(value) }
}

// MARK: - TransformableValue + TransformableValue

extension [Module.Manifest.Meta]: TransformableValue {
  public func encode() throws -> Data { try JSONEncoder().encode(self) }
  public static func decode(value: Data) throws -> [Element] { try JSONDecoder().decode(Self.self, from: value) }
}

// MARK: - Module.Manifest + TransformableValue

extension Module.Manifest: TransformableValue {
  public func encode() throws -> Data { try JSONEncoder().encode(self) }
  public static func decode(value: Data) throws -> Module.Manifest { try JSONDecoder().decode(Self.self, from: value) }
}

// MARK: - Tagged + TransformableValue

extension Tagged: TransformableValue where RawValue: TransformableValue {}
