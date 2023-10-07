//
//  LazyView.swift
//  
//
//  Created by ErrorErrorError on 10/6/23.
//  
//

import Foundation
import SwiftUI

// MARK: - LazyView

@MainActor
public struct LazyView<Content: View>: View {
    let build: () -> Content

    @MainActor
    public init(@ViewBuilder _ build: @escaping () -> Content) {
        self.build = build
    }

    @MainActor
    public init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }

    @MainActor
    public var body: some View {
        LazyVStack {
            build()
        }
    }
}
