//
//  SwiftSoup.swift
//
//
//  Created by ErrorErrorError on 10/4/23.
//
//

struct SwiftSoup: PackageDependency {
    var dependency: Package.Dependency {
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0")
    }
}
