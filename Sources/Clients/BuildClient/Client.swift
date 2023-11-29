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

// MARK: TestDependencyKey

public struct BuildKey: DependencyKey {
    public static let testValue = Build(
        version: .init(0, 0, 0),
        number: 0
    )

    public static let liveValue = Build(
        version: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
            .flatMap { $0 as? String }
            .flatMap { try? Semver($0) } ?? .init(0, 0, 0),
        number: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")
            .flatMap { $0 as? Int }
            .flatMap { .init(rawValue: $0) } ?? .init(0)
    )
}

public extension DependencyValues {
    var build: Build {
        get { self[BuildKey.self] }
        set { self[BuildKey.self] = newValue }
    }
}
