//
//  Bindings+Meta.swift
//
//
//  Created by ErrorErrorError on 5/9/23.
//
//

import Foundation
import SharedModels
import WasmInterpreter

// MARK: Meta Structs Imports

// swiftlint:disable closure_parameter_position
extension ModuleClient.WAInstance {
    func metaImports() -> WasmInstance.Import {
        WasmInstance.Import(namespace: "structs_meta") {
            WasmInstance.Function("create_search_filter_option") { [self] (
                optionIdPtr: RawPtr,
                optionIdLen: Int32,
                namePtr: RawPtr,
                nameLen: Int32
            ) -> PtrRef in
                hostBindings.meta_create_search_filter_option(
                    option_id_ptr: optionIdPtr,
                    option_id_len: optionIdLen,
                    name_ptr: namePtr,
                    name_len: nameLen
                )
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
                hostBindings.meta_create_search_filter(
                    id_ptr: idPtr,
                    id_len: idLen,
                    name_ptr: namePtr,
                    name_len: nameLen,
                    options_array_ref: optionsArrayRef,
                    multiselect: multiSelect,
                    required: required
                )
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
                hostBindings.meta_create_paging(
                    id_ptr: idPtr,
                    id_len: idLen,
                    previous_page_ptr: previousPagePtr,
                    previous_page_len: previousPageLen,
                    next_page_ptr: nextPagePtr,
                    next_page_len: nextPageLen,
                    items_ptr: itemsPtr
                )
            }

            WasmInstance.Function("create_discover_listing") { [self] (
                titlePtr: RawPtr,
                titleLen: Int32,
                listingType: RawPtr,
                pagingPtr: PtrRef
            ) -> PtrRef in
                hostBindings.meta_create_discover_listing(
                    title_ptr: titlePtr,
                    title_len: titleLen,
                    listing_type: listingType,
                    paging_ptr: pagingPtr
                )
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
                hostBindings.meta_create_playlist(
                    id_ptr: idPtr,
                    id_len: idLen,
                    title_ptr: titlePtr,
                    title_len: titleLen,
                    poster_image_ptr: posterImagePtr,
                    poster_image_len: posterImageLen,
                    banner_image_ptr: bannerImagePtr,
                    banner_image_len: bannerImageLen,
                    type: type
                )
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
                hostBindings.meta_create_playlist_details(
                    description_ptr: descriptionPtr,
                    description_len: descriptionLen,
                    alternative_titles_ptr: alternativeTitlesPtr,
                    alternative_posters_ptr: alternativePostersPtr,
                    alternative_banners_ptr: alternativeBannersPtr,
                    genres_ptr: genresPtr,
                    year_released: yearReleased,
                    ratings: ratings,
                    previews_ptr: previewsPtr
                )
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
                hostBindings.meta_create_playlist_preview(
                    title_ptr: title_ptr,
                    title_len: title_len,
                    description_ptr: description_ptr,
                    description_len: description_len,
                    thumbnail_ptr: thumbnail_ptr,
                    thumbnail_len: thumbnail_len,
                    link_ptr: link_ptr,
                    link_len: link_len,
                    preview_type: preview_type
                )
            }

            WasmInstance.Function("create_playlist_item") { [self] (
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
            ) -> PtrRef in
                hostBindings.meta_create_playlist_item(
                    id_ptr: id_ptr,
                    id_len: id_len,
                    title_ptr: title_ptr,
                    title_len: title_len,
                    description_ptr: description_ptr,
                    description_len: description_len,
                    thumbnail_ptr: thumbnail_ptr,
                    thumbnail_len: thumbnail_len,
                    number: number,
                    timestamp_ptr: timestamp_ptr,
                    timestamp_len: timestamp_len,
                    tags_ptr: tags_ptr
                )
            }

            WasmInstance.Function("create_playlist_items_response") { [self] (
                contents_ptr: PtrRef,
                all_groups_ptr: PtrRef
            ) -> PtrRef in
                hostBindings.meta_create_playlist_items_response(
                    contents_ptr: contents_ptr,
                    all_groups_ptr: all_groups_ptr
                )
            }

            WasmInstance.Function("create_playlist_group") { [self] (
                id: Float64,
                display_title_ptr: RawPtr,
                display_title_len: Int32
            ) -> PtrRef in
                hostBindings.meta_create_playlist_group(
                    id: id,
                    display_title_ptr: display_title_ptr,
                    display_title_len: display_title_len
                )
            }

            WasmInstance.Function("create_playlist_group_page") { (
                id_ptr: RawPtr,
                id_len: Int32,
                display_name_ptr: RawPtr,
                display_name_len: Int32
            ) -> PtrRef in
                hostBindings.meta_create_playlist_group_page(
                    id_ptr: id_ptr,
                    id_len: id_len,
                    display_name_ptr: display_name_ptr,
                    display_name_len: display_name_len
                )
            }

            WasmInstance.Function("create_playlist_group_items") { (
                group_id: Float64,
                pagings_ptr: PtrRef,
                all_pages_ptr: PtrRef
            ) -> Int32 in
                hostBindings.meta_create_playlist_group_items(
                    group_id: group_id,
                    pagings_ptr: pagings_ptr,
                    all_pages_ptr: all_pages_ptr
                )
            }
        }
    }
}

// swiftlint:enable closure_parameter_position
