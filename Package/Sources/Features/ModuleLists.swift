//
//  ModuleLists.swift
//
//
//  Created by ErrorErrorError on 10/5/23.
//
//

import Foundation

struct ModuleLists: _Feature {
    var dependencies: any Dependencies {
        Architecture()
        RepoClient()
        Styling()
        SharedModels()
        ViewComponents()
        ComposableArchitecture()
    }
}
