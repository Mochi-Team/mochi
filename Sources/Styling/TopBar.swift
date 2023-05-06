//
//  TopBar.swift
//  
//
//  Created by ErrorErrorError on 4/25/23.
//  
//

import Foundation
import SwiftUI

public struct TopBarView: View {
    public struct Button {
        let style: Style
        let callback: () -> Void

        public init(
            style: TopBarView.Button.Style,
            callback: @escaping () -> Void
        ) {
            self.style = style
            self.callback = callback
        }

        public enum Style {
            case text(String)
            case image(String)
            case systemImage(String)
        }
    }

    public init(
        title: String? = nil,
        backCallback: (() -> Void)? = nil,
        buttons: [Button] = []
    ) {
        self.title = title
        self.backCallback = backCallback
        self.buttons = buttons
    }

    public let title: String?
    public let buttons: [Button]
    public let backCallback: (() -> Void)?

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let backCallback {
                SwiftUI.Button {
                    backCallback()
                } label: {
                    Image(systemName: "chevron.backward.circle.fill")
                        .font(.system(size: 24, weight: .bold))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            if let title {
                HStack(alignment: .bottom, spacing: 12) {
                    Text(title)
                        .font(.largeTitle.bold())

                    Spacer()

                    ForEach(Array(zip(buttons.indices, buttons)), id: \.0) { _, button in
                        SwiftUI.Button {
                            button.callback()
                        } label: {
                            Group {
                                switch button.style {
                                case let .text(string):
                                    Text(string)
                                case let .image(named):
                                    Image(named)
                                case let .systemImage(named):
                                    Image(systemName: named)
                                }
                            }
                            .font(.title2.weight(.semibold))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .systemBackground))
    }
}
