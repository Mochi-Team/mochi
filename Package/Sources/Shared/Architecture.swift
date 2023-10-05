//
//  Architecture.swift
//  
//
//  Created by ErrorErrorError on 10/5/23.
//  
//

struct Architecture: Shared {
    var dependencies: any Dependencies {
        FoundationHelpers()
        ComposableArchitecture()
    }
}
