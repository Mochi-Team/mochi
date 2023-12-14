//
//  DateComponentsFormatter+.swift
//
//
//  Created by ErrorErrorError on 11/22/23.
//
//

import Architecture
import Foundation

extension DateComponentsFormatterClient {
  func playbackTimestamp(_ time: Double) -> String? {
    withFormatter { formatter in
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
}
