//
//  SwiftUIBackports.swift
//
//
//  Created by ErrorErrorError on 10/4/23.
//
//

struct SwiftUIBackports: PackageDependency {
    var dependency: Package.Dependency {
        .package(url: "https://github.com/shaps80/SwiftUIBackports.git", .upToNextMajor(from: "2.0.0"))
    }
}
