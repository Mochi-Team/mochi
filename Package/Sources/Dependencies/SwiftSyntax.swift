//
//  SwiftSyntax.swift
//  
//
//  Created by ErrorErrorError on 10/11/23.
//  
//

import Foundation

struct SwiftSyntax: PackageDependency {
    var dependency: Package.Dependency {
        .package(url: "https://github.com/apple/swift-syntax", from: "509.0.1")
    }
}

struct SwiftSyntaxMacros: Dependency {
    var targetDepenency: _PackageDescription_TargetDependency {
        .product(name: "\(Self.self)", package: SwiftSyntax().packageName)
    }
}

struct SwiftCompilerPlugin: Dependency {
    var targetDepenency: _PackageDescription_TargetDependency {
        .product(name: "\(Self.self)", package: SwiftSyntax().packageName)
    }
}

