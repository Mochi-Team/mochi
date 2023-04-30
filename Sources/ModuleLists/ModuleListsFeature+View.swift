//
//  ModuleListsFeature+View.swift
//  
//
//  Created ErrorErrorError on 4/23/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import NukeUI
import SharedModels
import SwiftUI

extension ModuleListsFeature.View: View {
    @MainActor
    public var body: some View {
        WithViewStore(
            store.viewAction,
            observe: \.repos
        ) { viewStore in
            VStack {
                if viewStore.isEmpty {
                    VStack(spacing: 12) {
                        Text("No modules installed")
                            .font(.headline.bold())

                        Text("Make sure you have modules installed in the repos tab.")
                            .font(.callout)
                            .multilineTextAlignment(.center)
                            .font(.body)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                } else {
                    ScrollView(.vertical) {
                        VStack(spacing: 24) {
                            ForEach(viewStore.state) { repo in
                                repoSection(repo)
                            }
                        }
                        .padding()
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity)
            .onAppear {
                viewStore.send(.didAppear)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

extension ModuleListsFeature.View {
    @MainActor
    func repoSection(_ repo: Repo) -> some View {
        VStack(spacing: 12) {
            HStack {
                LazyImage(url: repo.icon) { state in
                    if let image = state.image {
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                    } else if state.error != nil {
                        EmptyView()
                    } else {
                        Color.gray
                    }
                }

                VStack(alignment: .leading) {
                    Text(repo.name)
                        .font(.title3.bold())

                    Text(repo.author)
                        .font(.subheadline.bold())
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .fixedSize(horizontal: true, vertical: false)
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            VStack(spacing: 8) {
                if repo.modules.isEmpty {
                    VStack(spacing: 8) {
                        Text("No modules installed")
                            .font(.headline.bold())

                        Text("This repo does not contained any installed modules.")
                            .font(.callout)
                            .multilineTextAlignment(.center)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.16).cornerRadius(12))
                } else {
                    ForEach(repo.modules) { module in
                        Button {
                            ViewStore(store.viewAction.stateless)
                                .send(.didSelectModule(repo.id, module.id))
                        } label: {
                            moduleRow(module)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @MainActor
    func moduleRow(_ module: Module.Manifest) -> some View {
        HStack {
            LazyImage(url: module.icon) { state in
                if let image = state.image {
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                } else if state.error != nil {
                    EmptyView()
                } else {
                    Color.gray // Acts as a placeholder
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(module.name)
                    .font(.body.weight(.medium))

                Text(module.version)
                    .font(.footnote.weight(.medium))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: true, vertical: false)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
    }
}

import Styling

struct ModuleListsFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        SheetView(isPresenting: .constant(true)) {
            ModuleListsFeature.View(
                store: .init(
                    initialState: .init(
                        repos: [
                            .init(
                                repoURL: .init(string: "/").unsafelyUnwrapped,
                                manifest: .init(
                                    id: "local",
                                    name: "Local Repo",
                                    author: "errorerrorerror",
                                    description: "This is a local repo"
                                )
                            )
                        ],
                        selected: .init(repoId: "local", moduleId: "1")
                    ),
                    reducer: EmptyReducer()
                )
            )
        }
        .previewLayout(.sizeThatFits)
    }
}
