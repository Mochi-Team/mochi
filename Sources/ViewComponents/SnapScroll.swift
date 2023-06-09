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

    @State
    private var maxWidth = CGFloat.zero

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

    public var body: some View {
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
                    let roundIndex: Int

                    if abs(value.translation.width) > maxWidth / 2 ||
                        abs(value.predictedEndTranslation.width) > maxWidth / 2 {
                        roundIndex = offset > 0 ? 1 : -1
                    } else {
                        roundIndex = 0
                    }

                    position = max(min(position + roundIndex, list.count - 1), 0)
                }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .readSize { size in
            maxWidth = size.size.width
        }
        .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.76), value: translation != .zero)
        .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.66), value: position)
    }
}

// MARK: SnapScroll.EdgeInsets

public extension SnapScroll {
    struct EdgeInsets {
        public let leading: CGFloat
        public let trailing: CGFloat

        public init(
            leading: CGFloat = 0,
            trailing: CGFloat = 0
        ) {
            self.leading = leading
            self.trailing = trailing
        }
    }
}

extension SnapScroll.EdgeInsets {
    var horizontal: CGFloat {
        leading + trailing
    }
}

// MARK: - SnapScroll_Previews

struct SnapScroll_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SnapScroll(
                spacing: 20,
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
}
