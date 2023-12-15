//
//  Live.swift
//
//
//  Created ErrorErrorError on 12/15/23.
//  Copyright © 2023. All rights reserved.
//

import Dependencies
import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - ClipboardClient + DependencyKey

extension ClipboardClient: DependencyKey {
  public static let liveValue = Self(
    copyValue: { value in
      #if canImport(UIKit)
      UIPasteboard.general.string = value
      #elseif canImport(AppKit)
      NSPasteboard.general.setString(value, forType: .string)
      #endif
    }
  )
}
