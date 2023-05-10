//
//  Live+Imports+Structs.swift
//  
//
//  Created by ErrorErrorError on 5/9/23.
//  
//

import Foundation
import SharedModels

// MARK: - Meta Struct Imports

// swiftlint:disable function_parameter_count
extension HostModuleIntercommunication {
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
                throw ModuleClient.Error.castError(for: "\(#function): [SearchFilter.Options]")
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

    func create_media(
        id_ptr: RawPtr,
        id_len: Int32,
        title_ptr: RawPtr,
        title_len: Int32,
        poster_image_ptr: RawPtr,
        poster_image_len: Int32,
        banner_image_ptr: RawPtr,
        banner_image_len: Int32,
        meta: Int32
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
                Media(
                    id: .init(idStr),
                    title: titleStr,
                    posterImage: posterImageStr.flatMap { .init(string: $0) },
                    bannerImage: bannerImageStr.flatMap { .init(string: $0) },
                    meta: Media.Meta(rawValue: .init(meta)) ?? .video
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
                throw ModuleClient.Error.castError(for: "\(#function): [Media]")
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
                throw ModuleClient.Error.castError()
            }

            return alloc.add(
                DiscoverListing(
                    title: title,
                    type: .init(rawValue: .init(listing_type)) ?? .default,
                    paging: paging.into(Media.self)
                )
            )
        }
    }
}
