//
//  HostModuleInterop+Structs.swift
//
//
//  Created by ErrorErrorError on 5/9/23.
//
//

import Foundation
import SharedModels
import WasmInterpreter

// MARK: Meta Structs Imports

// swiftlint:disable function_body_length closure_parameter_position closure_parameter_position
extension ModuleClient.Instance {
    func metaStructsImports() -> WasmInstance.Import {
        WasmInstance.Import(namespace: "structs_meta") {
            WasmInstance.Function("create_search_filter_option") { [self] (
                optionIdPtr: RawPtr,
                optionIdLen: Int32,
                namePtr: RawPtr,
                nameLen: Int32
            ) -> PtrRef in
                handleErrorAlloc { alloc in
                    let optionIdStr = try memory.string(
                        byteOffset: Int(optionIdPtr),
                        length: Int(optionIdLen)
                    )

                    let nameStr = try memory.string(
                        byteOffset: Int(namePtr),
                        length: Int(nameLen)
                    )

                    return alloc.add(
                        SearchFilter.Option(
                            id: .init(rawValue: optionIdStr),
                            displayName: nameStr
                        )
                    )
                }
            }

            WasmInstance.Function("create_search_filter") { [self] (
                idPtr: Int32,
                idLen: Int32,
                namePtr: Int32,
                nameLen: Int32,
                optionsArrayRef: Int32,
                multiSelect: Int32,
                required: Int32
            ) -> PtrRef in
                handleErrorAlloc { alloc in
                    let idStr = try memory.string(
                        byteOffset: Int(idPtr),
                        length: Int(idLen)
                    )

                    let nameStr = try memory.string(
                        byteOffset: Int(namePtr),
                        length: Int(nameLen)
                    )

                    guard let options = alloc[optionsArrayRef] as? [SearchFilter.Option] else {
                        throw ModuleClient.Error.castError(
                            got: .init(describing: alloc[optionsArrayRef].self),
                            expected: .init(describing: [SearchFilter.Option].self)
                        )
                    }

                    return alloc.add(
                        SearchFilter(
                            id: .init(rawValue: idStr),
                            displayName: nameStr,
                            multiSelect: multiSelect != 0,
                            required: `required` != 0,
                            options: options
                        )
                    )
                }
            }

            WasmInstance.Function("create_paging") { [self] (
                idPtr: RawPtr,
                idLen: Int32,
                previousPagePtr: RawPtr,
                previousPageLen: Int32,
                nextPagePtr: RawPtr,
                nextPageLen: Int32,
                itemsPtr: PtrRef
            ) -> PtrRef in
                handleErrorAlloc { alloc in
                    let idStr = try memory.string(
                        byteOffset: .init(idPtr),
                        length: .init(idLen)
                    )

                    let previousPageStr = try? memory.string(
                        byteOffset: .init(previousPagePtr),
                        length: .init(previousPageLen)
                    )

                    let nextPageStr = try? memory.string(
                        byteOffset: .init(nextPagePtr),
                        length: .init(nextPageLen)
                    )

                    guard let items = alloc[itemsPtr] as? [Any?] else {
                        throw ModuleClient.Error.castError(
                            got: .init(describing: alloc[itemsPtr].self),
                            expected: .init(describing: [Any?].self)
                        )
                    }

                    return alloc.add(
                        Paging(
                            id: .init(idStr),
                            previousPage: previousPageStr.flatMap { .init($0) },
                            nextPage: nextPageStr.flatMap { .init($0) },
                            items: items
                        )
                    )
                }
            }

            WasmInstance.Function("create_discover_listing") { [self] (
                titlePtr: RawPtr,
                titleLen: Int32,
                listingType: RawPtr,
                pagingPtr: PtrRef
            ) -> PtrRef in
                handleErrorAlloc { alloc in
                    let title: String = try memory.string(
                        byteOffset: .init(titlePtr),
                        length: .init(titleLen)
                    )

                    guard let paging = alloc[pagingPtr] as? Paging<Any?> else {
                        throw ModuleClient.Error.castError(
                            got: .init(describing: alloc[pagingPtr].self),
                            expected: .init(describing: Paging<Playlist?>.self)
                        )
                    }

                    return alloc.add(
                        DiscoverListing(
                            title: title,
                            type: .init(rawValue: .init(listingType)) ?? .default,
                            paging: paging.cast(Playlist.self)
                        )
                    )
                }
            }

            WasmInstance.Function("create_playlist") { [self] (
                idPtr: RawPtr,
                idLen: Int32,
                titlePtr: RawPtr,
                titleLen: Int32,
                posterImagePtr: RawPtr,
                posterImageLen: Int32,
                bannerImagePtr: RawPtr,
                bannerImageLen: Int32,
                type: Int32
            ) -> PtrRef in
                handleErrorAlloc { alloc in
                    let idStr = try memory.string(
                        byteOffset: .init(idPtr),
                        length: .init(idLen)
                    )

                    let titleStr = try? memory.string(
                        byteOffset: .init(titlePtr),
                        length: .init(titleLen)
                    )

                    let posterImageStr = try? memory.string(
                        byteOffset: .init(posterImagePtr),
                        length: .init(posterImageLen)
                    )

                    let bannerImageStr = try? memory.string(
                        byteOffset: .init(bannerImagePtr),
                        length: .init(bannerImageLen)
                    )

                    // TODO: Add URL and Status
        //            let url = try memory.string(byteOffset: url_ptr, length: url_len)
        //            let status = Playlist.Status.init(rawValue: <#T##Int#>) ?? .unknown

                    return alloc.add(
                        Playlist(
                            id: .init(idStr),
                            title: titleStr,
                            posterImage: posterImageStr.flatMap { .init(string: $0) },
                            bannerImage: bannerImageStr.flatMap { .init(string: $0) },
                            url: .init(string: "/").unsafelyUnwrapped,
                            status: .unknown,
                            type: Playlist.PlaylistType(rawValue: .init(type)) ?? .video
                        )
                    )
                }
            }

            WasmInstance.Function("create_playlist_details") { [self] (
                descriptionPtr: RawPtr,
                descriptionLen: Int32,
                alternativeTitlesPtr: PtrRef,
                alternativePostersPtr: PtrRef,
                alternativeBannersPtr: PtrRef,
                genresPtr: PtrRef,
                yearReleased: Int32,
                ratings: Int32,
                previewsPtr: PtrRef
            ) -> PtrRef in
                handleErrorAlloc { alloc in
                    let description = try? memory.string(
                        byteOffset: .init(descriptionPtr),
                        length: .init(descriptionLen)
                    )

                    let alternativeTitles = (alloc[alternativeTitlesPtr] as? [Any?])?
                        .compactMap { $0 as? String }

                    let alternativePosters = (alloc[alternativePostersPtr] as? [Any?])?
                        .compactMap { $0 as? String }
                        .compactMap { URL(string: $0) }

                    let alternativeBanners = (alloc[alternativeBannersPtr] as? [Any?])?
                        .compactMap { $0 as? String }
                        .compactMap { URL(string: $0) }

                    let genres = (alloc[genresPtr] as? [Any?])?
                        .compactMap { $0 as? String }

                    let previews = (alloc[previewsPtr] as? [Any?])?
                        .compactMap { $0 as? Int }
                        .compactMap { alloc[.init($0)] as? Playlist.Details.Preview }

                    return alloc.add(
                        Playlist.Details(
                            contentDescription: description,
                            alternativeTitles: alternativeTitles ?? [],
                            alternativePosters: alternativePosters ?? [],
                            alternativeBanners: alternativeBanners ?? [],
                            genres: genres ?? [],
                            yearReleased: yearReleased > 0 ? .init(yearReleased) : nil,
                            ratings: ratings >= 0 ? .init(ratings) : nil,
                            previews: previews ?? []
                        )
                    )
                }
            }

            WasmInstance.Function("create_playlist_preview") { [self] (
                title_ptr: RawPtr,
                title_len: Int32,
                description_ptr: RawPtr,
                description_len: Int32,
                thumbnail_ptr: RawPtr,
                thumbnail_len: Int32,
                link_ptr: RawPtr,
                link_len: Int32,
                preview_type: Int32
            ) -> PtrRef in
                handleErrorAlloc { alloc in
                    let title = try? memory.string(
                        byteOffset: .init(title_ptr),
                        length: .init(title_len)
                    )

                    let description = try? memory.string(
                        byteOffset: .init(description_ptr),
                        length: .init(description_len)
                    )

                    let thumbnail = try? memory.string(
                        byteOffset: .init(thumbnail_ptr),
                        length: .init(thumbnail_len)
                    )

                    let link = try memory.string(
                        byteOffset: .init(link_ptr),
                        length: .init(link_len)
                    )

                    guard let linkURL = URL(string: link) else {
                        throw ModuleClient.Error.nullPtr(message: "Link url is not valid")
                    }

                    return alloc.add(
                        Playlist.Details.Preview(
                            title: title,
                            description: description,
                            thumbnail: thumbnail.flatMap { .init(string: $0) },
                            link: linkURL,
                            type: .init(rawValue: .init(preview_type)) ?? .image
                        )
                    )
                }
            }

            WasmInstance.Function("create_playlist_item") { [self] (
                idPtr: RawPtr,
                idLen: Int32,
                titlePtr: RawPtr,
                titleLen: Int32,
                descriptionPtr: RawPtr,
                descriptionLen: Int32,
                thumbnailPtr: RawPtr,
                thumbnailLen: Int32,
                number: Float64,
                timestampPtr: RawPtr,
                timestampLen: Int32,
                tagsPtr: PtrRef
            ) -> PtrRef in
                handleErrorAlloc { alloc in
                    let id = try memory.string(
                        byteOffset: .init(idPtr),
                        length: .init(idLen)
                    )

                    let title = try? memory.string(
                        byteOffset: .init(titlePtr),
                        length: .init(titleLen)
                    )

                    let description = try? memory.string(
                        byteOffset: .init(descriptionPtr),
                        length: .init(descriptionLen)
                    )

                    let thumbnail = try? memory.string(
                        byteOffset: .init(thumbnailPtr),
                        length: .init(thumbnailLen)
                    )

                    let timestamp = try? memory.string(
                        byteOffset: .init(timestampPtr),
                        length: .init(timestampLen)
                    )

                    let tags = (alloc[tagsPtr] as? [Any?])?
                        .compactMap { $0 as? String }

                    return alloc.add(
                        Playlist.Item(
                            id: .init(id),
                            title: title,
                            description: description,
                            thumbnail: thumbnail.flatMap { .init(string: $0) },
                            number: number,
                            timestamp: timestamp,
                            tags: tags ?? []
                        )
                    )
                }
            }

            WasmInstance.Function("create_playlist_items_response") { [self] (
                contents_ptr: PtrRef,
                all_groups_ptr: PtrRef
            ) -> PtrRef in
                handleErrorAlloc { alloc in
                    guard let contents = alloc[contents_ptr] as? [Playlist.Group.Content] else {
                        throw ModuleClient.Error.castError(
                            got: .init(describing: alloc[contents_ptr].self),
                            expected: .init(describing: [Playlist.Group.Content].self)
                        )
                    }

                    guard let allGroups = alloc[all_groups_ptr] as? [Playlist.Group] else {
                        throw ModuleClient.Error.castError(
                            got: .init(describing: alloc[all_groups_ptr].self),
                            expected: .init(describing: [Playlist.Group].self)
                        )
                    }

                    return alloc.add(
                        Playlist.ItemsResponse(
                            contents: contents,
                            allGroups: allGroups
                        )
                    )
                }
            }

            WasmInstance.Function("create_playlist_group") { [self] (
                id: Float64,
                display_title_ptr: RawPtr,
                display_title_len: Int32
            ) -> PtrRef in
                handleErrorAlloc { alloc in
                    let title = try? memory.string(byteOffset: .init(display_title_ptr), length: .init(display_title_len))
                    return alloc.add(Playlist.Group(id: .init(id), displayTitle: title))
                }
            }

            WasmInstance.Function("create_playlist_group_page") { (
                id_ptr: RawPtr,
                id_len: Int32,
                display_name_ptr: RawPtr,
                display_name_len: Int32
            ) -> PtrRef in
                handleErrorAlloc { alloc in
                    let id = try memory.string(
                        byteOffset: .init(id_ptr),
                        length: .init(id_len)
                    )

                    let displayName = try memory.string(
                        byteOffset: .init(display_name_ptr),
                        length: .init(display_name_len)
                    )

                    return alloc.add(Playlist.Group.Content.Page(id: .init(id), displayName: displayName))
                }
            }

            WasmInstance.Function("create_playlist_group_items") { (
                group_id: Float64,
                pagings_ptr: PtrRef,
                all_pages_ptr: PtrRef
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    guard group_id >= 0 else {
                        throw ModuleClient.Error.nullPtr()
                    }

                    guard pagings_ptr >= 0 else {
                        throw ModuleClient.Error.nullPtr()
                    }

                    guard all_pages_ptr >= 0 else {
                        throw ModuleClient.Error.nullPtr()
                    }

                    guard let pagesMemoryPtr = alloc[pagings_ptr] as? [Any?] else {
                        throw ModuleClient.Error.castError()
                    }

                    guard let allPagesMemoryPtr = alloc[all_pages_ptr] as? [Any?] else {
                        throw ModuleClient.Error.castError()
                    }

                    // TODO: Improve paging
                    let pages = pagesMemoryPtr.compactMap { ($0 as? Paging<Any?>)?
                        .cast(Int.self)
                        .map(to: { ptr in alloc[.init(ptr)] })
                        .cast(Playlist.Item.self) }
                    let allPages = allPagesMemoryPtr.compactMap { $0 as? Playlist.Group.Content.Page }

                    return alloc.add(
                        Playlist.Group.Content(
                            groupId: .init(group_id),
                            pagings: pages,
                            allPagesInfo: allPages
                        )
                    )
                }
            }
        }
    }
}
