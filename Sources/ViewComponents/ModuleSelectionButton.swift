//
//  ModuleSelectionCore.swift
//  
//
//  Created by ErrorErrorError on 5/10/23.
//  
//

import ComposableArchitecture
import Foundation
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
                Text(module?.name ?? "Unselected")
                Image(systemName: "chevron.up.chevron.down")
            }
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
