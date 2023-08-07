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

// MARK: - TopBarBackgroundStyle

public enum TopBarBackgroundStyle: Equatable {
    case system
    case gradientSystem(Easing = .easeIn)
    case blurred
    case clear
}

// MARK: - TopBarView

@MainActor
public struct TopBarView<LeadingAccessory: View, TrailingAccessory: View, BottomAccessory: View>: View {
    let backCallback: (() -> Void)?
    var backgroundStyle: TopBarBackgroundStyle = .system
    let leadingAccessory: () -> LeadingAccessory
    let trailingAccessory: () -> TrailingAccessory
    let bottomAccessory: () -> BottomAccessory

    public init(
        backgroundStyle: TopBarBackgroundStyle = .system,
        backCallback: (() -> Void)? = nil,
        @ViewBuilder leadingAccessory: @escaping () -> LeadingAccessory,
        @ViewBuilder trailingAccessory: @escaping () -> TrailingAccessory,
        @ViewBuilder bottomAccessory: @escaping () -> BottomAccessory
    ) {
        self.backCallback = backCallback
        self.leadingAccessory = leadingAccessory
        self.trailingAccessory = trailingAccessory
        self.bottomAccessory = bottomAccessory
        self.backgroundStyle = backgroundStyle
    }

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

                leadingAccessory()

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
                    Color.theme.backgroundColor
                        .transition(.opacity)
                case let .gradientSystem(easing):
                    LinearGradient(
                        gradient: .init(
                            colors: [
                                .theme.backgroundColor,
                                .theme.backgroundColor.opacity(0)
                            ],
                            easing: easing
                        ),
                        startPoint: .top,
                        endPoint: .bottom
                    )
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

public extension TopBarView {
    init(
        backgroundStyle: TopBarBackgroundStyle = .system,
        backCallback: (() -> Void)? = nil,
        @ViewBuilder leadingAccessory: @escaping () -> LeadingAccessory
    ) where TrailingAccessory == EmptyView, BottomAccessory == EmptyView {
        self.init(
            backgroundStyle: backgroundStyle,
            backCallback: backCallback,
            leadingAccessory: leadingAccessory,
            trailingAccessory: EmptyView.init,
            bottomAccessory: EmptyView.init
        )
    }

    init(
        backgroundStyle: TopBarBackgroundStyle = .system,
        backCallback: (() -> Void)? = nil,
        @ViewBuilder leadingAccessory: @escaping () -> LeadingAccessory,
        @ViewBuilder trailingAccessory: @escaping () -> TrailingAccessory
    ) where BottomAccessory == EmptyView {
        self.init(
            backgroundStyle: backgroundStyle,
            backCallback: backCallback,
            leadingAccessory: leadingAccessory,
            trailingAccessory: trailingAccessory,
            bottomAccessory: EmptyView.init
        )
    }

    init(
        title: String? = nil,
        backgroundStyle: TopBarBackgroundStyle = .system,
        backCallback: (() -> Void)? = nil,
        @ViewBuilder trailingAccessory: @escaping () -> TrailingAccessory,
        @ViewBuilder bottomAccessory: @escaping () -> BottomAccessory
    ) where LeadingAccessory == Text? {
        self.init(
            backgroundStyle: backgroundStyle,
            backCallback: backCallback,
            leadingAccessory: {
                if let title {
                    Text(title)
                        .font(.title.bold())
                }
            },
            trailingAccessory: trailingAccessory,
            bottomAccessory: bottomAccessory
        )
    }

    init(
        title: String? = nil,
        backgroundStyle: TopBarBackgroundStyle = .system,
        backCallback: (() -> Void)? = nil
    ) where LeadingAccessory == Text?, TrailingAccessory == EmptyView, BottomAccessory == EmptyView {
        self.init(title: title, backgroundStyle: backgroundStyle, backCallback: backCallback) {
            EmptyView()
        } bottomAccessory: {
            EmptyView()
        }
    }

    init(
        title: String? = nil,
        backgroundStyle: TopBarBackgroundStyle = .system,
        backCallback: (() -> Void)? = nil,
        @ViewBuilder trailingAccessory: @escaping () -> TrailingAccessory
    ) where LeadingAccessory == Text?, BottomAccessory == EmptyView {
        self.init(title: title, backgroundStyle: backgroundStyle, backCallback: backCallback) {
            trailingAccessory()
        } bottomAccessory: {
            EmptyView()
        }
    }

    init(
        title: String? = nil,
        backgroundStyle: TopBarBackgroundStyle = .system,
        backCallback: (() -> Void)? = nil,
        @ViewBuilder bottomAccessory: @escaping () -> BottomAccessory
    ) where LeadingAccessory == Text?, TrailingAccessory == EmptyView {
        self.init(title: title, backgroundStyle: backgroundStyle, backCallback: backCallback) {
            EmptyView()
        } bottomAccessory: {
            bottomAccessory()
        }
    }
}

@MainActor
public extension View {
    func topBar(
        backgroundStyle: TopBarBackgroundStyle = .system,
        backCallback: (() -> Void)? = nil,
        @ViewBuilder leadingAccessory: @escaping () -> some View,
        @ViewBuilder trailingAccessory: @escaping () -> some View,
        @ViewBuilder bottomAccessory: @escaping () -> some View
    ) -> some View {
        safeAreaInset(edge: .top) {
            TopBarView(
                backgroundStyle: backgroundStyle,
                backCallback: backCallback,
                leadingAccessory: leadingAccessory,
                trailingAccessory: trailingAccessory,
                bottomAccessory: bottomAccessory
            )
            .frame(maxWidth: .infinity)
        }
    }

    func topBar(
        title: String? = nil,
        backgroundStyle: TopBarBackgroundStyle = .system,
        backCallback: (() -> Void)? = nil,
        @ViewBuilder trailingAccessory: @escaping () -> some View,
        @ViewBuilder bottomAccessory: @escaping () -> some View
    ) -> some View {
        safeAreaInset(edge: .top) {
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
        topBar(title: title, backgroundStyle: backgroundStyle, backCallback: backCallback) {
            EmptyView()
        } bottomAccessory: {
            EmptyView()
        }
    }

    func topBar(
        title: String? = nil,
        backgroundStyle: TopBarBackgroundStyle = .system,
        backCallback: (() -> Void)? = nil,
        @ViewBuilder trailingAccessory: @escaping () -> some View
    ) -> some View {
        topBar(title: title, backgroundStyle: backgroundStyle, backCallback: backCallback, trailingAccessory: trailingAccessory) {
            EmptyView()
        }
    }

    func topBar(
        title: String? = nil,
        backgroundStyle: TopBarBackgroundStyle = .system,
        backCallback: (() -> Void)? = nil,
        @ViewBuilder bottomAccessory: @escaping () -> some View
    ) -> some View {
        topBar(title: title, backgroundStyle: backgroundStyle, backCallback: backCallback) {
            EmptyView()
        } bottomAccessory: {
            bottomAccessory()
        }
    }
}

public extension ButtonStyle where Self == MaterialToolbarImageButtonStyle {
    static var materialToolbarImage: MaterialToolbarImageButtonStyle { .init() }
}

// MARK: - MaterialToolbarImageButtonStyle

public struct MaterialToolbarImageButtonStyle: ButtonStyle {
    public init() {}

    @ScaledMetric
    var size = 28.0

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

// MARK: - MaterialToolbarButtonMenuStyle

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
