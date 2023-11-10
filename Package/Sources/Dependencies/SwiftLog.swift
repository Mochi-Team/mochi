//
//  File.swift
//  
//
//  Created by ErrorErrorError on 11/9/23.
//  
//

struct SwiftLog: PackageDependency {
    var name: String { "swift-log" }

    var dependency: Package.Dependency {
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    }
}

struct Logging: Dependency {
    var targetDepenency: _PackageDescription_TargetDependency {
        .product(name: "\(Self.self)", package: SwiftLog().packageName)
    }
}
