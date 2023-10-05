//
//  File.swift
//  
//
//  Created by ErrorErrorError on 10/5/23.
//  
//

import Foundation

struct ViewComponents: Shared {
    var dependencies: any Dependencies {
        SharedModels()
        ComposableArchitecture()
        NukeUI()
    }
}
