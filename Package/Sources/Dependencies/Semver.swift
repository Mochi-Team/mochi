//
//  Semver.swift
//
//
//  Created by ErrorErrorError on 10/4/23.
//
//

struct Semver: PackageDependency {
    var dependency: Package.Dependency {
        .package(url: "https://github.com/kutchie-pelaez/Semver.git", exact: "1.0.0")
    }
}
