//
//  ScrollViewTracker.swift
//
//
//  Created by ErrorErrorError on 12/12/23.
//  
//

import Foundation
import SwiftUI

private struct ScrollOffsetPreferenceKey: SwiftUI.PreferenceKey {
    static var defaultValue: CGPoint = .zero

    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}

private let scrollOffsetNamespace = "scrollView"

public struct ScrollViewTracker<Content: View>: View {
    public init(
        _ axis: Axis.Set = [.horizontal, .vertical],
        showsIndicators: Bool = true,
        onScroll: ScrollAction? = nil,
        content: @escaping () -> Content
    ) {
        self.axis = axis
        self.showsIndicators = showsIndicators
        self.action = onScroll
        self.content = content
    }

    private let axis: Axis.Set
    private let showsIndicators: Bool
    private let content: () -> Content
    private let action: ScrollAction?

    public typealias ScrollAction = (_ offset: CGPoint) -> Void

    public var body: some View {
        ScrollView(axis, showsIndicators: showsIndicators) {
            ZStack(alignment: .top) {
                GeometryReader { geo in
                    Color.clear
                        .preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geo.frame(in: .named(scrollOffsetNamespace)).origin
                        )
                }
                .frame(height: 0)

                content()
            }
        }
        .coordinateSpace(name: scrollOffsetNamespace)
        .onPreferenceChange(ScrollOffsetPreferenceKey.self, perform: { action?($0) })
    }
}
