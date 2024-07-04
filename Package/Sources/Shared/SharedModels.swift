//
//  SharedModels.swift
//
//
//  Created by MochiTeam on 10/5/23.
//
//

import Foundation

struct SharedModels: _Shared {
    var dependencies: any Dependencies {
        DatabaseClient()
        Tagged()
        ComposableArchitecture()
        Semver()
        JSValueCoder()
    }
}
