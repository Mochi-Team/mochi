//
//  FlyingFox.swift
//  
//
//  Created by MochiTeam on 09.05.2024.
//

import Foundation

struct FlyingFox: PackageDependency {
    var dependency: Package.Dependency {
        .package(url: "https://github.com/swhitty/FlyingFox.git", .upToNextMajor(from: "0.14.0"))
    }
}
