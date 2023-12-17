//
//  View+Squircle.swift
//
//
//  Created by ErrorErrorError on 5/29/23.
//
//

import Foundation
import SwiftUI

// MARK: - SquircleModifier

@MainActor
struct SquircleModifier: ViewModifier {
  @State var sizeInset = SizeInset.zero
  @Environment(\.colorScheme) var scheme

  @MainActor
  func body(content: Content) -> some View {
    content
      .readSize { sizeInset = $0 }
      .clipShape(clippedShape)
      .overlay {
        clippedShape
          .style(withStroke: Color(white: scheme == .dark ? 0.25 : 0.75), lineWidth: 0.5, fill: .clear)
      }
  }

  var clippedShape: some Shape {
    RoundedRectangle(cornerRadius: sizeInset.size.width / 4, style: .continuous)
  }
}

extension View {
  @MainActor
  public func squircle() -> some View {
    modifier(SquircleModifier())
  }
}
