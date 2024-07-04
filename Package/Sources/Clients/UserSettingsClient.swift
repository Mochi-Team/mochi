//
//  UserSettingsClient.swift
//
//
//  Created by MochiTeam on 10/5/23.
//
//

import Foundation

struct UserSettingsClient: _Client {
    var dependencies: any Dependencies {
        UserDefaultsClient()
        ComposableArchitecture()
        ViewComponents()
    }
}
