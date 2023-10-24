//
//  SettingsRow.swift
//
//
//  Created by ErrorErrorError on 10/11/23.
//
//

import Foundation
import SwiftUI

public struct SettingRow<Accessory: View, Content: View>: View {
    let title: String
    let footer: String?
    let accessory: () -> Accessory
    let content: () -> Content

    public init(
        title: String,
        footer: String? = nil,
        @ViewBuilder accessory: @escaping () -> Accessory,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.footer = footer
        self.accessory = accessory
        self.content = content
    }

    public init(
        title: String,
        footer: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) where Accessory == EmptyView {
        self.init(
            title: title,
            footer: footer,
            accessory: EmptyView.init,
            content: content
        )
    }

    public init(
        title: String,
        footer: String? = nil,
        @ViewBuilder accessory: @escaping () -> Accessory
    ) where Content == EmptyView {
        self.init(
            title: title,
            footer: footer,
            accessory: accessory,
            content: EmptyView.init
        )
    }

    @Environment(\.theme)
    var theme

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack {
                    Text(title)
                        .font(.callout.weight(.medium))
                        .foregroundColor(theme.textColor)
                    if let footer {
                        Text(footer)
                            .font(.footnote)
                            .foregroundColor(theme.textColor.opacity(0.5))
                    }
                }
                Spacer()
                accessory()
            }
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)

            content()
                .frame(maxWidth: .infinity)
                .safeAreaInset(edge: .leading) {
                    Color.clear
                        .frame(width: 0, height: 0, alignment: .leading)
                        .padding(.leading, 4)
                }
                .safeAreaInset(edge: .trailing) {
                    Color.clear
                        .frame(width: 0, height: 0, alignment: .trailing)
                        .padding(.trailing, 4)
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear
                        .frame(width: 0, height: 0, alignment: .trailing)
                        .padding(.bottom, 12)
                }
        }
        .frame(maxWidth: .infinity)
    }
}
