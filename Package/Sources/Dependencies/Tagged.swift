//
//  Tagged.swift
//
//
//  Created by ErrorErrorError on 10/5/23.
//
//

import Foundation

struct Tagged: PackageDependency {
    var dependency: Package.Dependency {
        .package(url: "https://github.com/pointfreeco/swift-tagged", exact: "0.10.0")
    }
}
