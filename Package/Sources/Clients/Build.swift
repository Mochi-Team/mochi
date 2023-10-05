//
//  Build.swift
//  
//
//  Created by ErrorErrorError on 10/5/23.
//  
//

import Foundation

struct Build: Client {
    var dependencies: any Dependencies {
        Semver()
        ComposableArchitecture()
    }
}
