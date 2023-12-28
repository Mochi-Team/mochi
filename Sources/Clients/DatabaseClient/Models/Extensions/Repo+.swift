//
//  Repo+.swift
//
//
//  Created by ErrorErrorError on 12/28/23.
//
//

import Foundation
import Tagged

// MARK: - Repo + Identifiable

extension Repo: Identifiable {
  public var id: Tagged<Self, URL> { .init(remoteURL) }
}

extension Repo {
  public var iconURL: URL? {
    manifest.icon.flatMap { URL(string: $0) }
      .flatMap { url in
        if url.baseURL == nil {
          .init(string: url.relativeString, relativeTo: remoteURL)
        } else {
          url
        }
      }
  }
}

extension Repo {
  public struct Manifest: Equatable, Sendable, Codable, TransformableValue {
    public var name: String
    public var author: String
    public var description: String?
    public var icon: String?

    public init(
      name: String = "",
      author: String = "",
      description: String? = nil,
      icon: String? = nil
    ) {
      self.name = name
      self.author = author
      self.description = description
      self.icon = icon
    }

    public func encode() throws -> Data {
      try JSONEncoder().encode(self)
    }

    public static func decode(value: Data) throws -> Repo.Manifest {
      try JSONDecoder().decode(Self.self, from: value)
    }
  }

  public subscript<Value>(dynamicMember dynamicMember: WritableKeyPath<Manifest, Value>) -> Value {
    get { manifest[keyPath: dynamicMember] }
    set { manifest[keyPath: dynamicMember] = newValue }
  }
}
