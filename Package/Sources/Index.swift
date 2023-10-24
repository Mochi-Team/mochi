//
//  Index.swift
//  
//
//  Created by ErrorErrorError on 10/4/23.
//  
//

import Foundation

let package = Package {
    ModuleLists()
    PlaylistDetails()
    Discover()
    Repos()
    Search()
    Settings()
    VideoPlayer()

    MochiApp()
} testTargets: {
    ModuleClient.Tests()
}
.supportedPlatforms {
    MochiPlatforms()
}
