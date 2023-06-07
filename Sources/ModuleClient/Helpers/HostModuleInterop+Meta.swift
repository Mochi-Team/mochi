//
//  HostModuleInterop+Structs.swift
//  
//
//  Created by ErrorErrorError on 5/9/23.
//  
//

import Foundation
import SharedModels

// MARK: - Meta Struct Imports

// swiftlint:disable function_parameter_count
extension HostModuleInterop {
    func create_search_filter_option(
        option_id_ptr: RawPtr,
        option_id_len: Int32,
        name_ptr: RawPtr,
        name_len: Int32
    ) -> PtrRef {
        self.handleErrorAlloc { alloc in
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

    func create_search_filter(
        id_ptr: RawPtr,
        id_len: Int32,
        name_ptr: RawPtr,
        name_len: Int32,
        options_array_ref: PtrRef,
        multiselect: Int32,
        required: Int32
    ) -> PtrRef {
        self.handleErrorAlloc { alloc in
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

    func create_paging(
        items_array_ref_ptr: PtrRef,
        current_page_ptr: RawPtr,
        current_page_len: Int32,
        next_page_ptr: RawPtr,
        next_page_len: Int32
    ) -> PtrRef {
        handleErrorAlloc { alloc in
            guard let items = alloc[items_array_ref_ptr] as? [Any?] else {
                throw ModuleClient.Error.castError(
                    got: .init(describing: alloc[items_array_ref_ptr].self),
                    expected: .init(describing: [Any?].self)
                )
            }

            let currentPageStr = try memory.string(
                byteOffset: .init(current_page_ptr),
                length: .init(current_page_len)
            )

            let nextPageStr = try? memory.string(
                byteOffset: .init(next_page_ptr),
                length: .init(next_page_len)
            )

            return alloc.add(
                Paging(
                    items: items,
                    currentPage: currentPageStr,
                    nextPage: nextPageStr
                )
            )
        }
    }

    func create_discover_listing(
        title_ptr: RawPtr,
        title_len: Int32,
        listing_type: RawPtr,
        paging_ptr: PtrRef
    ) -> PtrRef {
        self.handleErrorAlloc { alloc in
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
                    paging: paging.into(Playlist.self)
                )
            )
        }
    }

    func create_playlist(
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

            return alloc.add(
                Playlist(
                    id: .init(idStr),
                    title: titleStr,
                    posterImage: posterImageStr.flatMap { .init(string: $0) },
                    bannerImage: bannerImageStr.flatMap { .init(string: $0) },
                    type: Playlist.PlaylistType(rawValue: .init(type)) ?? .video
                )
            )
        }
    }

    func create_playlist_details(
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
                .compactMap { $0 as? String  }

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
                .compactMap { alloc[.init($0)] as? Playlist.Preview }

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

    func create_playlist_preview(
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
                Playlist.Preview(
                    title: title,
                    description: description,
                    thumbnail: thumbnail.flatMap { .init(string: $0) },
                    link: linkURL,
                    type: .init(rawValue: .init(preview_type)) ?? .image
                )
            )
        }
    }

    func create_playlist_item(
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

    func create_playlist_items_response(
        content_ptr: PtrRef,
        all_groups_ptr: PtrRef
    ) -> PtrRef {
        handleErrorAlloc { alloc in
            guard let content = alloc[content_ptr] as? Playlist.Group.Content else {
                throw ModuleClient.Error.castError(
                    got: .init(describing: alloc[content_ptr].self),
                    expected: .init(describing: [Playlist.Group.Content].self)
                )
            }

            guard let all_groups = alloc[all_groups_ptr] as? [Playlist.Group] else {
                throw ModuleClient.Error.castError(
                    got: .init(describing: alloc[all_groups_ptr].self),
                    expected: .init(describing: [Playlist.Group].self)
                )
            }

            return alloc.add(
                Playlist.ItemsResponse(
                    content: content,
                    allGroups: all_groups
                )
            )
        }
    }

    func create_playlist_group(
        id: Float64,
        display_title_ptr: Int32,
        display_title_len: Int32
    ) -> PtrRef {
        handleErrorAlloc { alloc in
            let title = try? memory.string(byteOffset: .init(display_title_ptr), length: .init(display_title_len))
            return alloc.add(Playlist.Group(id: .init(id), displayTitle: title))
        }
    }

    func create_playlist_group_items(
        group_id: Float64,
        previous_group_id: Float64,
        next_group_id: Float64,
        items_ptr: PtrRef
    ) -> PtrRef {
        handleErrorAlloc { alloc in
            guard group_id >= 0 else {
                throw ModuleClient.Error.nullPtr()
            }

            guard let pointers = alloc[items_ptr] as? [Any?] else {
                throw ModuleClient.Error.castError()
            }

            let items = pointers.compactMap { pointer in
                if let pointer = pointer as? Int {
                    return alloc[.init(pointer)] as? Playlist.Item
                }
                return nil
            }

            return alloc.add(
                Playlist.Group.Content(
                    groupId: .init(group_id),
                    previousGroupId: previous_group_id >= 0 ? .init(previous_group_id) : nil,
                    nextGroupId: next_group_id >= 0 ? .init(next_group_id) : nil,
                    items: items
                )
            )
        }
    }
}
