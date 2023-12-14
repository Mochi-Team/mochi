//
//  SettingsGroup.swift
//
//
//  Created by ErrorErrorError on 10/11/23.
//
//

import ComposableArchitecture
import SwiftUI
import UserSettingsClient

public struct SettingsGroup<Content: View>: View {
  let title: String
  let content: () -> Content

  @Environment(\.theme)
  var theme

  public init(
    title: String,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.title = title
    self.content = content
  }

  public var body: some View {
    VStack(alignment: .leading) {
      Text(title)
        .font(.caption.weight(.semibold))
        .foregroundColor(theme.textColor.opacity(0.85))
        .frame(maxWidth: .infinity, alignment: .leading)

      _VariadicView.Tree(Layout()) {
        content()
      }
      .background {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .style(
            withStroke: Color.gray.opacity(0.2),
            lineWidth: 1,
            fill: theme.overBackgroundColor
          )
      }
      .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
      .clipped()
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal)
  }

  /// Source: https://movingparts.io/variadic-views-in-swiftui
  struct Layout: _VariadicView_UnaryViewRoot {
    @ViewBuilder
    func body(children: _VariadicView.Children) -> some View {
      let last = children.last?.id
      VStack(spacing: 0) {
        ForEach(children) { child in
          child
          if child.id != last {
            Capsule()
              .fill(Color.gray.opacity(0.2))
              .frame(maxWidth: .infinity)
              .frame(height: 1)
          }
        }
      }
    }
  }
}
