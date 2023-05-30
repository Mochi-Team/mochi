//
//  Live.swift
//  
//
//  Created ErrorErrorError on 5/26/23.
//  Copyright © 2023. All rights reserved.
//

import AVFoundation
import Dependencies
import Foundation

extension VideoPlayerClient: DependencyKey {
    public static let liveValue: Self = {
//        let player = LockIsolated(AVPlayer())
        return Self()
    }()
}
