//
//  SwiftSyntax.swift
//
//
//  Created by ErrorErrorError on 10/11/23.
//
//

import Foundation

// MARK: - SwiftSyntax

struct SwiftSyntax: PackageDependency {
    var dependency: Package.Dependency {
        .package(url: "https://github.com/apple/swift-syntax", from: "509.0.1")
    }
}

// MARK: - SwiftSyntaxMacros

struct SwiftSyntaxMacros: _Depending, Dependency {
    var targetDepenency: _PackageDescription_TargetDependency {
        .product(name: "\(Self.self)", package: SwiftSyntax().packageName)
    }

    var dependencies: any Dependencies {
        SwiftSyntax()
    }
}

// MARK: - SwiftCompilerPlugin

struct SwiftCompilerPlugin: _Depending, Dependency {
    var targetDepenency: _PackageDescription_TargetDependency {
        .product(name: "\(Self.self)", package: SwiftSyntax().packageName)
    }

    var dependencies: any Dependencies {
        SwiftSyntax()
    }
}
