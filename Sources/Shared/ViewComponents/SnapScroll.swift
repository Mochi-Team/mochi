//
//  SnapScroll.swift
//
//
//  Created by ErrorErrorError on 4/21/23.
//
//

import Foundation
import SwiftUI

// MARK: - SnapScroll

@MainActor
public struct SnapScroll<T: RandomAccessCollection, Content: View>: View where T.Index == Int {
  @State
  var position: T.Index

  var list: T
  var content: (T.Element) -> Content

  var alignment: VerticalAlignment
  var spacing: CGFloat
  var edgeInsets: EdgeInsets

  // Offset...
  @GestureState
  private var translation: CGFloat = 0

  @MainActor
  public init(
    alignment: VerticalAlignment = .center,
    spacing: CGFloat = 0,
    edgeInsets: EdgeInsets = .init(),
    items: T,
    @ViewBuilder content: @escaping (T.Element) -> Content
  ) {
    self.alignment = alignment
    self.spacing = spacing
    self.edgeInsets = edgeInsets
    self._position = .init(initialValue: .init())
    self.list = items
    self.content = content
  }

  @MainActor
  public var body: some View {
    GeometryReader { proxy in
      let maxWidth = proxy.size.width
      HStack(alignment: alignment, spacing: spacing) {
        ForEach(list.indices, id: \.self) { idx in
          content(list[idx])
            .frame(width: max(0, maxWidth - edgeInsets.horizontal - (spacing * 2)))
        }
      }
      .frame(width: maxWidth, alignment: .leading)
      .offset(x: -CGFloat(position) * maxWidth)
      .offset(x: CGFloat(position) * spacing)
      .offset(x: CGFloat(position) * edgeInsets.horizontal)
      .offset(x: edgeInsets.leading)
      .offset(x: spacing)
      .offset(x: translation)
      .contentShape(Rectangle())
      .highPriorityGesture(
        DragGesture()
          .updating($translation) { value, out, _ in
            let leftOverscrol = position == 0 && value.translation.width > 0
            let rightOverscroll = position == list.count - 1 && value.translation.width < 0
            let shouldRestrict = leftOverscrol || rightOverscroll
            out = value.translation.width / (shouldRestrict ? log10(abs(value.translation.width)) : 1)
          }
          .onEnded { value in
            let offset = -(value.translation.width / maxWidth)
            var roundIndex: Int = 0

            if abs(value.translation.width) > maxWidth / 2 ||
              abs(value.predictedEndTranslation.width) > maxWidth / 2 {
              roundIndex = offset > 0 ? 1 : -1
            }

            position = max(min(position + roundIndex, list.count - 1), 0)
          }
      )
      .frame(width: proxy.size.width, height: proxy.size.height)
      .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.76), value: translation != .zero)
      .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.66), value: position)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

// MARK: SnapScroll.EdgeInsets

extension SnapScroll {
  public struct EdgeInsets {
    public let leading: CGFloat
    public let trailing: CGFloat

    public init(
      leading: CGFloat = 0,
      trailing: CGFloat = 0
    ) {
      self.leading = leading
      self.trailing = trailing
    }

    public init(_ size: CGFloat) {
      self.init(leading: size, trailing: size)
    }
  }
}

extension SnapScroll.EdgeInsets {
  var horizontal: CGFloat {
    leading + trailing
  }
}

// MARK: - SnapScroll_Previews

#Preview {
  VStack {
    SnapScroll(
      spacing: 0,
      edgeInsets: .init(
        leading: 20,
        trailing: 40
      ),
      items: [
        Color.red,
        Color.green,
        Color.blue
      ]
    ) { color in
      color
    }

    Text("lol")
  }
}
