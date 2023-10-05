//
//  SharedModels.swift
//  
//
//  Created by ErrorErrorError on 10/5/23.
//  
//

import Foundation

struct SharedModels: Shared {
    var dependencies: any Dependencies {
        DatabaseClient()
        Tagged()
        ComposableArchitecture()
        Semver()
    }
}
