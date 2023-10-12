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
                SettingsGroup(title: "Apearance") {
                    SettingRow(title: "Theme") {
                        Text(viewStore.userSettings.theme.name)
                            .font(.callout.weight(.medium))
                            .foregroundColor(theme.textColor.opacity(0.5))
                    } content: {
                        ThemePicker(theme: viewStore.$userSettings.theme)
                    }

                    SettingRow(title: "App Icon", accessory: EmptyView.init) {

                    }
                }
            }
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
            HStack(alignment: .center, spacing: 12) {
                ForEach(Theme.allCases, id: \.self) { theme in
                    Button {
                        self.theme = theme
                    } label: {
                        VStack(alignment: .center, spacing: 12) {
                            Circle()
                                .style(
                                    withStroke: self.theme == theme ? Color.accentColor : Color.clear,
                                    lineWidth: 2,
                                    fill: LinearGradient(
                                        colors: [theme.backgroundColor, theme.overBackgroundColor],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )

                                )
                                .frame(height: 54)
                                .padding(.top, 1)

                            Text(theme.name)
                                .font(.caption.weight(.medium))
                        }
                        .overlay(alignment: .topTrailing) {
                            if self.theme == theme {
                                Image(systemName: "checkmark.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 18)
                                    .foregroundColor(Color.accentColor)
                                    .background(self.theme.overBackgroundColor, in: Circle())
                            }
                        }
                    }
                    .buttonStyle(.scaled)
                }
            }
        }
    }

    struct ScreenView: View {
        let theme: Theme

        var body: some View {
            RoundedRectangle(cornerRadius: 4)
                .fill(theme.backgroundColor)
//                .overlay {
//                    RoundedRectangle(cornerRadius: 2)
//                        .fill(theme.overBackgroundColor)
//                        .padding()
//                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(5 / 7, contentMode: .fill)
                .padding(.top, 2)
        }
    }
}

// MARK: - SettingsFeatureView_Previews

#Preview {
    SettingsFeature.View(
        store: .init(
            initialState: .init(),
            reducer: {
                SettingsFeature()
                    .transformDependency(\.userSettings) { dependency in
                        dependency.get = { .init(theme: .dark, appIcon: .default) }
                    }
            }
        )
    )
    .themable()
}
