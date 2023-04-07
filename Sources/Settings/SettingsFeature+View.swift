//
//  SettingsFeature+View.swift
//  
//
//  Created ErrorErrorError on 4/7/23.
//  Copyright © 2023. All rights reserved.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

extension SettingsFeature.View: View {
    @MainActor
    public var body: some View {
        EmptyView()
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
