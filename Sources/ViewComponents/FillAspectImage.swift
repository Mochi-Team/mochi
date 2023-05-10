//
//  FillAspectImage.swift
//
//
//  Created by ErrorErrorError on 10/25/22.
//
//

import NukeUI
import SwiftUI

public struct FillAspectImage: View {
    let url: URL?
    var averageColor: ((Color?) -> Void)?

    public init(url: URL?) {
        self.url = url
    }

    public var body: some View {
        GeometryReader { proxy in
            LazyImage(
                url: url,
                transaction: .init(animation: .easeInOut(duration: 0.4))
            ) { state in
                if let image = state.image {
                    image.resizable()
                } else {
                    Color.gray.opacity(0.2)
                }
            }
//            .onAverageColor(averageColor)
            .scaledToFill()
            .frame(
                width: proxy.size.width,
                height: proxy.size.height,
                alignment: .center
            )
            .contentShape(Rectangle())
            .clipped()
        }
    }

    public func onAverageColor(_ callback: @escaping (Color?) -> Void) -> Self {
        var copy = self
        copy.averageColor = callback
        return copy
    }
}
