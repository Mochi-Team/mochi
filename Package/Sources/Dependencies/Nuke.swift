//
//  Nuke.swift
//  
//
//  Created by ErrorErrorError on 10/4/23.
//  
//

struct Nuke: PackageDependency {
    static let nukeURL = "https://github.com/kean/Nuke.git"
    static let nukeVersion: Version = "12.1.5"

    var dependency: Package.Dependency {
        .package(url: Self.nukeURL, exact: Self.nukeVersion)
    }
}

struct NukeUI: PackageDependency {
    var dependency: Package.Dependency {
        .package(url: Nuke.nukeURL, exact: Nuke.nukeVersion)
    }
}
