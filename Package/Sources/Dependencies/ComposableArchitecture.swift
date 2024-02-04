//
//  ComposableArchitecture.swift
//
//
//  Created by ErrorErrorError on 10/4/23.
//
//

struct ComposableArchitecture: PackageDependency {
    var dependency: Package.Dependency {
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "1.5.6")
    }
}
