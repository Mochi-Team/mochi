//
//  SwiftLog.swift
//
//
//  Created by ErrorErrorError on 11/9/23.
//
//

// MARK: - SwiftLog

struct SwiftLog: PackageDependency {
    var name: String { "swift-log" }
    var productName: String { "swift-log" }

    var dependency: Package.Dependency {
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0")
    }
}

// MARK: - Logging

struct Logging: _Depending, Dependency {
    var targetDepenency: _PackageDescription_TargetDependency {
        .product(name: "\(Self.self)", package: SwiftLog().packageName)
    }

    var dependencies: any Dependencies {
        SwiftLog()
    }
}
