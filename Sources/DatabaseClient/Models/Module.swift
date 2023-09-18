//
//  Module.swift
//
//
//  Created by ErrorErrorError on 5/17/23.
//
//

import CoreData
import Foundation
@preconcurrency
import Semver
import Tagged

public struct Module: Entity, Hashable, Sendable {
//    @Attribute("moduleLocation", \.moduleLocation)
    public var moduleLocation: URL = .init(string: "/").unsafelyUnwrapped

//    @Attribute("installDate", \.installDate)
    public var installDate: Date = .init()

//    @Attribute("manifest", \.manifest)
    public var manifest: Manifest = .init()

    public var objectID: NSManagedObjectID?

    public static var properties: Set<Property> = [
        .init("moduleLocation", \Self.moduleLocation),
        .init("installDate", \Self.installDate),
        .init("manifest", \Self.manifest)
    ]

    public init() {}
}

// MARK: Identifiable

extension Module: Identifiable {
    public var id: Manifest.ID {
        get { manifest.id }
        set { manifest.id = newValue }
    }
}

public extension Module {
    init(
        moduleLocation: URL,
        installDate: Date,
        manifest: Module.Manifest
    ) {
        self.moduleLocation = moduleLocation
        self.installDate = installDate
        self.manifest = manifest
    }

    subscript<Value>(dynamicMember dynamicMember: WritableKeyPath<Manifest, Value>) -> Value {
        get { manifest[keyPath: dynamicMember] }
        set { manifest[keyPath: dynamicMember] = newValue }
    }
}

// MARK: Module.Manifest

public extension Module {
    struct Manifest: Hashable, Identifiable, Sendable, Codable {
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
            id: Self.ID = "",
            name: String = "",
            description: String? = nil,
            file: String = "",
            version: Semver = .init(0, 0, 0),
            released: Date = .init(),
            meta: [Meta] = [],
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
