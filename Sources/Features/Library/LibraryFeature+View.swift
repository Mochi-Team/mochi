//
//  LibraryFeature+View.swift
//
//
//  Created ErrorErrorError on 1/2/24.
//  Copyright © 2024. All rights reserved.
//

import Architecture
import ComposableArchitecture
import SwiftUI

// MARK: - LibraryFeature.View + View

extension LibraryFeature.View: View {
  @MainActor public var body: some View {
    WithViewStore(store, observe: \.`self`) { viewStore in
      Text("Hello, World!")
        .onAppear {
          viewStore.send(.didAppear)
        }
    }
  }
}

// MARK: - LibraryFeatureView_Previews

struct LibraryFeatureView_Previews: PreviewProvider {
  static var previews: some View {
    LibraryFeature.View(
      store: .init(
        initialState: .init(),
        reducer: { LibraryFeature() }
      )
    )
  }
}
