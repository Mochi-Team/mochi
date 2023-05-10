//
//  TopBar.swift
//  
//
//  Created by ErrorErrorError on 4/25/23.
//  
//

import Foundation
import SwiftUI
import ViewComponents

public struct TopBarView<TrailingAccessory: View, BottomAccessory: View>: View {
    public enum BackgroundStyle {
        case system
        case blurred
        case clear
    }

    public init(
        title: String? = nil,
        backCallback: (() -> Void)? = nil,
        @ViewBuilder trailingAccessory: @escaping () -> TrailingAccessory,
        @ViewBuilder bottomAccessory: @escaping () -> BottomAccessory
    ) {
        self.title = title
        self.backCallback = backCallback
        self.trailingAccessory = trailingAccessory
        self.bottomAccessory = bottomAccessory
    }

    public let title: String?
    public let backCallback: (() -> Void)?
    public var backgroundStyle: BackgroundStyle = .system
    public let trailingAccessory: () -> TrailingAccessory
    public let bottomAccessory: () -> BottomAccessory

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let backCallback {
                SwiftUI.Button {
                    backCallback()
                } label: {
                    Image(systemName: "chevron.backward.circle.fill")
                        .font(.system(size: 24, weight: .bold))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            HStack(alignment: .bottom, spacing: 12) {
                Text(title ?? "")
                    .font(.largeTitle.bold())
                    .opacity(title == nil ? 0.0 : 1.0)

                Spacer()

                trailingAccessory()
            }

            bottomAccessory()
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Group {
                switch backgroundStyle {
                case .system:
                    Color(uiColor: .systemBackground)
                case .blurred:
                    BlurView()
                case .clear:
                    EmptyView()
                }
            }
            .edgesIgnoringSafeArea(.top)
        )
    }

    public func backgroundStyle(_ style: BackgroundStyle) -> Self {
        var copy = self
        copy.backgroundStyle = style
        return copy
    }
}

extension TopBarView {
    public init(
        title: String? = nil,
        backCallback: (() -> Void)? = nil
    ) where TrailingAccessory == EmptyView, BottomAccessory == EmptyView {
        self.init(title: title, backCallback: backCallback) {
            EmptyView()
        } bottomAccessory: {
            EmptyView()
        }
    }

    public init(
        title: String? = nil,
        backCallback: (() -> Void)? = nil,
        @ViewBuilder trailingAccessory: @escaping () -> TrailingAccessory
    ) where BottomAccessory == EmptyView {
        self.init(title: title, backCallback: backCallback) {
            trailingAccessory()
        } bottomAccessory: {
            EmptyView()
        }
    }

    public init(
        title: String? = nil,
        backCallback: (() -> Void)? = nil,
        @ViewBuilder bottomAccessory: @escaping () -> BottomAccessory
    ) where TrailingAccessory == EmptyView {
        self.init(title: title, backCallback: backCallback) {
            EmptyView()
        } bottomAccessory: {
            bottomAccessory()
        }
    }
}

extension TopBarView {
//    public struct Button {
//        let style: Style
//        let callback: () -> Void
//
//        public init(
//            style: TopBarView.Button.Style,
//            callback: @escaping () -> Void
//        ) {
//            self.style = style
//            self.callback = callback
//        }
//
//        public enum Style {
//            case text(String)
//            case image(String)
//            case systemImage(String)
//        }
//    }

//    public init(
//        title: String? = nil,
//        backCallback: (() -> Void)? = nil,
//        buttons: [Button] = []
//    ) {
//        self.init(title: title, backCallback: backCallback) {
//            ForEach(Array(zip(buttons.indices, buttons)), id: \.0) { _, button in
//                SwiftUI.Button {
//                    button.callback()
//                } label: {
//                    Group {
//                        switch button.style {
//                        case let .text(string):
//                            Text(string)
//                        case let .image(named):
//                            Image(named)
//                        case let .systemImage(named):
//                            Image(systemName: named)
//                        }
//                    }
//                    .font(.title2.weight(.semibold))
//                }
//                .buttonStyle(.plain)
//            }
//        }
}
