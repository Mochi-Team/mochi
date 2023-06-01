//
//  VideoPlayerFeature+View.swift
//  
//
//  Created ErrorErrorError on 5/26/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import SwiftUI

extension VideoPlayerFeature.View: View {
    @MainActor
    public var body: some View {
        WithViewStore(store.viewAction, observe: \.player) { viewStore in
            VideoPlayer(player: viewStore.state)
                .edgesIgnoringSafeArea(.all)
                .ignoresSafeArea(.all, edges: .all)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct VideoPlayerFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        VideoPlayerFeature.View(
            store: .init(
                initialState: .init(
                    player: .init()
                ),
                reducer: VideoPlayerFeature.Reducer()
            )
        )
    }
}
