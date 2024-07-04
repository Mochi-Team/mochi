//
//  PlayerClient.swift
//
//
//  Created by MochiTeam on 10/5/23.
//
//

import Foundation

struct PlayerClient: _Client {
    var dependencies: any Dependencies {
        Architecture()
        ModuleClient()
        SharedModels()
        Styling()
        UserDefaultsClient()
        ComposableArchitecture()
        ViewComponents()
        XMLCoder()
    }
}
