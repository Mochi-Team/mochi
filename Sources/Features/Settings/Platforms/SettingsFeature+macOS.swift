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
  @MainActor public var listSections: some View {
    TabView {
      ForEach(SettingsFeature.Section.allCases, id: \.self) { section in
        VStack {
          switch section {
          case .general:
            GeneralView(showTitle: false, store: store)
          case .appearance:
            AppearanceView(showTitle: false, store: store)
          case .developer:
            DeveloperView(showTitle: false, store: store)
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
