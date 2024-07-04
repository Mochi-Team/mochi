//
//  Styling.swift
//
//
//  Created by MochiTeam on 10/5/23.
//
//

import Foundation

struct Styling: _Shared {
    var dependencies: any Dependencies {
        ViewComponents()
        ComposableArchitecture()
        Tagged()
        SwiftUIBackports()
        UserSettingsClient()
    }
}
