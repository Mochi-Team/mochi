//
//  Live.swift
//
//
//  Created by ErrorErrorError on 10/6/23.
//
//

import ComposableArchitecture
import Foundation

extension FileClient: DependencyKey {
    public static var liveValue: FileClient = {
        let documentDirectory: URL = if let document = try? FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) {
            document
        } else {
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        }

        let reposDirectory = documentDirectory.appendingPathComponent("Repos", isDirectory: true)

        let create: (URL) throws -> Void = { url in
            if !FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true)
            }
        }

        return Self(
            createModuleFolder: { path in
                let url = documentDirectory.appendingPathComponent("Repos", isDirectory: true).appendingPathComponent(path, isDirectory: true)
                try create(url)
                return url
            },
            retrieveModuleFolder: { documentDirectory.appendingPathComponent("Repos", isDirectory: true).appendingPathComponent($0.relativePath) }
        )
    }()
}
