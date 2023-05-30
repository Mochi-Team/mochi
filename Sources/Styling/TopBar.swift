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

public enum TopBarBackgroundStyle {
    case system
    case blurred
    case clear
}

public struct TopBarView<TrailingAccessory: View, BottomAccessory: View>: View {
    public init(
        title: String? = nil,
        backgroundStyle: TopBarBackgroundStyle = .system,
        backCallback: (() -> Void)? = nil,
        @ViewBuilder trailingAccessory: @escaping () -> TrailingAccessory,
        @ViewBuilder bottomAccessory: @escaping () -> BottomAccessory
    ) {
        self.title = title
        self.backCallback = backCallback
        self.trailingAccessory = trailingAccessory
        self.bottomAccessory = bottomAccessory
        self.backgroundStyle = backgroundStyle
    }

    let title: String?
    let backCallback: (() -> Void)?
    var backgroundStyle: TopBarBackgroundStyle = .system
    let trailingAccessory: () -> TrailingAccessory
    let bottomAccessory: () -> BottomAccessory

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                if let backCallback {
                    SwiftUI.Button {
                        backCallback()
                    } label: {
                        Image(systemName: "chevron.backward")
                    }
                    .buttonStyle(.materialToolbarImage)
                }

                if let title {
                    Text(title)
                        .font(.title.bold())
                }

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
            ZStack {
                switch backgroundStyle {
                case .system:
                    Color(uiColor: .systemBackground)
                        .transition(.opacity)
                case .blurred:
                    BlurView()
                        .transition(.opacity)
                case .clear:
                    EmptyView()
                        .transition(.opacity)
                }
            }
            .edgesIgnoringSafeArea(.top)
            .animation(.easeInOut, value: backgroundStyle)
        )
    }

    public func backgroundStyle(_ style: TopBarBackgroundStyle) -> Self {
        var copy = self
        copy.backgroundStyle = style
        return copy
    }
}

extension TopBarView {
    public init(
        title: String? = nil,
        backgroundStyle: TopBarBackgroundStyle = .system,
        backCallback: (() -> Void)? = nil
    ) where TrailingAccessory == EmptyView, BottomAccessory == EmptyView {
        self.init(title: title, backgroundStyle: backgroundStyle, backCallback: backCallback) {
            EmptyView()
        } bottomAccessory: {
            EmptyView()
        }
    }

    public init(
        title: String? = nil,
        backgroundStyle: TopBarBackgroundStyle = .system,
        backCallback: (() -> Void)? = nil,
        @ViewBuilder trailingAccessory: @escaping () -> TrailingAccessory
    ) where BottomAccessory == EmptyView {
        self.init(title: title, backgroundStyle: backgroundStyle, backCallback: backCallback) {
            trailingAccessory()
        } bottomAccessory: {
            EmptyView()
        }
    }

    public init(
        title: String? = nil,
        backgroundStyle: TopBarBackgroundStyle = .system,
        backCallback: (() -> Void)? = nil,
        @ViewBuilder bottomAccessory: @escaping () -> BottomAccessory
    ) where TrailingAccessory == EmptyView {
        self.init(title: title, backgroundStyle: backgroundStyle, backCallback: backCallback) {
            EmptyView()
        } bottomAccessory: {
            bottomAccessory()
        }
    }
}

public extension View {
    func topBar<TrailingAccessory: View, BottomAccessory: View>(
        title: String? = nil,
        backgroundStyle: TopBarBackgroundStyle = .system,
        backCallback: (() -> Void)? = nil,
        @ViewBuilder trailingAccessory: @escaping () -> TrailingAccessory,
        @ViewBuilder bottomAccessory: @escaping () -> BottomAccessory
    ) -> some View {
        self.safeAreaInset(edge: .top) {
            TopBarView(
                title: title,
                backgroundStyle: backgroundStyle,
                backCallback: backCallback,
                trailingAccessory: trailingAccessory,
                bottomAccessory: bottomAccessory
            )
            .frame(maxWidth: .infinity)
        }
    }

    func topBar(
        title: String? = nil,
        backgroundStyle: TopBarBackgroundStyle = .system,
        backCallback: (() -> Void)? = nil
    ) -> some View {
        self.topBar(title: title, backgroundStyle: backgroundStyle, backCallback: backCallback) {
            EmptyView()
        } bottomAccessory: {
            EmptyView()
        }
    }

    func topBar<TrailingAccessory: View>(
        title: String? = nil,
        backgroundStyle: TopBarBackgroundStyle = .system,
        backCallback: (() -> Void)? = nil,
        @ViewBuilder trailingAccessory: @escaping () -> TrailingAccessory
    ) -> some View {
        self.topBar(title: title, backgroundStyle: backgroundStyle, backCallback: backCallback, trailingAccessory: trailingAccessory) {
            EmptyView()
        }
    }

    func topBar<BottomAccessory: View>(
        title: String? = nil,
        backgroundStyle: TopBarBackgroundStyle = .system,
        backCallback: (() -> Void)? = nil,
        @ViewBuilder bottomAccessory: @escaping () -> BottomAccessory
    ) -> some View {
        self.topBar(title: title, backgroundStyle: backgroundStyle, backCallback: backCallback) {
            EmptyView()
        } bottomAccessory: {
            bottomAccessory()
        }
    }
}

public extension ButtonStyle where Self == MaterialToolbarImageButtonStyle {
    static var materialToolbarImage: MaterialToolbarImageButtonStyle { .init() }
}

public struct MaterialToolbarImageButtonStyle: ButtonStyle {
    public init() {}

    @ScaledMetric var size = 28.0

    public func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .font(.callout.bold())
            .frame(width: size, height: size)
            .background(.ultraThinMaterial, in: Circle())
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(), value: configuration.isPressed)
    }
}

public extension MenuStyle where Self == MaterialToolbarButtonMenuStyle {
    static var materialToolbarImage: MaterialToolbarButtonMenuStyle { .init() }
}

public struct MaterialToolbarButtonMenuStyle: MenuStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        Menu(configuration)
            .foregroundColor(.label)
            .font(.callout.bold())
            .frame(width: 28, height: 28)
            .background(.ultraThinMaterial, in: Circle())
            .contentShape(Rectangle())
    }
}
