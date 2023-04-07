//
//  AppFeature+View.swift
//  
//
//  Created by ErrorErrorError on 4/6/23.
//  
//

import ComposableArchitecture
import Foundation
import SwiftUI

extension AppFeature.View: View {
    @MainActor
    public var body: some View {
        WithViewStore(store, observe: \.`self`) { viewStore in
            Text("Hello, world!")
                .onAppear {
                    viewStore.send(.view(.didAppear))
                }
        }
    }
}

struct AppFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        AppFeature.View(
            store: .init(
                initialState: .home(),
                reducer: AppFeature.Reducer()
            )
        )
    }
}
