//
//  TOMLDecoder.swift
//  
//
//  Created by ErrorErrorError on 10/4/23.
//  
//

struct TOMLDecoder: PackageDependency {
    var dependency: Package.Dependency {
        .package(url: "https://github.com/dduan/TOMLDecoder", from: "0.2.2")
    }
}
