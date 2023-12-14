//
//  SettingsFeature+iOS.swift
//
//
//  Created by ErrorErrorError on 11/27/23.
//
//

import BuildClient
import ComposableArchitecture
import Dependencies
import SwiftUI

#if os(iOS)
extension SettingsFeature.View {
  @MainActor public var listSections: some View {
    ScrollView(.vertical) {
      VStack(spacing: 16) {
        ForEach(SettingsFeature.Section.allCases, id: \.self) { section in
          switch section {
          case .general:
            GeneralView(viewStore: viewStore)
          case .appearance:
            AppearanceView(viewStore: viewStore)
          case .developer:
            DeveloperView(viewStore: viewStore)
          }
        }

        VersionView()
      }
    }
  }
}

@MainActor
private struct VersionView: View {
  @Dependency(\.build) var build

  var body: some View {
    VStack(spacing: 12) {
      Text(
        """
        Design and developed by \
        [@errorerrorerror](https://errorerrorerror.dev) \
        & \
        [contributors](https://github.com/Mochi-Team/mochi/contributors)
        """
      )
      .multilineTextAlignment(.center)
      Text("Version: \(build.version.description) (\(build.number.rawValue))")
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 12)
    .font(.footnote.weight(.medium))
    .foregroundColor(.gray)
    .frame(maxWidth: .infinity, alignment: .center)
  }
}

#Preview {
  SettingsFeature.View(
    store: .init(initialState: .init()) {
      EmptyReducer()
    }
  )
}
#endif
