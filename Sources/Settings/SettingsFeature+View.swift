//
//  SettingsFeature+View.swift
//  
//
//  Created ErrorErrorError on 4/8/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import SwiftUI

extension SettingsFeature.View: View {
    @MainActor
    public var body: some View {
        WithViewStore(store.viewAction, observe: \.`self`) { viewStore in
            Text("Hello, World!")
                .onAppear {
                    viewStore.send(.didAppear)
                }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
}

struct SettingsFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsFeature.View(
            store: .init(
                initialState: .init(),
                reducer: SettingsFeature.Reducer()
            )
        )
    }
}
