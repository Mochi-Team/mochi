//
//  File.swift
//  
//
//  Created by ErrorErrorError on 4/10/23.
//  
//

import DatabaseClient
import Foundation
@preconcurrency import Semver
import Tagged

@dynamicMemberLookup
public struct Repo: Equatable, Identifiable, Sendable, Decodable {
    public var id: Tagged<Self, URL> { .init(baseURL) }
    public var baseURL: URL
    public var dateAdded: Date
    public var lastRefreshed: Date?
    public var modules: Set<Module>

    public var iconURL: URL? {
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

    var manifest: Manifest

    public init(
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

    public subscript<Value>(dynamicMember dynamicMember: WritableKeyPath<Manifest, Value>) -> Value {
        get { manifest[keyPath: dynamicMember] }
        set { manifest[keyPath: dynamicMember] = newValue }
    }
}

public extension Repo {
    struct Manifest: Equatable, Sendable, Decodable {
        public var name: String
        public var author: String
        public var description: String?
        public var icon: String?

        public init(
            name: String,
            author: String,
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

extension Repo: MORepresentable {
    public static func createEmptyValue() -> Repo {
        .init(
            baseURL: .init(string: "/").unsafelyUnwrapped,
            dateAdded: .init(),
            lastRefreshed: nil,
            manifest: .init(
                name: "",
                author: ""
            ),
            modules: []
        )
    }

    public static var idKeyPath: KeyPath<Repo, URL> = \Self.baseURL
    public static var entityName: String { "CDRepo" }
    public static var attributes: Set<Attribute<Self>> = [
        .init("author", \.author),
        .init("baseURL", \.baseURL),
        .init("dateAdded", \.dateAdded),
        .init("icon", \.icon),
        .init("lastRefreshed", \.lastRefreshed),
        .init("name", \.name),
        .init("repoDescription", \.description),
        .init("modules", \.modules)
    ]
}

@dynamicMemberLookup
public struct Module: Hashable, Identifiable, Sendable, Decodable {
    public var id: Manifest.ID {
        get { manifest.id }
        set { manifest.id = newValue }
    }
    public var binaryModule: Data
    public var installDate: Date

    public var manifest: Manifest

    public init(
        binaryModule: Data,
        installDate: Date,
        manifest: Manifest
    ) {
        self.binaryModule = binaryModule
        self.installDate = installDate
        self.manifest = manifest
    }

    public subscript<Value>(dynamicMember dynamicMember: WritableKeyPath<Manifest, Value>) -> Value {
        get { manifest[keyPath: dynamicMember] }
        set { manifest[keyPath: dynamicMember] = newValue }
    }
}

extension Module {
    public struct Manifest: Hashable, Identifiable, Sendable, Decodable {
        public var id: Tagged<Self, String>
        public var name: String
        public var description: String?
        public var file: String
        public var version: Semver
        public var released: Date
        public var meta: [Meta]
        public var icon: String?

        public func iconURL(repoURL: URL) -> URL? {
            icon.flatMap { URL(string: $0) }
                .flatMap { url in
                    if url.baseURL == nil {
                        return .init(string: url.relativeString, relativeTo: repoURL)
                    } else {
                        return url
                    }
                }
        }

        public init(
            id: Self.ID,
            name: String,
            description: String? = nil,
            file: String,
            version: Semver,
            released: Date,
            meta: [Meta],
            icon: String? = nil
        ) {
            self.id = id
            self.name = name
            self.description = description
            self.file = file
            self.version = version
            self.icon = icon
            self.released = released
            self.meta = meta
        }

        public enum Meta: String, Equatable, Sendable, Codable {
            case video
            case image
            case text
        }
    }
}

extension Module: MORepresentable {
    public static func createEmptyValue() -> Module {
        .init(
            binaryModule: .init(),
            installDate: .init(),
            manifest: .init(
                id: .init(""),
                name: "",
                file: "",
                version: .init(0, 0, 0),
                released: .init(),
                meta: []
            )
        )
    }

    public static var idKeyPath: KeyPath<Self, String> = \Self.id.rawValue
    public static var entityName: String { "CDModule" }
    public static var attributes: Set<Attribute<Self>> = [
        .init("binaryModule", \.binaryModule),
        .init("icon", \.icon),
        .init("id", \.id.rawValue),
        .init("installDate", \.installDate),
        .init("meta", \.meta),
        .init("moduleDescription", \.description),
        .init("name", \.name),
        .init("released", \.released),
        .init("version", \.version)
    ]
}

extension Semver: ConvertableValue {
    public func encode() -> String {
        self.description
    }

    public static func decode(value: String) throws -> Semver {
        try Semver(value)
    }
}

extension [Module.Manifest.Meta]: ConvertableValue {
    public func encode() -> Data {
        (try? JSONEncoder().encode(self)) ?? .init()
    }

    public static func decode(value: Data) throws -> [Element] {
        (try? JSONDecoder().decode(Self.self, from: value)) ?? .init()
    }
}

extension Tagged: ConvertableValue where RawValue: ConvertableValue {}
