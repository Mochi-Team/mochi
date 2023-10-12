//
//  Macro.swift
//
//
//  Created by ErrorErrorError on 10/11/23.
//  
//

import CompilerPluginSupport
import Foundation

protocol Macro: Target {}

extension Macro {
  var targetType: TargetType {
    .macro
  }

  var targetDepenency: _PackageDescription_TargetDependency {
      .target(name: self.name)
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

// Skeleton
//.macro(
//    name: <#T##String#>,
//    dependencies: <#T##[Dependency]#>,
//    path: <#T##String?#>,
//    exclude: <#T##[String]#>,
//    sources: <#T##[String]?#>,
//    packageAccess: <#T##Bool#>,
//    swiftSettings: <#T##[SwiftSetting]?#>,
//    linkerSettings: <#T##[LinkerSetting]?#>,
//    plugins: <#T##[PluginUsage]?#>
//)
