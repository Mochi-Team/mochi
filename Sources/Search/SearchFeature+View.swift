//
//  SearchFeature+View.swift
//  
//
//  Created ErrorErrorError on 4/18/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import SwiftUI

extension SearchFeature.View: View {
    @MainActor
    public var body: some View {
        VStack {
            WithViewStore(store.viewAction, observe: \.`self`) { viewStore in
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("Search for content...", text: viewStore.binding(\.$query))
                        .textFieldStyle(.plain)
                        .font(.system(size: 16, weight: .regular))
                        .frame(maxWidth: .infinity)

                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.gray)
                        .opacity(viewStore.query.isEmpty ? 0.0 : 1.0)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewStore.send(.didClearQuery)
                        }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .foregroundColor(.gray.opacity(0.1))
                )
                .padding(.horizontal)

                // TODO: Show/Hide filters depending on module, if available
//                    Image(systemName: "line.horizontal.3.decrease")
//                        .font(.system(size: 18, weight: .bold))

            }
            .padding(.top, 16)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            ViewStore(store.viewAction.stateless).send(.didAppear)
        }
    }
}

struct SearchFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        SearchFeature.View(
            store: .init(
                initialState: .init(query: ""),
                reducer: SearchFeature.Reducer()
            )
        )
    }
}
