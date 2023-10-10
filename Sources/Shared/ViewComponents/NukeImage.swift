//
//  NukeImage.swift
//
//
//  Created by ErrorErrorError on 10/10/23.
//  
//

import Foundation
import Nuke
import NukeUI
import SwiftUI

@MainActor
public struct NukeImage<Content: View>: View {
    @StateObject private var viewModel = FetchImage()
    private var request: ImageRequest?
    private var content: (AsyncImagePhase) -> Content

    @MainActor
    public init(url: URL? = nil, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.init(request: url.flatMap { .init(url: $0) }, content: content)
    }

    @MainActor
    public init(request: URLRequest? = nil, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.content = content
        self.request = request.flatMap { .init(urlRequest: $0) }
    }

    @MainActor
    public var body: some View {
        ZStack {
            if let result = viewModel.result {
                switch result {
                case .success(let success):
                    content(.success(Image(success.image)))
                case .failure(let failure):
                    content(.failure(failure))
                }
            } else {
                content(.empty)
            }
        }
        .onAppear { viewModel.load(request) }
        .onDisappear { viewModel.cancel() }
        .onChange(of: request) { value in viewModel.load(value) }
    }
}

extension ImageRequest: Equatable {
    public static func == (lhs: Nuke.ImageRequest, rhs: Nuke.ImageRequest) -> Bool {
        lhs.urlRequest == rhs.urlRequest &&
        lhs.options == rhs.options &&
        lhs.priority == rhs.priority 
//        &&
//        lhs.processors == rhs.processors
    }
}
