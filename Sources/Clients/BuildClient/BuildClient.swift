//
//  BuildClient.swift
//
//
//  Created by ErrorErrorError on 7/28/23.
//
//

import Dependencies
import Foundation
import Semver

// MARK: - BuildClient

public struct BuildClient {
    public let version: Semver
    public let buildNumber: Int
}

// MARK: TestDependencyKey

extension BuildClient: TestDependencyKey {
    public static var testValue: BuildClient = .init(
        version: .init(0, 0, 0),
        buildNumber: 1
    )
}

public extension DependencyValues {
    var build: BuildClient {
        get { self[BuildClient.self] }
        set { self[BuildClient.self] = newValue }
    }
}

// MARK: - BuildClient + DependencyKey

extension BuildClient: DependencyKey {
    public static var liveValue: BuildClient {
        .init(
            version: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
                .flatMap { $0 as? String }
                .flatMap { try? Semver($0) } ?? .init(0, 0, 0),
            buildNumber: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")
                .flatMap { $0 as? Int } ?? 0
        )
    }
}
