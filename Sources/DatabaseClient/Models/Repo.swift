//
//  Repo.swift
//
//
//  Created by ErrorErrorError on 4/10/23.
//
//

import Foundation
import Tagged

@dynamicMemberLookup
public struct Repo: Entity, Equatable, Sendable {
    public var remoteURL: URL = .init(string: "/").unsafelyUnwrapped
    public var manifest: Manifest = .init()
    public var modules: Set<Module> = []

    public var objectID: ManagedObjectID?

    public static var properties: Set<Property<Self>> = [
        .init("remoteURL", \.remoteURL),
        .init("manifest", \.manifest),
        .init("modules", \.modules)
    ]

    public init() {}
}

public extension Repo {
    init(
        remoteURL: URL,
        manifest: Repo.Manifest,
        modules: Set<Module> = []
    ) {
        self.remoteURL = remoteURL
        self.manifest = manifest
        self.modules = modules
    }
}

// MARK: Identifiable

extension Repo: Identifiable {
    public var id: Tagged<Self, URL> { .init(remoteURL) }
}

public extension Repo {
    var iconURL: URL? {
        manifest.icon
            .flatMap { URL(string: $0) }
            .flatMap { url in
                if url.baseURL == nil {
                    return .init(string: url.relativeString, relativeTo: remoteURL)
                } else {
                    return url
                }
            }
    }
}

public extension Repo {
    subscript<Value>(dynamicMember dynamicMember: WritableKeyPath<Manifest, Value>) -> Value {
        get { manifest[keyPath: dynamicMember] }
        set { manifest[keyPath: dynamicMember] = newValue }
    }

    struct Manifest: Equatable, Sendable, Codable {
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
    }
}

// MARK: - Repo.Manifest + TransformableValue

extension Repo.Manifest: TransformableValue {
    public func encode() throws -> Data {
        try JSONEncoder().encode(self)
    }

    public static func decode(value: Data) throws -> Repo.Manifest {
        try JSONDecoder().decode(Self.self, from: value)
    }
}
