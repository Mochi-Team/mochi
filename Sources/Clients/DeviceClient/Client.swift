//
//  Client.swift
//
//
//  Created by ErrorErrorError on 11/29/23.
//
//

import Dependencies
import Foundation

// MARK: - DeviceClient

public struct DeviceClient {
  public var hasBottomIndicator: () -> Bool
}

// MARK: DependencyKey

extension DeviceClient: DependencyKey {
  public static let liveValue: DeviceClient = .init(
    hasBottomIndicator: {
      #if os(iOS)
      if let keyWindow = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .flatMap(\.windows)
        .first(where: { $0.isKeyWindow }),
        keyWindow.safeAreaInsets.bottom > 0 {
        return true
      }
      #endif
      return false
    }
  )
}

extension DependencyValues {
  public var device: DeviceClient {
    get { self[DeviceClient.self] }
    set { self[DeviceClient.self] = newValue }
  }
}
