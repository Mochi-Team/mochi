//
//  Repo.swift
//
//
//  Created by ErrorErrorError on 4/10/23.
//
//

import CoreORM
import Foundation
import Tagged

// MARK: - Repo

@dynamicMemberLookup
public struct Repo: Entity, Equatable, Sendable {
    @Attribute
    public var baseURL: URL = .init(string: "/").unsafelyUnwrapped

    @Attribute
    public var dateAdded: Date = .init()

    @Attribute
    public var lastRefreshed: Date? = .init()

    @Attribute
    public var manifest: Manifest = .init()

    @Relation
    public var modules: Set<Module> = []

    public init() {}
}

public extension Repo {
    init(
        baseURL: URL,
        dateAdded: Date,
        lastRefreshed: Date?,
        manifest: Repo.Manifest,
        modules: Set<Module> = []
    ) {
        self.baseURL = baseURL
        self.dateAdded = dateAdded
        self.lastRefreshed = lastRefreshed
        self.manifest = manifest
        self.modules = modules
    }
}

// MARK: Identifiable

extension Repo: Identifiable {
    public var id: Tagged<Self, URL> { .init(baseURL) }
}

public extension Repo {
    var iconURL: URL? {
        manifest.icon
            .flatMap { URL(string: $0) }
            .flatMap { url in
                if url.baseURL == nil {
                    return .init(string: url.relativeString, relativeTo: baseURL)
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
    public func encode() -> Data {
        (try? JSONEncoder().encode(self)) ?? .init()
    }

    public static func decode(value: Data) throws -> Repo.Manifest {
        try JSONDecoder().decode(Self.self, from: value)
    }
}
