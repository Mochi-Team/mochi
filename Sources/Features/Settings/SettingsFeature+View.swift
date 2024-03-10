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
  @MainActor public var body: some View {
    NavStack(store.scope(state: \.path, action: \.internal.path)) {
      listSections
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Settings")
        .task { store.send(.view(.onTask)) }
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

// MARK: - GeneralView

@MainActor
struct GeneralView: View {
  var showTitle = true
  let store: StoreOf<SettingsFeature>

  @Environment(\.theme) var theme

  var body: some View {
    EmptyView()
//        SettingsGroup(title: showTitle ? SettingsFeature.Section.general.localized : "") {
//            // TODO: Actually allow users to set which discover page to show on startup
//            SettingRow(title: "Discover Page", accessory: {
//                Toggle("", isOn: .constant(true))
//                    .labelsHidden()
//                    .toggleStyle(.switch)
//                    .controlSize(.small)
//            })
//        }
  }
}

// MARK: - AppearanceView

@MainActor
struct AppearanceView: View {
  var showTitle = true
  let store: StoreOf<SettingsFeature>

  @Environment(\.theme) var theme

  var body: some View {
    WithViewStore(store, observe: \.`self`) { viewStore in
      SettingsGroup(title: showTitle ? SettingsFeature.Section.appearance.localized : "") {
        SettingRow(title: "Theme") {
          Text(viewStore.userSettings.theme.name)
            .font(.callout)
            .foregroundColor(theme.textColor.opacity(0.65))
        } content: {
          ThemePicker(theme: viewStore.$userSettings.theme)
        }

        // TODO: Add option to change app icon
        // SettingRow(title: "App Icon", accessory: EmptyView.init) {}
      }
    }
  }
}

// MARK: - DeveloperView

@MainActor
struct DeveloperView: View {
  var showTitle = true
  let store: StoreOf<SettingsFeature>

  @Environment(\.theme) var theme

  var body: some View {
    WithViewStore(store, observe: \.`self`) { viewStore in
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
      .animation(.easeInOut, value: viewStore.userSettings.developerModeEnabled)
    }
  }
}

// MARK: - ThemePicker

@MainActor
struct ThemePicker: View {
  @Binding var theme: Theme

  @ScaledMetric(relativeTo: .body) var heightSize = 54

  @MainActor var body: some View {
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
                      stops: [
                        .init(color: Theme.light.backgroundColor, location: 0.5),
                        .init(color: Theme.dark.backgroundColor, location: 0.5)
                      ],
                      startPoint: .leading,
                      endPoint: .trailing
                    )
                  )
                  .frame(height: heightSize)
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
                  .frame(height: heightSize)
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

// MARK: - HistoryView

@MainActor
struct HistoryView: View {
  var showTitle = true
  let store: StoreOf<SettingsFeature>

  @SwiftUI.State private var confirmRemoval: Bool = false

  @Environment(\.theme) var theme

  var body: some View {
    WithViewStore(store, observe: \.`self`) { viewStore in
      SettingsGroup(title: showTitle ? SettingsFeature.Section.history.localized : "") {
        Button {
          confirmRemoval.toggle()
        } label: {
          Text("Clear Watch History").foregroundColor(.red)
            .frame(maxWidth: .infinity)
        }
        .confirmationDialog(
          "Are you sure?",
          isPresented: $confirmRemoval
        ) {
          Button("Remove all watch history", role: .destructive) {
            viewStore.send(.view(.clearHistory))
          }
        } message: {
          Text("You cannot undo this action")
        }
        .padding()
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
