//
//  ExpandableText.swift
//
//
//  Created by ErrorErrorError on 5/23/23.
//
//

import Foundation
import SwiftUI

// MARK: - ExpandableText

public struct ExpandableText: View {
    private let callback: () -> Void
    @State
    private var truncated = false

    private var lineLimit: Int?

    private var text: String

    public init(_ text: String, onReadMoreTapped: @escaping () -> Void) {
        self.text = text
        self.callback = onReadMoreTapped
    }

    public var body: some View {
        VStack(alignment: .leading) {
            Text(text)
                .lineLimit(lineLimit)
                .background(
                    Text(text)
                        .lineLimit(lineLimit)
                        .background(
                            GeometryReader { visibleTextGeometry in
                                ZStack {
                                    Text(text)
                                        .readSize { size in
                                            truncated = size.size.height > visibleTextGeometry.size.height
                                        }
                                }
                                .frame(height: .greatestFiniteMagnitude)
                            }
                        )
                        .hidden()
                )

            if truncated {
                Button {
                    callback()
                } label: {
                    Text("Read More")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            Color.gray.opacity(0.12)
                                .cornerRadius(8)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

public extension ExpandableText {
    func lineLimit(_ limit: Int?) -> Self {
        var copy = self
        copy.lineLimit = limit
        return copy
    }
}
