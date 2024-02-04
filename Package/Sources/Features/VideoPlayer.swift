//
//  VideoPlayer.swift
//
//
//  Created by ErrorErrorError on 10/5/23.
//
//

struct VideoPlayer: _Feature {
    var dependencies: any Dependencies {
        Architecture()
        ContentCore()
        LoggerClient()
        PlayerClient()
        SharedModels()
        Styling()
        ViewComponents()
        UserSettingsClient()
        ComposableArchitecture()
        NukeUI()
    }
}
