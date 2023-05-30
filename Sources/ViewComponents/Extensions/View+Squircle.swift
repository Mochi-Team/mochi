//
//  View+Squircle.swift
//  
//
//  Created by ErrorErrorError on 5/29/23.
//  
//

import Foundation
import SwiftUI

@MainActor
struct SquircleModifier: ViewModifier {
    @State var sizeInset = SizeInset.zero

    @MainActor
    func body(content: Content) -> some View {
        content
            .readSize { sizeInset in
                self.sizeInset = sizeInset
            }
            .clipShape(RoundedRectangle(cornerRadius: sizeInset.size.width / 4, style: .continuous))
    }
}

public extension View {
    @MainActor
    func squircle() -> some View {
        self.modifier(SquircleModifier())
    }
}
