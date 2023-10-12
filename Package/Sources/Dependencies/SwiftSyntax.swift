//
//  SwiftSyntax.swift
//  
//
//  Created by ErrorErrorError on 10/11/23.
//  
//

import Foundation

struct SwiftSyntaxMacros: PackageDependency {
    var dependency: Package.Dependency {
        .package(url: "https://github.com/apple/swift-syntax", from: "509.0.0")
    }
}

struct SwiftCompilerPlugin: PackageDependency {
    var dependency: Package.Dependency {
        .package(url: "https://github.com/apple/swift-syntax", from: "509.0.0")
    }
}
