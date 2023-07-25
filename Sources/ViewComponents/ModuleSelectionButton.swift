//
//  ModuleSelectionCore.swift
//
//
//  Created by ErrorErrorError on 5/10/23.
//
//

import ComposableArchitecture
import Foundation
import NukeUI
import SharedModels
import SwiftUI

public struct ModuleSelectionButton: View {
    let module: Module.Manifest?
    let didTapped: () -> Void

    public init(
        module: Module.Manifest? = nil,
        didTapped: @escaping () -> Void
    ) {
        self.module = module
        self.didTapped = didTapped
    }

    public var body: some View {
        Button {
            didTapped()
        } label: {
            HStack {
                LazyImage(url: module?.icon.flatMap { .init(string: $0) }) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                    } else {
                        EmptyView()
                    }
                }

            Text(module?.name ?? "Unselected")
                Image(systemName: "chevron.up.chevron.down")
            }
            .fixedSize(horizontal: false, vertical: true)
            .font(.footnote.weight(.semibold))
            .padding(8)
            .padding(.vertical, 2)
            .padding(.horizontal, 4)
            .background(.ultraThinMaterial, in: Capsule())
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
