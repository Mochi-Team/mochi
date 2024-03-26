//
//  Macro.swift
//
//
//  Created by ErrorErrorError on 10/11/23.
//
//

import CompilerPluginSupport
import Foundation

// MARK: - Macro

protocol Macro: Target {}

extension Macro {
    var targetType: TargetType {
        .macro
    }

    var targetDepenency: _PackageDescription_TargetDependency {
        .target(name: name)
    }

    var cSettings: [CSetting] {
        []
    }

    var swiftSettings: [SwiftSetting] {
        []
    }

    var resources: [Resource] {
        []
    }
}
