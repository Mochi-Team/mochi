//
//  OfflineManagerClient.swift
//
//
//  Created by MochiTeam on 06.04.2024.
//

import Foundation

struct OfflineManagerClient: _Client {
  var dependencies: any Dependencies {
    FileClient()
    SharedModels()
    ComposableArchitecture()
    FlyingFox()
  }
}
