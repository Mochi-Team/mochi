//
//  Styling.swift
//
//
//  Created by ErrorErrorError on 10/5/23.
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
