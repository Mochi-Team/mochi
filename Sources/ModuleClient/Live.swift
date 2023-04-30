//
//  Live.swift
//
//
//  Created ErrorErrorError on 4/10/23.
//  Copyright © 2023. All rights reserved.
//

import Dependencies
import Foundation
import SharedModels
import WasmInterpreter

extension ModuleClient: DependencyKey {
    public static let liveValue = Self(
        searchFilters: { module in
            try await ModuleHandler(module: module)
                .searchFilters()
        },
        search: { module, query in
            try await ModuleHandler(module: module)
                .search(query)
        },
        getDiscoverListings: { module in
            try await ModuleHandler(module: module)
                .discoverListings()
        }
    )
}

struct ModuleHandler {
    private let module: Module
    private let instance: WasmInstance
    private let importHandlers: HostModuleIntercommunication<WasmInstance.Memory>

    init(module: Module) throws {
        self.module = module
        self.instance = try .init(module: module.binaryModule)
        self.importHandlers = .init(memory: instance.memory)
        initializeImports()
    }
}

/// Available method calls
///
extension ModuleHandler {
    func search(_ query: SearchQuery) async throws -> Paging<Media> {
        let queryPtr = self.importHandlers.addToHostMemory(query)
        let resultsPtr: Int32 = try instance.exports.search(queryPtr)

        if let values = importHandlers.getHostObject(resultsPtr) as? Paging<Media> {
            return values
        } else if let result = importHandlers.getHostObject(resultsPtr) as? ModuleClient.Error {
            throw result
        } else {
            throw ModuleClient.Error.nullPtr(for: #function)
        }
    }

    func discoverListings() async throws -> [DiscoverListing] {
        let resultsPtr: Int32 = try instance.exports.discovery_listing()

        if let values = importHandlers.getHostObject(resultsPtr) as? [DiscoverListing] {
            return values
        } else if let result = importHandlers.getHostObject(resultsPtr) as? ModuleClient.Error {
            throw result
        } else {
            throw ModuleClient.Error.nullPtr(for: #function)
        }
    }

    func searchFilters() async throws -> [SearchFilter] {
        let resultsPtr: Int32 = try instance.exports.search_filters()
        if let values = importHandlers.getHostObject(resultsPtr) as? [SearchFilter] {
            return values
        } else if let result = importHandlers.getHostObject(resultsPtr) as? ModuleClient.Error {
            throw result
        } else {
            throw ModuleClient.Error.nullPtr(for: #function)
        }
    }
}

private extension ModuleHandler {
    // swiftlint:disable closure_parameter_position function_body_length
    func initializeImports() {
        try? self.instance.importFunctions {

            // MARK: Core Imports

            WasmInstance.Import(namespace: "core") {
                WasmInstance.Function("copy") { [self] (
                    ptr: PtrRef
                ) -> Int32 in
                    importHandlers.copy(ptr: ptr)
                }

                WasmInstance.Function("destroy") { [self] (ptr: Int32) in
                    importHandlers.destroy(ptr: ptr)
                }

                WasmInstance.Function("create_array") { [self] () -> Int32 in
                    importHandlers.create_array()
                }

                WasmInstance.Function("create_obj") { [self] in
                    importHandlers.create_obj()
                }

                WasmInstance.Function("create_string") { [self] (
                    bufPtr: RawPtr,
                    bufLen: Int32
                ) -> Int32 in
                    importHandlers.create_string(buf_ptr: bufPtr, buf_len: bufLen)
                }

                WasmInstance.Function("create_bool") { [self] (
                    value: Int32
                ) -> Int32 in
                    importHandlers.create_bool(value: value)
                }

                WasmInstance.Function("create_float") { [self] (
                    value: Float64
                ) -> Int32 in
                    importHandlers.create_float(value: value)
                }

                WasmInstance.Function("create_int") { [self] (
                    value: Int64
                ) -> Int32 in
                    importHandlers.create_int(value: value)
                }

                WasmInstance.Function("create_error") { [self] () -> Int32 in
                    importHandlers.create_error()
                }

                WasmInstance.Function("ptr_kind") { [self] (
                    ptr: PtrRef
                ) -> PtrKind.RawValue in
                    importHandlers.ptr_kind(ptr: ptr)
                }

                WasmInstance.Function("string_len") { [self] (
                    ptr: Int32
                ) -> Int32 in
                    importHandlers.string_len(ptr: ptr)
                }

                WasmInstance.Function("read_string") { [self] (
                    ptr: Int32,
                    bufPtr: Int32,
                    bufLen: Int32
                ) in
                    importHandlers.read_string(ptr: ptr, buf_ptr: bufPtr, len: bufLen)
                }

                WasmInstance.Function("read_int") { [self] (
                    ptr: Int32
                ) -> Int64 in
                    importHandlers.read_int(ptr: ptr)
                }

                WasmInstance.Function("read_float") { [self] (
                    ptr: Int32
                ) -> Float64 in
                    importHandlers.read_float(ptr: ptr)
                }

                WasmInstance.Function("read_bool") { [self] (
                    ptr: Int32
                ) -> Int32 in
                    importHandlers.read_bool(ptr: ptr)
                }

                WasmInstance.Function("obj_len") { [self] (
                    ptr: Int32
                ) -> Int32 in
                    importHandlers.obj_len(ptr: ptr)
                }

                WasmInstance.Function("obj_get") { [self] (
                    ptr: PtrRef,
                    keyPtr: RawPtr,
                    keyLen: Int32
                ) -> Int32 in
                    importHandlers.obj_get(ptr: ptr, key_ptr: keyPtr, key_len: keyLen)
                }

                WasmInstance.Function("obj_set") { [self] (
                    ptr: PtrRef,
                    keyPtr: RawPtr,
                    keyLen: Int32,
                    valuePtr: PtrRef
                ) in
                    importHandlers.obj_set(ptr: ptr, key_ptr: keyPtr, key_len: keyLen, value_ptr: valuePtr)
                }

                WasmInstance.Function("obj_remove") { [self] (
                    ptr: Int32,
                    keyPtr: Int32,
                    keyLen: Int32
                ) in
                    importHandlers.obj_remove(ptr: ptr, key_ptr: keyPtr, key_len: keyLen)
                }

                WasmInstance.Function("obj_keys") { [self] (
                    ptr: PtrRef
                ) -> Int32 in
                    importHandlers.obj_keys(ptr: ptr)
                }

                WasmInstance.Function("obj_values") { [self] (
                    ptr: Int32
                ) -> Int32 in
                    importHandlers.obj_values(ptr: ptr)
                }

                WasmInstance.Function("array_len") { [self] (
                    ptr: Int32
                ) -> Int32 in
                    importHandlers.array_len(ptr: ptr)
                }

                WasmInstance.Function("array_get") { [self] (
                    ptr: PtrRef,
                    idx: Int32
                ) -> Int32 in
                    importHandlers.array_get(ptr: ptr, idx: idx)
                }

                WasmInstance.Function("array_set") { [self] (
                    ptr: Int32,
                    idx: Int32,
                    valuePtr: Int32
                ) in
                    importHandlers.array_set(ptr: ptr, idx: idx, value_ptr: valuePtr)
                }

                WasmInstance.Function("array_append") { [self] (
                    ptr: Int32,
                    valuePtr: Int32
                ) in
                    importHandlers.array_append(ptr: ptr, value_ptr: valuePtr)
                }

                WasmInstance.Function("array_remove") { [self] (
                    ptr: Int32,
                    idx: Int32
                ) in
                    importHandlers.array_remove(ptr: ptr, idx: idx)
                }
            }

            // MARK: HTTP Imports

            WasmInstance.Import(namespace: "http") {
                WasmInstance.Function("create") { [self] (method: Int32) -> Int32 in
                    importHandlers.request_create(method: method)
                }

                WasmInstance.Function("send") { [self] (ptr: ReqRef) in
                    importHandlers.request_send(ptr: ptr)
                }

                WasmInstance.Function("close") { [self] (ptr: ReqRef) in
                    importHandlers.request_close(ptr: ptr)
                }

                WasmInstance.Function("set_url") { [self] (
                    ptr: ReqRef,
                    urlPtr: Int32,
                    urlLen: Int32
                ) in
                    importHandlers.request_set_url(
                        ptr: ptr,
                        url_ptr: urlPtr,
                        url_len: urlLen
                    )
                }

                WasmInstance.Function("set_header") { [self] (
                    ptr: ReqRef,
                    keyPtr: Int32,
                    keyLen: Int32,
                    valuePtr: Int32,
                    valueLen: Int32
                ) in
                    importHandlers.request_set_header(
                        ptr: ptr,
                        key_ptr: keyPtr,
                        key_len: keyLen,
                        value_ptr: valuePtr,
                        value_len: valueLen
                    )
                }

                WasmInstance.Function("set_body") { [self] (
                    ptr: Int32,
                    dataPtr: Int32,
                    dataLen: Int32
                ) in
                    importHandlers.request_set_body(
                        ptr: ptr,
                        data_ptr: dataPtr,
                        data_len: dataLen
                    )
                }

                WasmInstance.Function("set_method") { [self] (
                    ptr: Int32,
                    method: Int32
                ) in
                    importHandlers.request_set_method(ptr: ptr, method: method)
                }

                WasmInstance.Function("get_method") { [self] (
                    ptr: Int32
                ) -> WasmRequest.Method.RawValue in
                    importHandlers.request_get_method(ptr: ptr)
                }

                WasmInstance.Function("get_url") { [self] (
                    ptr: Int32
                ) -> Int32 in
                    importHandlers.request_get_url(ptr: ptr)
                }

                WasmInstance.Function("get_header") { [self] (
                    ptr: Int32,
                    keyPtr: Int32,
                    keyLen: Int32
                ) -> Int32 in
                    importHandlers.request_get_header(ptr: ptr, key_ptr: keyPtr, key_len: keyLen)
                }

                WasmInstance.Function("get_status_code") { [self] (
                    ptr: Int32
                ) -> Int32 in
                    importHandlers.request_get_status_code(ptr: ptr)
                }

                WasmInstance.Function("get_data_len") { [self] (
                    ptr: ReqRef
                ) -> Int32 in
                    importHandlers.request_get_data_len(ptr: ptr)
                }

                WasmInstance.Function("get_data") { [self] (
                    ptr: Int32,
                    arrRef: Int32,
                    arrLen: Int32
                ) in
                    importHandlers.request_get_data(ptr: ptr, arr_ptr: arrRef, arr_len: arrLen)
                }
            }

            // MARK: JSON Imports

            WasmInstance.Import(namespace: "json") {
                WasmInstance.Function("json_parse") { [self] (
                    bufPtr: RawPtr,
                    bufLen: Int32
                ) -> Int32 in
                    importHandlers.json_parse(buf_ptr: bufPtr, buf_len: bufLen)
                }
            }

            // MARK: Mochi Structs Meta

            WasmInstance.Import(namespace: "structs_meta") {
                WasmInstance.Function("create_search_filters") { [self] (
                    filtersPtr: Int32,
                    filtersLen: Int32
                ) -> Int32 in
                    importHandlers.create_search_filters(
                        filters_ptr: filtersPtr,
                        filters_len: filtersLen
                    )
                }

                WasmInstance.Function("create_search_filter") { [self] (
                    idPtr: Int32,
                    idLen: Int32,
                    namePtr: Int32,
                    nameLen: Int32,
                    optionsPtr: Int32,
                    optionsLen: Int32,
                    multiSelect: Int32,
                    required: Int32
                ) -> Int32 in
                    importHandlers.create_search_filter(
                        id_ptr: idPtr,
                        id_len: idLen,
                        name_ptr: namePtr,
                        name_len: nameLen,
                        options_ptr: optionsPtr,
                        options_len: optionsLen,
                        multiselect: multiSelect,
                        required: required
                    )
                }

                WasmInstance.Function("create_search_filter_option") { [self] (
                    optionIdPtr: Int32,
                    optionIdLen: Int32,
                    namePtr: Int32,
                    nameLen: Int32
                ) -> Int32 in
                    importHandlers.create_search_filter_option(
                        option_id_ptr: optionIdPtr,
                        option_id_len: optionIdLen,
                        name_ptr: namePtr,
                        name_len: nameLen
                    )
                }

                WasmInstance.Function("create_media") { [self] (
                    idPtr: Int32,
                    idLen: Int32,
                    titlePtr: Int32,
                    titleLen: Int32,
                    posterImagePtr: RawPtr,
                    posterImageLen: Int32,
                    bannerImagePtr: RawPtr,
                    bannerImageLen: Int32,
                    meta: Int32
                ) -> Int32 in
                    importHandlers.create_media(
                        id_ptr: idPtr,
                        id_len: idLen,
                        title_ptr: titlePtr,
                        title_len: titleLen,
                        poster_image_ptr: posterImagePtr,
                        poster_image_len: posterImageLen,
                        banner_image_ptr: bannerImagePtr,
                        banner_image_len: bannerImageLen,
                        meta: meta
                    )
                }

                WasmInstance.Function("create_media_paging") { [self] (
                    itemsPtr: Int32,
                    itemsCount: Int32,
                    currentPagePtr: Int32,
                    currentPageLen: Int32,
                    nextPagePtr: Int32,
                    nextPageLen: Int32
                ) -> Int32 in
                    importHandlers.create_media_paging(
                        items_ptr: itemsPtr,
                        items_count: itemsCount,
                        current_page_ptr: currentPagePtr,
                        current_page_len: currentPageLen,
                        next_page_ptr: nextPagePtr,
                        next_page_len: nextPageLen
                    )
                }

                WasmInstance.Function("create_discover_listing") { [self] (
                    titlePtr: RawPtr,
                    titleLen: Int32,
                    listingType: RawPtr,
                    pagingPtr: PtrRef
                ) -> Int32 in
                    importHandlers.create_discover_listing(
                        title_ptr: titlePtr,
                        title_len: titleLen,
                        listing_type: listingType,
                        paging_ptr: pagingPtr
                    )
                }

                WasmInstance.Function("create_discover_listings") { [self] (
                    listingsPtr: RawPtr,
                    listingsLen: Int32
                ) -> Int32 in
                    importHandlers.create_discover_listings(
                        listings_ptr: listingsPtr,
                        listings_len: listingsLen
                    )
                }
            }
        }
    }
}
