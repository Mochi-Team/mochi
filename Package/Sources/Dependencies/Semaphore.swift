//
//  Semaphore.swift
//
//
//  Created by ErrorErrorError on 10/4/23.
//
//

struct Semaphore: PackageDependency {
    var dependency: Package.Dependency {
        .package(url: "https://github.com/groue/Semaphore", exact: "0.0.8")
    }
}
