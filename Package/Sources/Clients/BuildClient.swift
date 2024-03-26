//
//  BuildClient.swift
//
//
//  Created by ErrorErrorError on 10/5/23.
//
//

import Foundation

struct BuildClient: _Client {
    var dependencies: any Dependencies {
        Semver()
        ComposableArchitecture()
    }
}
