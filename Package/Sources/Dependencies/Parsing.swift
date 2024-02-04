//
//  Parsing.swift
//
//
//  Created by ErrorErrorError on 12/17/23.
//
//

struct Parsing: PackageDependency {
    var dependency: Package.Dependency {
        .package(url: "https://github.com/pointfreeco/swift-parsing", exact: "0.13.0")
    }
}
