//
//  HomeFeature+View.swift
//  
//
//  Created by ErrorErrorError on 4/5/23.
//  
//

import ComposableArchitecture
import SharedModels
import SwiftUI

extension HomeFeature.View: View {
    @MainActor
    public var body: some SwiftUI.View {
        EmptyView()
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeFeature.View(
            store: .init(
                initialState: .init(),
                reducer: HomeFeature.Reducer()
            )
        )
    }
}
