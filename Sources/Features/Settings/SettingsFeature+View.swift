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
        NavStack(store.scope(state: \.path, action: Action.InternalAction.path)) {
            listSections
                .animation(.easeInOut, value: viewStore.userSettings.developerModeEnabled)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .topBar(title: "Settings")
                .task { viewStore.send(.onTask) }
        } destination: { store in
            SwitchStore(store) { state in
                switch state {
                case .logs:
                    CaseLet(
                        /SettingsFeature.Path.State.logs,
                        action: SettingsFeature.Path.Action.logs,
                        then: { store in Logs.View(store: store) }
                    )
                }
            }
        }
    }
}

@MainActor
struct GeneralView: View {
    var showTitle = true

    @Environment(\.theme)
    var theme

    @ObservedObject
    var viewStore: FeatureViewStore<SettingsFeature>

    var body: some View {
        SettingsGroup(title: showTitle ? SettingsFeature.Section.general.localized : "") {
            // TODO: Actually allow users to set which discover page to show on startup
            SettingRow(title: "Discover Page", accessory: {
                Toggle("", isOn: .constant(true))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
            })
        }
    }
}

@MainActor
struct AppearanceView: View {
    var showTitle = true

    @Environment(\.theme)
    var theme

    @ObservedObject
    var viewStore: FeatureViewStore<SettingsFeature>

    var body: some View {
        SettingsGroup(title: showTitle ? SettingsFeature.Section.appearance.localized : "") {
            SettingRow(title: "Theme") {
                Text(viewStore.userSettings.theme.name)
                    .font(.callout)
                    .foregroundColor(theme.textColor.opacity(0.65))
            } content: {
                ThemePicker(theme: viewStore.$userSettings.theme)
            }

            // TODO: Add option to change app icon
            SettingRow(title: "App Icon", accessory: EmptyView.init) {}
        }
    }
}

@MainActor
struct DeveloperView: View {
    var showTitle = true

    @Environment(\.theme)
    var theme

    @ObservedObject
    var viewStore: FeatureViewStore<SettingsFeature>

    var body: some View {
        SettingsGroup(title: showTitle ? SettingsFeature.Section.developer.localized : "") {
            SettingRow(title: String(localized: "Developer Mode"), accessory: {
                Toggle("", isOn: viewStore.$userSettings.developerModeEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
            })

            if viewStore.userSettings.developerModeEnabled {
                SettingRow(title: String(localized: "View Logs"), accessory: {
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                })
                .contentShape(Rectangle())
                .onTapGesture {
                    viewStore.send(.didTapViewLogs)
                }
            }
        }
    }
}

// MARK: - ThemePicker

@MainActor
struct ThemePicker: View {
    @Binding
    var theme: Theme

    @MainActor
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
            reducer: { SettingsFeature() },
            withDependencies: { deps in
                deps.userSettings.get = {
                    .init(
                        theme: .dark,
                        appIcon: .default,
                        developerModeEnabled: true
                    )
                }
            }
        )
    )
    .themeable()
}
