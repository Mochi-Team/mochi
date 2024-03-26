//
//  CustomDump.swift
//
//
//  Created by ErrorErrorError on 1/1/24.
//
//

import Foundation

struct CustomDump: PackageDependency {
    var dependency: Package.Dependency {
        .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.0.0")
    }
}
