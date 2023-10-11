//
//  SettingsFeature+View.swift
//
//
//  Created ErrorErrorError on 4/8/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import Styling
import SwiftUI
import ViewComponents

// MARK: - SettingsFeature.View + View

extension SettingsFeature.View: View {
    @MainActor
    public var body: some View {
        WithViewStore(store, observe: \.`self`) { viewStore in
            ScrollView(.vertical) {
                SettingGroup(title: "Customization") {
                    SettingRow(title: "Theme", accessory: EmptyView.init) {
                        ThemePicker(theme: viewStore.$userSettings.theme)
                    }

                    SettingRow(title: "App Icon", accessory: EmptyView.init) {

                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .topBar(title: "Settings")
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
}

struct ThemePicker: View {
    @Binding var theme: Theme

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(Theme.allCases, id: \.self) { theme in
                    VStack(alignment: .center, spacing: 4) {
                        ScreenView(theme: theme)
                            .frame(height: 94)

                        Text(theme.name)
                            .font(.caption.weight(.medium))
                            .padding(6)

                        Button {
                            self.theme = theme
                        } label: {
                            HStack {
                                Image(systemName: self.theme == theme ? "largecircle.fill.circle" : "circle")
                                    .renderingMode(.original)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }
                        }
                    }
                }
            }
        }
    }

    struct ScreenView: View {
        let theme: Theme

        var body: some View {
            RoundedRectangle(cornerRadius: 4)
                .style(withStroke: theme.backgroundColor.opacity(0.2), lineWidth: 2, fill: theme.backgroundColor)
                .aspectRatio(5 / 7, contentMode: .fit)
        }
    }
}

private struct SettingGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundColor(Color.gray)
                .frame(maxWidth: .infinity, alignment: .leading)

            _VariadicView.Tree(Layout()) {
                content()
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .style(
                        withStroke: Color.gray.opacity(0.2),
                        lineWidth: 1,
                        fill: Color.gray.opacity(0.12)
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }

    /// From: https://movingparts.io/variadic-views-in-swiftui
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
                            .padding(.horizontal, 12)
                    }
                }
            }
        }
    }
}

private struct SettingRow<Accessory: View, Content: View>: View {
    let title: String

    @ViewBuilder let accessory: () -> Accessory
    @ViewBuilder let content: () -> Content

    init(
        title: String,
        @ViewBuilder accessory: @escaping () -> Accessory,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.accessory = accessory
        self.content = content
    }

    init(
        title: String,
        @ViewBuilder content: @escaping () -> Content
    ) where Accessory == EmptyView {
        self.title = title
        self.accessory = EmptyView.init
        self.content = content
    }

    init(
        title: String,
        @ViewBuilder accessory: @escaping () -> Accessory
    ) where Content == EmptyView {
        self.title = title
        self.accessory = accessory
        self.content = EmptyView.init
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .font(.callout.weight(.medium))
                Spacer()
                accessory()
            }
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)

            content()
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
    }
}

// MARK: - SettingsFeatureView_Previews

#Preview {
    SettingsFeature.View(
        store: .init(
            initialState: .init(),
            reducer: { SettingsFeature() }
        )
    )
    .themable()
}
