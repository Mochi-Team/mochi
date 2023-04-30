//
//  File.swift
//  
//
//  Created by ErrorErrorError on 4/10/23.
//  
//

import Foundation
import Tagged

@dynamicMemberLookup
public struct Repo: Equatable, Identifiable, Sendable, Decodable {
    public var id: Manifest.ID { manifest.id }
    public let repoURL: URL

    let manifest: Manifest

    public init(
        repoURL: URL,
        manifest: Repo.Manifest
    ) {
        self.repoURL = repoURL
        self.manifest = manifest
    }

    public subscript<Value>(dynamicMember dynamicMember: KeyPath<Manifest, Value>) -> Value {
        manifest[keyPath: dynamicMember]
    }
}

public extension Repo {
    struct Manifest: Equatable, Identifiable, Sendable, Decodable {
        public let id: Tagged<Self, String>
        public let name: String
        public let author: String
        public let description: String?
        public let icon: URL?
        public var modules: [Module.Manifest] = []

        public init(
            id: Tagged<Self, String>,
            name: String,
            author: String,
            description: String? = nil,
            icon: URL? = nil,
            modules: [Module.Manifest] = []
        ) {
            self.id = id
            self.name = name
            self.author = author
            self.description = description
            self.icon = icon
            self.modules = modules
        }
    }
}

@dynamicMemberLookup
public struct Module: Equatable, Identifiable, Sendable, Decodable {
    public var id: Manifest.ID { manifest.id }
    public let binaryModule: Data
    public let installDate: Date

    let manifest: Manifest

    public init(
        binaryModule: Data,
        installDate: Date,
        manifest: Manifest
    ) {
        self.binaryModule = binaryModule
        self.installDate = installDate
        self.manifest = manifest
    }

    public subscript<Value>(dynamicMember dynamicMember: KeyPath<Manifest, Value>) -> Value {
        manifest[keyPath: dynamicMember]
    }
}

extension Module {
    public struct Manifest: Equatable, Identifiable, Sendable, Decodable {
        public let id: Tagged<Self, String>
        public let name: String
        public let icon: URL?
        public let version: String
        public let released: Date

        public init(
            id: Tagged<Self, String>,
            name: String,
            icon: URL? = nil,
            version: String,
            released: Date
        ) {
            self.id = id
            self.name = name
            self.icon = icon
            self.version = version
            self.released = released
        }
    }
}
