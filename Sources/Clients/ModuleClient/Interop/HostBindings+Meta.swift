//
//  HostBindings+Meta.swift
//
//
//  Created by ErrorErrorError on 5/9/23.
//
//

import Foundation
import SharedModels

// MARK: - Meta Struct Imports

// swiftlint:disable function_parameter_count
extension HostBindings {
    func meta_create_search_filter_option(
        option_id_ptr: RawPtr,
        option_id_len: Int32,
        name_ptr: RawPtr,
        name_len: Int32
    ) -> PtrRef {
        handleErrorAlloc { alloc in
            let optionIdStr = try memory.string(
                byteOffset: Int(option_id_ptr),
                length: Int(option_id_len)
            )

            let nameStr = try memory.string(
                byteOffset: Int(name_ptr),
                length: Int(name_len)
            )

            return alloc.add(
                SearchFilter.Option(
                    id: .init(rawValue: optionIdStr),
                    displayName: nameStr
                )
            )
        }
    }

    func meta_create_search_filter(
        id_ptr: RawPtr,
        id_len: Int32,
        name_ptr: RawPtr,
        name_len: Int32,
        options_array_ref: PtrRef,
        multiselect: Int32,
        required: Int32
    ) -> PtrRef {
        handleErrorAlloc { alloc in
            let idStr = try memory.string(
                byteOffset: Int(id_ptr),
                length: Int(id_len)
            )

            let nameStr = try memory.string(
                byteOffset: Int(name_ptr),
                length: Int(name_len)
            )

            guard let options = alloc[options_array_ref] as? [SearchFilter.Option] else {
                throw ModuleClient.Error.castError(
                    got: .init(describing: alloc[options_array_ref].self),
                    expected: .init(describing: [SearchFilter.Option].self)
                )
            }

            return alloc.add(
                SearchFilter(
                    id: .init(rawValue: idStr),
                    displayName: nameStr,
                    multiSelect: multiselect != 0,
                    required: required != 0,
                    options: options
                )
            )
        }
    }

    func meta_create_paging(
        id_ptr: RawPtr,
        id_len: Int32,
        previous_page_ptr: RawPtr,
        previous_page_len: Int32,
        next_page_ptr: RawPtr,
        next_page_len: Int32,
        items_ptr: PtrRef
    ) -> PtrRef {
        handleErrorAlloc { alloc in
            let idStr = try memory.string(
                byteOffset: .init(id_ptr),
                length: .init(id_len)
            )

            let previousPageStr = try? memory.string(
                byteOffset: .init(previous_page_ptr),
                length: .init(previous_page_len)
            )

            let nextPageStr = try? memory.string(
                byteOffset: .init(next_page_ptr),
                length: .init(next_page_len)
            )

            guard let items = alloc[items_ptr] as? [Any?] else {
                throw ModuleClient.Error.castError(
                    got: .init(describing: alloc[items_ptr].self),
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

    func meta_create_discover_listing(
        title_ptr: RawPtr,
        title_len: Int32,
        listing_type: RawPtr,
        paging_ptr: PtrRef
    ) -> PtrRef {
        handleErrorAlloc { alloc in
            let title: String = try memory.string(
                byteOffset: .init(title_ptr),
                length: .init(title_len)
            )

            guard let paging = alloc[paging_ptr] as? Paging<Any?> else {
                throw ModuleClient.Error.castError(
                    got: .init(describing: alloc[paging_ptr].self),
                    expected: .init(describing: Paging<Playlist?>.self)
                )
            }

            return alloc.add(
                DiscoverListing(
                    title: title,
                    type: .init(rawValue: .init(listing_type)) ?? .default,
                    paging: paging.cast(Playlist.self)
                )
            )
        }
    }

    func meta_create_playlist(
        id_ptr: RawPtr,
        id_len: Int32,
        title_ptr: RawPtr,
        title_len: Int32,
        poster_image_ptr: RawPtr,
        poster_image_len: Int32,
        banner_image_ptr: RawPtr,
        banner_image_len: Int32,
        type: Int32
    ) -> PtrRef {
        handleErrorAlloc { alloc in
            let idStr = try memory.string(
                byteOffset: .init(id_ptr),
                length: .init(id_len)
            )

            let titleStr = try? memory.string(
                byteOffset: .init(title_ptr),
                length: .init(title_len)
            )

            let posterImageStr = try? memory.string(
                byteOffset: .init(poster_image_ptr),
                length: .init(poster_image_len)
            )

            let bannerImageStr = try? memory.string(
                byteOffset: .init(banner_image_ptr),
                length: .init(banner_image_len)
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

    func meta_create_playlist_details(
        description_ptr: RawPtr,
        description_len: Int32,
        alternative_titles_ptr: Int32,
        alternative_posters_ptr: Int32,
        alternative_banners_ptr: Int32,
        genres_ptr: Int32,
        year_released: Int32,
        ratings: Int32,
        previews_ptr: Int32
    ) -> PtrRef {
        handleErrorAlloc { alloc in
            let description = try? memory.string(
                byteOffset: .init(description_ptr),
                length: .init(description_len)
            )

            let alternativeTitles = (alloc[alternative_titles_ptr] as? [Any?])?
                .compactMap { $0 as? String }

            let alternativePosters = (alloc[alternative_posters_ptr] as? [Any?])?
                .compactMap { $0 as? String }
                .compactMap { URL(string: $0) }

            let alternativeBanners = (alloc[alternative_banners_ptr] as? [Any?])?
                .compactMap { $0 as? String }
                .compactMap { URL(string: $0) }

            let genres = (alloc[genres_ptr] as? [Any?])?
                .compactMap { $0 as? String }

            let previews = (alloc[previews_ptr] as? [Any?])?
                .compactMap { $0 as? Int }
                .compactMap { alloc[.init($0)] as? Playlist.Details.Preview }

            return alloc.add(
                Playlist.Details(
                    contentDescription: description,
                    alternativeTitles: alternativeTitles ?? [],
                    alternativePosters: alternativePosters ?? [],
                    alternativeBanners: alternativeBanners ?? [],
                    genres: genres ?? [],
                    yearReleased: year_released > 0 ? .init(year_released) : nil,
                    ratings: ratings >= 0 ? .init(ratings) : nil,
                    previews: previews ?? []
                )
            )
        }
    }

    func meta_create_playlist_preview(
        title_ptr: RawPtr,
        title_len: Int32,
        description_ptr: Int32,
        description_len: Int32,
        thumbnail_ptr: Int32,
        thumbnail_len: Int32,
        link_ptr: Int32,
        link_len: Int32,
        preview_type: Int32
    ) -> PtrRef {
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

    func meta_create_playlist_item(
        id_ptr: RawPtr,
        id_len: Int32,
        title_ptr: RawPtr,
        title_len: Int32,
        description_ptr: RawPtr,
        description_len: Int32,
        thumbnail_ptr: RawPtr,
        thumbnail_len: Int32,
        number: Float64,
        timestamp_ptr: RawPtr,
        timestamp_len: Int32,
        tags_ptr: PtrRef
    ) -> PtrRef {
        handleErrorAlloc { alloc in
            let id = try memory.string(
                byteOffset: .init(id_ptr),
                length: .init(id_len)
            )

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

            let timestamp = try? memory.string(
                byteOffset: .init(timestamp_ptr),
                length: .init(timestamp_len)
            )

            let tags = (alloc[tags_ptr] as? [Any?])?
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

    func meta_create_playlist_items_response(
        contents_ptr: PtrRef,
        all_groups_ptr: PtrRef
    ) -> PtrRef {
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

    func meta_create_playlist_group(
        id: Float64,
        display_title_ptr: Int32,
        display_title_len: Int32
    ) -> PtrRef {
        handleErrorAlloc { alloc in
            let title = try? memory.string(byteOffset: .init(display_title_ptr), length: .init(display_title_len))
            return alloc.add(Playlist.Group(id: .init(id), displayTitle: title))
        }
    }

    func meta_create_playlist_group_page(
        id_ptr: RawPtr,
        id_len: Int32,
        display_name_ptr: RawPtr,
        display_name_len: Int32
    ) -> PtrRef {
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

    func meta_create_playlist_group_items(
        group_id: Float64,
        pagings_ptr: Int32,
        all_pages_ptr: Int32
    ) -> PtrRef {
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
            let pages = pagesMemoryPtr.compactMap { ($0 as? Paging<Any?>)?.cast(Int.self).map { ptr in alloc[.init(ptr)] }.cast(Playlist.Item.self) }
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

// swiftlint:enable function_parameter_count
