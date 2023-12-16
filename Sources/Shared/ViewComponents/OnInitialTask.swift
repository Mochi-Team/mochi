//
//  OnInitialTask.swift
//
//
//  Created by ErrorErrorError on 12/15/23.
//  
//

import Foundation
import SwiftUI

private struct OnInitialTask: ViewModifier {
  @State var appeared = false

  let priority: TaskPriority
  let callback: @Sendable () async -> Void

  func body(content: Content) -> some View {
    content.task(priority: priority) {
      guard !appeared else { return }
      appeared = true
      await callback()
    }
  }
}

extension View {
  public func initialTask(
    priority: TaskPriority = .userInitiated,
    _ callback: @escaping @Sendable () async -> Void
  ) -> some View {
    self.modifier(OnInitialTask(priority: priority, callback: callback))
  }
}
