//
//  SettingsFeature+macOS.swift
//
//
//  Created by ErrorErrorError on 11/27/23.
//
//

import SwiftUI

#if os(macOS)
extension SettingsFeature.View {
  @MainActor
  public var listSections: some View {
    TabView {
      ForEach(SettingsFeature.Section.allCases, id: \.self) { section in
        VStack {
          switch section {
          case .general:
            GeneralView(showTitle: false, viewStore: viewStore)
          case .appearance:
            AppearanceView(showTitle: false, viewStore: viewStore)
          case .developer:
            DeveloperView(showTitle: false, viewStore: viewStore)
          }
          Spacer()
        }
        .tabItem { Label(section.localized, systemImage: section.systemImage) }
        .tag(section)
      }
    }
  }
}
#endif
