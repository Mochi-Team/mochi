//
//  File.swift
//  
//
//  Created by ErrorErrorError on 6/11/23.
//  
//

import ComposableArchitecture
import CoreMedia
import Foundation

extension CMTime {
    public var displayTime: String? {
        @Dependency(\.dateComponentsFormatter)
        var formatter

        let time = CMTimeGetSeconds(self)
        guard !time.isNaN else {
            return nil
        }

        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad

        if time < 60 * 60 {
            formatter.allowedUnits = [.minute, .second]
        } else {
            formatter.allowedUnits = [.hour, .minute, .second]
        }

        return formatter.string(from: time)
    }
}
