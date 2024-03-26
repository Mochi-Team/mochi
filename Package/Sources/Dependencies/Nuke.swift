//
//  Nuke.swift
//
//
//  Created by ErrorErrorError on 10/4/23.
//
//

// MARK: - Nuke

struct Nuke: PackageDependency {
    static let nukeURL = "https://github.com/kean/Nuke.git"
    static let nukeVersion: Version = "12.1.6"

    var dependency: Package.Dependency {
        .package(url: Self.nukeURL, exact: Self.nukeVersion)
    }
}

// MARK: - NukeUI

struct NukeUI: PackageDependency {
    var dependency: Package.Dependency {
        .package(url: Nuke.nukeURL, exact: Nuke.nukeVersion)
    }
}
