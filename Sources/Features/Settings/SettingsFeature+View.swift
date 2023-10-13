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
                VStack(spacing: 16) {
                    SettingsGroup(title: "General") {
                        // TODO: Actually allow users to set which discover page to show on startup
                        SettingRow(title: "Discover Page", accessory: {
                            Toggle("", isOn: .constant(true))
                                .labelsHidden()
                        })
                    }

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

                    VStack {
                        Text("Made with ❤️")
                        Text("Version: \(viewStore.buildVersion.description) (\(viewStore.buildNumber))")
                    }
                    .font(.footnote.weight(.medium))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical)
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
                            if theme == .automatic {
                                Circle()
                                    .style(
                                        withStroke: self.theme == theme ? Color.accentColor : Color.gray.opacity(0.5),
                                        lineWidth: 2,
                                        fill: LinearGradient(
                                            colors: [
                                                Theme.light.backgroundColor,
                                                Theme.light.overBackgroundColor,
                                                Theme.dark.overBackgroundColor,
                                                Theme.dark.backgroundColor
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(height: 54)
                                    .padding(.top, 1)
                            } else {
                                Circle()
                                    .style(
                                        withStroke: self.theme == theme ? Color.accentColor : Color.gray.opacity(0.5),
                                        lineWidth: 2,
                                        fill: LinearGradient(
                                            colors: [theme.backgroundColor, theme.overBackgroundColor],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(height: 54)
                                    .padding(.top, 1)
                            }

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
