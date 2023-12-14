//
//  DynamicStack.swift
//
//
//  Created by ErrorErrorError on 6/7/23.
//
//

import Foundation
import SwiftUI

public struct DynamicStack<Content: View>: View {
  public enum StackType {
    case hstack(VerticalAlignment = .center)
    case vstack(HorizontalAlignment = .center)
  }

  let stackType: StackType
  let spacing: CGFloat
  let content: () -> Content

  public init(
    stackType: StackType,
    spacing: CGFloat = 0.0,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.stackType = stackType
    self.spacing = spacing
    self.content = content
  }

  public var body: some View {
    switch stackType {
    case let .hstack(alignment):
      HStack(alignment: alignment, spacing: spacing, content: content)
    case let .vstack(alignment):
      VStack(alignment: alignment, spacing: spacing, content: content)
    }
  }
}
