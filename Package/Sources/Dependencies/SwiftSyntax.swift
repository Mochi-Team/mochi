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

struct SwiftSyntaxMacros: _Depending, Dependency {
    var targetDepenency: _PackageDescription_TargetDependency {
        .product(name: "\(Self.self)", package: SwiftSyntax().packageName)
    }

    var dependencies: any Dependencies {
        SwiftSyntax()
    }
}

struct SwiftCompilerPlugin: _Depending, Dependency {
    var targetDepenency: _PackageDescription_TargetDependency {
        .product(name: "\(Self.self)", package: SwiftSyntax().packageName)
    }

    var dependencies: any Dependencies {
        SwiftSyntax()
    }
}

