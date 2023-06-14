//
//  ModuleHandler.swift
//  
//
//  Created by ErrorErrorError on 6/3/23.
//  
//

import Foundation
import SharedModels
import WasmInterpreter

public struct ModuleHandler {
    private let module: Module
    private let instance: WasmInstance
    private let hostModuleComms: HostModuleInterop<WasmInstance.Memory>

    init(module: Module) throws {
        self.module = module
        self.instance = try .init(module: module.binaryModule)
        self.hostModuleComms = .init(memory: instance.memory)
        initializeImports()
    }
}

/// Available method calls
///
public extension ModuleHandler {
    func search(_ query: SearchQuery) async throws -> Paging<Playlist> {
        let queryPtr = self.hostModuleComms.addToHostMemory(query)
        let resultsPtr: Int32 = try instance.exports.search(queryPtr)

        if let paging = hostModuleComms.getHostObject(resultsPtr) as? Paging<Any?> {
            return paging.into()
        } else if let result = hostModuleComms.getHostObject(resultsPtr) as? ModuleClient.Error {
            throw result
        } else {
            throw ModuleClient.Error.nullPtr(for: #function)
        }
    }

    func discoverListings() async throws -> [DiscoverListing] {
        let resultsPtr: Int32 = try instance.exports.discover_listings()

        if let values = hostModuleComms.getHostObject(resultsPtr) as? [DiscoverListing] {
            return values
        } else if let result = hostModuleComms.getHostObject(resultsPtr) as? ModuleClient.Error {
            throw result
        } else {
            throw ModuleClient.Error.nullPtr(for: #function)
        }
    }

    func searchFilters() async throws -> [SearchFilter] {
        let resultsPtr: Int32 = try instance.exports.search_filters()
        if let values = hostModuleComms.getHostObject(resultsPtr) as? [SearchFilter] {
            return values
        } else if let result = hostModuleComms.getHostObject(resultsPtr) as? ModuleClient.Error {
            throw result
        } else {
            throw ModuleClient.Error.nullPtr(for: #function)
        }
    }

    func playlistDetails(_ id: Playlist.ID) async throws -> Playlist.Details {
        let idPtr = self.hostModuleComms.addToHostMemory(id)
        let resultsPtr: Int32 = try instance.exports.playlist_details(idPtr)

        if let details = hostModuleComms.getHostObject(resultsPtr) as? Playlist.Details {
            return details
        } else if let result = hostModuleComms.getHostObject(resultsPtr) as? ModuleClient.Error {
            throw result
        } else {
            throw ModuleClient.Error.nullPtr(for: #function)
        }
    }

    func playlistVideos(_ request: Playlist.ItemsRequest) async throws -> Playlist.ItemsResponse {
        let requestPtr = hostModuleComms.addToHostMemory(request)
        let resultsPtr: Int32 = try instance.exports.playlist_episodes(requestPtr)

        if let response = hostModuleComms.getHostObject(resultsPtr) as? Playlist.ItemsResponse {
            return response
        } else if let result = hostModuleComms.getHostObject(resultsPtr) as? ModuleClient.Error {
            throw result
        } else {
            throw ModuleClient.Error.nullPtr()
        }
    }

    func playlistVideoSources(_ request: Playlist.EpisodeSourcesRequest) async throws -> [Playlist.EpisodeSource] {
        let requestPtr = hostModuleComms.addToHostMemory(request)
        let resultsPtr: Int32 = try instance.exports.playlist_episode_sources(requestPtr)

        if let response = hostModuleComms.getHostObject(resultsPtr) as? [Playlist.EpisodeSource] {
            return response
        } else if let result = hostModuleComms.getHostObject(resultsPtr) as? ModuleClient.Error {
            throw result
        } else {
            throw ModuleClient.Error.nullPtr()
        }
    }

    func playlistVideoServer(_ request: Playlist.EpisodeServerRequest) async throws -> Playlist.EpisodeServerResponse {
        let requestPtr = hostModuleComms.addToHostMemory(request)
        let resultsPtr: Int32 = try instance.exports.playlist_episode_server(requestPtr)

        if let response = hostModuleComms.getHostObject(resultsPtr) as? Playlist.EpisodeServerResponse {
            return response
        } else if let result = hostModuleComms.getHostObject(resultsPtr) as? ModuleClient.Error {
            throw result
        } else {
            throw ModuleClient.Error.nullPtr()
        }
    }
}

extension ModuleHandler {
    func initializeImports() {
        try? self.instance.importFunctions {
            self.envImports()
            self.coreImports()
            self.httpImports()
            self.jsonImports()
            self.htmlImports()
            self.cryptoImports()
            self.metaStructsImports()
            self.videoStructsImports()
        }
    }
}

extension ModuleHandler {
    func envImports() -> WasmInstance.Import {
        WasmInstance.Import(namespace: "env") {
            WasmInstance.Function("print") { (string_ptr: Int32, string_len: Int32) in
                hostModuleComms.print(string_ptr: string_ptr, string_len: string_len)
            }
        }
    }
}

// MARK: Core Imports

// swiftlint:disable closure_parameter_position
extension ModuleHandler {
    func coreImports() -> WasmInstance.Import {
        WasmInstance.Import(namespace: "core") {
            WasmInstance.Function("copy") { [self] (
                ptr: PtrRef
            ) -> Int32 in
                hostModuleComms.copy(ptr: ptr)
            }

            WasmInstance.Function("destroy") { [self] (ptr: Int32) in
                hostModuleComms.destroy(ptr: ptr)
            }

            WasmInstance.Function("create_array") { [self] () -> Int32 in
                hostModuleComms.create_array()
            }

            WasmInstance.Function("create_obj") { [self] in
                hostModuleComms.create_obj()
            }

            WasmInstance.Function("create_string") { [self] (
                bufPtr: RawPtr,
                bufLen: Int32
            ) -> Int32 in
                hostModuleComms.create_string(buf_ptr: bufPtr, buf_len: bufLen)
            }

            WasmInstance.Function("create_bool") { [self] (
                value: Int32
            ) -> Int32 in
                hostModuleComms.create_bool(value: value)
            }

            WasmInstance.Function("create_float") { [self] (
                value: Float64
            ) -> Int32 in
                hostModuleComms.create_float(value: value)
            }

            WasmInstance.Function("create_int") { [self] (
                value: Int64
            ) -> Int32 in
                hostModuleComms.create_int(value: value)
            }

            WasmInstance.Function("create_error") { [self] () -> Int32 in
                hostModuleComms.create_error()
            }

            WasmInstance.Function("ptr_kind") { [self] (
                ptr: PtrRef
            ) -> PtrKind.RawValue in
                hostModuleComms.ptr_kind(ptr: ptr)
            }

            WasmInstance.Function("string_len") { [self] (
                ptr: Int32
            ) -> Int32 in
                hostModuleComms.string_len(ptr: ptr)
            }

            WasmInstance.Function("read_string") { [self] (
                ptr: Int32,
                bufPtr: Int32,
                bufLen: Int32
            ) in
                hostModuleComms.read_string(ptr: ptr, buf_ptr: bufPtr, len: bufLen)
            }

            WasmInstance.Function("read_int") { [self] (
                ptr: Int32
            ) -> Int64 in
                hostModuleComms.read_int(ptr: ptr)
            }

            WasmInstance.Function("read_float") { [self] (
                ptr: Int32
            ) -> Float64 in
                hostModuleComms.read_float(ptr: ptr)
            }

            WasmInstance.Function("read_bool") { [self] (
                ptr: Int32
            ) -> Int32 in
                hostModuleComms.read_bool(ptr: ptr)
            }

            WasmInstance.Function("obj_len") { [self] (
                ptr: Int32
            ) -> Int32 in
                hostModuleComms.obj_len(ptr: ptr)
            }

            WasmInstance.Function("obj_get") { [self] (
                ptr: PtrRef,
                keyPtr: RawPtr,
                keyLen: Int32
            ) -> Int32 in
                hostModuleComms.obj_get(ptr: ptr, key_ptr: keyPtr, key_len: keyLen)
            }

            WasmInstance.Function("obj_set") { [self] (
                ptr: PtrRef,
                keyPtr: RawPtr,
                keyLen: Int32,
                valuePtr: PtrRef
            ) in
                hostModuleComms.obj_set(ptr: ptr, key_ptr: keyPtr, key_len: keyLen, value_ptr: valuePtr)
            }

            WasmInstance.Function("obj_remove") { [self] (
                ptr: Int32,
                keyPtr: Int32,
                keyLen: Int32
            ) in
                hostModuleComms.obj_remove(ptr: ptr, key_ptr: keyPtr, key_len: keyLen)
            }

            WasmInstance.Function("obj_keys") { [self] (
                ptr: PtrRef
            ) -> Int32 in
                hostModuleComms.obj_keys(ptr: ptr)
            }

            WasmInstance.Function("obj_values") { [self] (
                ptr: Int32
            ) -> Int32 in
                hostModuleComms.obj_values(ptr: ptr)
            }

            WasmInstance.Function("array_len") { [self] (
                ptr: Int32
            ) -> Int32 in
                hostModuleComms.array_len(ptr: ptr)
            }

            WasmInstance.Function("array_get") { [self] (
                ptr: PtrRef,
                idx: Int32
            ) -> Int32 in
                hostModuleComms.array_get(ptr: ptr, idx: idx)
            }

            WasmInstance.Function("array_set") { [self] (
                ptr: Int32,
                idx: Int32,
                valuePtr: Int32
            ) in
                hostModuleComms.array_set(ptr: ptr, idx: idx, value_ptr: valuePtr)
            }

            WasmInstance.Function("array_append") { [self] (
                ptr: Int32,
                valuePtr: Int32
            ) in
                hostModuleComms.array_append(ptr: ptr, value_ptr: valuePtr)
            }

            WasmInstance.Function("array_remove") { [self] (
                ptr: Int32,
                idx: Int32
            ) in
                hostModuleComms.array_remove(ptr: ptr, idx: idx)
            }
        }
    }
}

// MARK: HTTP Imports

extension ModuleHandler {
    func httpImports() -> WasmInstance.Import {
        WasmInstance.Import(namespace: "http") {
            WasmInstance.Function("create") { [self] (method: Int32) -> Int32 in
                hostModuleComms.request_create(method: method)
            }

            WasmInstance.Function("send") { [self] (ptr: ReqRef) in
                hostModuleComms.request_send(ptr: ptr)
            }

            WasmInstance.Function("close") { [self] (ptr: ReqRef) in
                hostModuleComms.request_close(ptr: ptr)
            }

            WasmInstance.Function("set_url") { [self] (
                ptr: ReqRef,
                urlPtr: Int32,
                urlLen: Int32
            ) in
                hostModuleComms.request_set_url(
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
                hostModuleComms.request_set_header(
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
                hostModuleComms.request_set_body(
                    ptr: ptr,
                    data_ptr: dataPtr,
                    data_len: dataLen
                )
            }

            WasmInstance.Function("set_method") { [self] (
                ptr: Int32,
                method: Int32
            ) in
                hostModuleComms.request_set_method(ptr: ptr, method: method)
            }

            WasmInstance.Function("get_method") { [self] (
                ptr: Int32
            ) -> WasmRequest.Method.RawValue in
                hostModuleComms.request_get_method(ptr: ptr)
            }

            WasmInstance.Function("get_url") { [self] (
                ptr: Int32
            ) -> Int32 in
                hostModuleComms.request_get_url(ptr: ptr)
            }

            WasmInstance.Function("get_header") { [self] (
                ptr: Int32,
                keyPtr: Int32,
                keyLen: Int32
            ) -> Int32 in
                hostModuleComms.request_get_header(ptr: ptr, key_ptr: keyPtr, key_len: keyLen)
            }

            WasmInstance.Function("get_status_code") { [self] (
                ptr: Int32
            ) -> Int32 in
                hostModuleComms.request_get_status_code(ptr: ptr)
            }

            WasmInstance.Function("get_data_len") { [self] (
                ptr: ReqRef
            ) -> Int32 in
                hostModuleComms.request_get_data_len(ptr: ptr)
            }

            WasmInstance.Function("get_data") { [self] (
                ptr: Int32,
                arrRef: Int32,
                arrLen: Int32
            ) in
                hostModuleComms.request_get_data(ptr: ptr, arr_ptr: arrRef, arr_len: arrLen)
            }
        }
    }
}

// MARK: JSON Imports

extension ModuleHandler {
    func jsonImports() -> WasmInstance.Import {
        WasmInstance.Import(namespace: "json") {
            WasmInstance.Function("json_parse") { [self] (
                bufPtr: RawPtr,
                bufLen: Int32
            ) -> Int32 in
                hostModuleComms.json_parse(buf_ptr: bufPtr, buf_len: bufLen)
            }
        }
    }
}

// MARK: HTML Imports

extension ModuleHandler {
    func htmlImports() -> WasmInstance.Import {
        WasmInstance.Import(namespace: "html") {
            WasmInstance.Function("parse") { (
                strPtr: RawPtr,
                strLen: Int32
            ) -> Int32 in
                hostModuleComms.scraper_parse(string_ptr: strPtr, string_len: strLen)
            }

            WasmInstance.Function("parse_with_uri") { (
                strPtr: RawPtr,
                strLen: Int32,
                uriPtr: RawPtr,
                uriLen: Int32
            ) -> Int32 in
                hostModuleComms.scraper_parse_with_uri(
                    string_ptr: strPtr,
                    string_len: strLen,
                    base_uri_ptr: uriPtr,
                    base_uri_len: uriLen
                )
            }

            WasmInstance.Function("parse_fragment") { (
                strPtr: RawPtr,
                strLen: Int32
            ) -> Int32 in
                hostModuleComms.scraper_parse(string_ptr: strPtr, string_len: strLen)
            }

            WasmInstance.Function("parse_fragment_with_uri") { (
                strPtr: RawPtr,
                strLen: Int32,
                uriPtr: RawPtr,
                uriLen: Int32
            ) -> Int32 in
                hostModuleComms.scraper_parse_with_uri(
                    string_ptr: strPtr,
                    string_len: strLen,
                    base_uri_ptr: uriPtr,
                    base_uri_len: uriLen
                )
            }

            WasmInstance.Function("select") { (
                ptr: PtrRef,
                strPtr: RawPtr,
                strLen: Int32
            ) -> Int32 in
                hostModuleComms.scraper_select(
                    ptr: ptr,
                    selector_ptr: strPtr,
                    selector_len: strLen
                )
            }

            WasmInstance.Function("attr") { (
                ptr: PtrRef,
                strPtr: RawPtr,
                strLen: Int32
            ) -> Int32 in
                hostModuleComms.scraper_attr(
                    ptr: ptr,
                    selector_ptr: strPtr,
                    selector_len: strLen
                )
            }

            WasmInstance.Function("set_text") { (
                ptr: PtrRef,
                strPtr: RawPtr,
                strLen: Int32
            ) -> Int32 in
                hostModuleComms.scraper_set_text(
                    ptr: ptr,
                    text: strPtr,
                    text_len: strLen
                )
            }

            WasmInstance.Function("set_html") { (
                ptr: PtrRef,
                strPtr: RawPtr,
                strLen: Int32
            ) -> Int32 in
                hostModuleComms.scraper_set_html(
                    ptr: ptr,
                    html: strPtr,
                    html_len: strLen
                )
            }

            WasmInstance.Function("prepend") { (
                ptr: PtrRef,
                strPtr: RawPtr,
                strLen: Int32
            ) -> Int32 in
                hostModuleComms.scraper_prepend(
                    ptr: ptr,
                    html: strPtr,
                    html_len: strLen
                )
            }

            WasmInstance.Function("append") { (
                ptr: PtrRef,
                strPtr: RawPtr,
                strLen: Int32
            ) -> Int32 in
                hostModuleComms.scraper_append(
                    ptr: ptr,
                    html: strPtr,
                    html_len: strLen
                )
            }

            WasmInstance.Function("first") { (ptr: PtrRef) -> PtrRef in
                hostModuleComms.scraper_first(ptr: ptr)
            }

            WasmInstance.Function("last") { (ptr: PtrRef) -> PtrRef in
                hostModuleComms.scraper_last(ptr: ptr)
            }

            WasmInstance.Function("next") { (ptr: PtrRef) -> PtrRef in
                hostModuleComms.scraper_next(ptr: ptr)
            }

            WasmInstance.Function("previous") { (ptr: PtrRef) -> PtrRef in
                hostModuleComms.scraper_previous(ptr: ptr)
            }

            WasmInstance.Function("base_uri") { (ptr: PtrRef) -> PtrRef in
                hostModuleComms.scraper_base_uri(ptr: ptr)
            }

            WasmInstance.Function("body") { (ptr: PtrRef) -> PtrRef in
                hostModuleComms.scraper_body(ptr: ptr)
            }

            WasmInstance.Function("text") { (ptr: PtrRef) -> PtrRef in
                hostModuleComms.scraper_text(ptr: ptr)
            }

            WasmInstance.Function("untrimmed_text") { (ptr: PtrRef) -> PtrRef in
                hostModuleComms.scraper_untrimmed_text(ptr: ptr)
            }

            WasmInstance.Function("own_text") { (ptr: PtrRef) -> PtrRef in
                hostModuleComms.scraper_own_text(ptr: ptr)
            }

            WasmInstance.Function("data") { (ptr: PtrRef) -> PtrRef in
                hostModuleComms.scraper_data(ptr: ptr)
            }

            WasmInstance.Function("array") { (ptr: PtrRef) -> PtrRef in
                hostModuleComms.scraper_array(ptr: ptr)
            }

            WasmInstance.Function("html") { (ptr: PtrRef) -> PtrRef in
                hostModuleComms.scraper_html(ptr: ptr)
            }

            WasmInstance.Function("outer_html") { (ptr: PtrRef) -> PtrRef in
                hostModuleComms.scraper_outer_html(ptr: ptr)
            }

            WasmInstance.Function("escape") { (ptr: PtrRef) -> PtrRef in
                hostModuleComms.scraper_escape(ptr: ptr)
            }

            WasmInstance.Function("unescape") { (ptr: PtrRef) -> PtrRef in
                hostModuleComms.scraper_unescape(ptr: ptr)
            }

            WasmInstance.Function("id") { (ptr: PtrRef) -> PtrRef in
                hostModuleComms.scraper_id(ptr: ptr)
            }

            WasmInstance.Function("tag_name") { (ptr: PtrRef) -> PtrRef in
                hostModuleComms.scraper_tag_name(ptr: ptr)
            }

            WasmInstance.Function("class_name") { (ptr: PtrRef) -> PtrRef in
                hostModuleComms.scraper_class_name(ptr: ptr)
            }

            WasmInstance.Function("has_class") { (
                ptr: PtrRef,
                classNamePtr: RawPtr,
                classNameLen: Int32
            ) -> Int32 in
                hostModuleComms.scraper_has_class(ptr: ptr, class_name_ptr: classNamePtr, class_name_length: classNameLen)
            }

            WasmInstance.Function("has_attr") { (
                ptr: PtrRef,
                attrNamePtr: RawPtr,
                attrNameLen: Int32
            ) -> Int32 in
                hostModuleComms.scraper_has_attr(
                    ptr: ptr,
                    attr_name_ptr: attrNamePtr,
                    attr_name_length: attrNameLen
                )
            }
        }
    }
}

// MARK: Crypto

extension ModuleHandler {
    func cryptoImports() -> WasmInstance.Import {
        WasmInstance.Import(namespace: "crypto") {
            WasmInstance.Function("crypto_get_data_len") { [self] (
                hostPtr: Int32
            ) -> Int32 in
                hostModuleComms.crypot_get_data_len(host_data_ptr: hostPtr)
            }

            WasmInstance.Function("crypto_get_data") { [self] (
                hostPtr: Int32,
                bufPtr: Int32,
                bufLen: Int32
            ) in
                hostModuleComms.crypto_get_data(
                    host_data_ptr: hostPtr,
                    buf_ptr: bufPtr,
                    buf_len: bufLen
                )
            }

            WasmInstance.Function("crypto_base64_parse") { [self] (
                valuePtr: Int32,
                valueLen: Int32
            ) -> Int32 in
                hostModuleComms.crypto_base64_parse(
                    value_ptr: valuePtr,
                    value_len: valueLen
                )
            }

            WasmInstance.Function("crypto_base64_string") { [self] (
                bytesPtr: Int32,
                bytesLen: Int32
            ) -> Int32 in
                hostModuleComms.crypto_base64_string(
                    bytes_ptr: bytesPtr,
                    bytes_len: bytesLen
                )
            }

            WasmInstance.Function("crypto_utf8_parse") { [self] (
                valuePtr: Int32,
                valueLen: Int32
            ) -> Int32 in
                hostModuleComms.crypto_utf8_parse(
                    value_ptr: valuePtr,
                    value_len: valueLen
                )
            }

            WasmInstance.Function("crypto_pbkdf2") { [self] (
                hashFunction: Int32,
                passwordPtr: Int32,
                passwordLen: Int32,
                saltPtr: Int32,
                saltLen: Int32,
                rounds: Int32,
                keyCount: Int32
            ) -> Int32 in
                hostModuleComms.crypto_pbkdf2(
                    hash_algorithm: .init(hashFunction),
                    password_ptr: passwordPtr,
                    password_len: passwordLen,
                    salt_ptr: saltPtr,
                    salt_len: saltLen,
                    rounds: rounds,
                    key_count: keyCount
                )
            }

            WasmInstance.Function("crypto_md5_hash") { [self] (
                inputPtr: Int32,
                inputLen: Int32
            ) -> Int32 in
                hostModuleComms.crypto_md5_hash(input_ptr: .init(inputPtr), input_len: .init(inputLen))
            }

            WasmInstance.Function("crypto_generate_random_bytes") { [self] (
                count: Int32
            ) -> Int32 in
                hostModuleComms.crypto_generate_random_bytes(count: count)
            }

            WasmInstance.Function("crypto_aes_encrypt") { [self] (
                msgPtr: Int32,
                msgLen: Int32,
                keyPtr: Int32,
                keyLen: Int32,
                ivPtr: Int32,
                ivLen: Int32
            ) -> Int32 in
                hostModuleComms.crypto_aes_encrypt(
                    msg_buf_ptr: msgPtr,
                    msg_buf_len: msgLen,
                    key_ptr: keyPtr,
                    key_len: keyLen,
                    iv_ptr: ivPtr,
                    iv_len: ivLen
                )
            }

            WasmInstance.Function("crypto_aes_decrypt") { [self] (
                msgPtr: Int32,
                msgLen: Int32,
                keyPtr: Int32,
                keyLen: Int32,
                ivPtr: Int32,
                ivLen: Int32
            ) -> Int32 in
                hostModuleComms.crypto_aes_decrypt(
                    encrypted_msg_ptr: msgPtr,
                    encrypted_msg_len: msgLen,
                    key_ptr: keyPtr,
                    key_len: keyLen,
                    iv_ptr: ivPtr,
                    iv_len: ivLen
                )
            }
        }
    }
}

// MARK: Meta Structs Imports

extension ModuleHandler {
    func metaStructsImports() -> WasmInstance.Import {
        WasmInstance.Import(namespace: "structs_meta") {
            WasmInstance.Function("create_search_filter_option") { [self] (
                optionIdPtr: RawPtr,
                optionIdLen: Int32,
                namePtr: RawPtr,
                nameLen: Int32
            ) -> PtrRef in
                hostModuleComms.create_search_filter_option(
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
                hostModuleComms.create_search_filter(
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
                itemsArrayRefPtr: PtrRef,
                currentPagePtr: RawPtr,
                currentPageLen: Int32,
                nextPagePtr: RawPtr,
                nextPageLen: Int32
            ) -> PtrRef in
                hostModuleComms.create_paging(
                    items_array_ref_ptr: itemsArrayRefPtr,
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
            ) -> PtrRef in
                hostModuleComms.create_discover_listing(
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
                hostModuleComms.create_playlist(
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
                hostModuleComms.create_playlist_details(
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
                hostModuleComms.create_playlist_preview(
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
                hostModuleComms.create_playlist_item(
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
                content_ptr: PtrRef,
                all_groups_ptr: PtrRef
            ) -> PtrRef in
                hostModuleComms.create_playlist_items_response(
                    content_ptr: content_ptr,
                    all_groups_ptr: all_groups_ptr
                )
            }

            WasmInstance.Function("create_playlist_group") { [self] (
                id: Float64,
                display_title_ptr: RawPtr,
                display_title_len: Int32
            ) -> PtrRef in
                hostModuleComms.create_playlist_group(
                    id: id,
                    display_title_ptr: display_title_ptr,
                    display_title_len: display_title_len
                )
            }

            WasmInstance.Function("create_playlist_group_items") { [self] (
                group_id: Float64,
                previous_group_id: Float64,
                next_group_id: Float64,
                items_ptr: PtrRef
            ) -> Int32 in
                hostModuleComms.create_playlist_group_items(
                    group_id: group_id,
                    previous_group_id: previous_group_id,
                    next_group_id: next_group_id,
                    items_ptr: items_ptr
                )
            }
        }
    }
}

// MARK: Video Structs Imports

extension ModuleHandler {
    func videoStructsImports() -> WasmInstance.Import {
        WasmInstance.Import(namespace: "structs_video") {
            WasmInstance.Function("create_episode_source") { [self] (
                idPtr: Int32,
                idLen: Int32,
                displayNamePtr: Int32,
                displayNameLen: Int32,
                descriptionPtr: Int32,
                descriptionLen: Int32,
                serversPtr: Int32
            ) -> Int32 in
                hostModuleComms.create_episode_source(
                    id_ptr: idPtr,
                    id_len: idLen,
                    display_name_ptr: displayNamePtr,
                    display_name_len: displayNameLen,
                    description_ptr: descriptionPtr,
                    description_len: descriptionLen,
                    servers_ptr: serversPtr
                )
            }

            WasmInstance.Function("create_episode_server") { [self] (
                idPtr: Int32,
                idLen: Int32,
                displayNamePtr: Int32,
                displayNameLen: Int32,
                descriptionPtr: Int32,
                descriptionLen: Int32
            ) -> Int32 in
                hostModuleComms.create_episode_server(
                    id_ptr: idPtr,
                    id_len: idLen,
                    display_name_ptr: displayNamePtr,
                    display_name_len: displayNameLen,
                    description_ptr: descriptionPtr,
                    description_len: descriptionLen
                )
            }

            WasmInstance.Function("create_episode_server_response") { [self] (
                linksPtr: Int32,
                subtitlesPtr: Int32
            ) -> Int32 in
                hostModuleComms.create_episode_server_response(
                    links_ptr: linksPtr,
                    subtitles_ptr: subtitlesPtr
                )
            }

            WasmInstance.Function("create_episode_server_link") { [self] (
                urlPtr: Int32,
                urlLen: Int32,
                quality: Int32,
                format: Int32
            ) -> Int32 in
                hostModuleComms.create_episode_server_link(
                    url_ptr: urlPtr,
                    url_len: urlLen,
                    quality: quality,
                    format: format
                )
            }

            WasmInstance.Function("create_episode_server_subtitle") { [self] (
                urlPtr: Int32,
                urlLen: Int32,
                languagePtr: Int32,
                languageLen: Int32,
                format: Int32
            ) -> Int32 in
                hostModuleComms.create_episode_server_subtitle(
                    url_ptr: urlPtr,
                    url_len: urlLen,
                    language_ptr: languagePtr,
                    language_len: languageLen,
                    format: format
                )
            }
        }
    }
}
