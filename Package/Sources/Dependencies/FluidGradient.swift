//
//  FluidGradient.swift
//
//
//  Created by ErrorErrorError on 10/11/23.
//
//

import Foundation

struct FluidGradient: PackageDependency {
    var dependency: Package.Dependency {
        .package(url: "https://github.com/Cindori/FluidGradient.git", exact: "1.0.0")
    }
}
