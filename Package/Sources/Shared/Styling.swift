//
//  File.swift
//  
//
//  Created by ErrorErrorError on 10/5/23.
//  
//

import Foundation

struct Styling: Shared {
    var dependencies: any Dependencies {
        ViewComponents()
        ComposableArchitecture()
        Tagged()
        SwiftUIBackports()
        UserSettingsClient()
    }
}
