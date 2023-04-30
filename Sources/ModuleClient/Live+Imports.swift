//
//  File.swift
//
//
//  Created by ErrorErrorError on 4/25/23.
//
//

import ComposableArchitecture
import Foundation
import SharedModels
import WasmInterpreter

/// This is a raw pointer that points into wasm's memory
///
typealias RawPtr = Int32

/// This is a pointer that points to an object stored in host's memory
///
typealias PtrRef = Int32

/// This is a pointer that points to a host's network request memory
///
typealias ReqRef = Int32

enum PtrKind: Int32 {
    case unknown
    case null
    case object
    case array
    case string
    case number
    case bool
}

enum HTTPMethod: Int32 {
    case get
    case post
    case put
    case patch
    case delete
}

/// This class allows testability of models memory/transformations.
///
struct HostModuleIntercommunication<M: MemoryInstance> {
    let memory: M

    private let hostAllocations = LockIsolated<[PtrRef: Any]>([:])

    init(memory: M) {
        self.memory = memory
    }

    func addToHostMemory(_ obj: Any) -> PtrRef {
        hostAllocations.withValue { $0.add(obj) }
    }

    func getHostObject(_ ptr: PtrRef) -> Any? {
        hostAllocations[ptr]
    }
}

// MARK: - Core Imports

extension HostModuleIntercommunication {
    func copy(ptr: PtrRef) -> PtrRef {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                return ptr
            }

            guard let value = alloc[ptr] else {
                throw ModuleClient.Error.nullPtr()
            }
            return alloc.add(value)
        }
    }

    func destroy(ptr: PtrRef) {
        self.hostAllocations.withValue { alloc in
            alloc[ptr] = nil
        }
    }

    func create_array() -> PtrRef {
        self.hostAllocations.withValue { alloc in
            alloc.add([AnyHashable?]())
        }
    }

    func create_obj() -> PtrRef {
        self.hostAllocations.withValue { $0.add([AnyHashable: AnyHashable]()) }
    }

    func create_string(buf_ptr: RawPtr, buf_len: Int32) -> PtrRef {
        self.handleErrorAlloc { alloc in
            let string = try memory.string(
                byteOffset: Int(buf_ptr),
                length: Int(buf_len)
            )

            return alloc.add(string)
        }
    }

    func create_bool(value: Int32) -> PtrRef {
        self.hostAllocations.withValue { alloc in
            alloc.add(value != 0)
        }
    }

    func create_float(value: Float64) -> PtrRef {
        self.hostAllocations.withValue { alloc in
            alloc.add(Float(value))
        }
    }

    func create_int(value: Int64) -> PtrRef {
        self.hostAllocations.withValue { alloc in
            alloc.add(Int(value))
        }
    }

    func create_error() -> PtrRef {
        self.hostAllocations.withValue { alloc in
            alloc.addError(.unknown)
        }
    }

    func ptr_kind(ptr: PtrRef) -> Int32 {
        self.hostAllocations.withValue { alloc in
            guard ptr >= 0 else {
                return PtrKind.null.rawValue
            }

            let value = alloc[ptr]

            if value == nil || value is NSNull {
                return PtrKind.null.rawValue
            } else if value is Int || value is Float || value is NSNumber {
                return PtrKind.number.rawValue
            } else if value is String {
                return PtrKind.string.rawValue
            } else if value is Bool {
                return PtrKind.bool.rawValue
            } else if value is [Any?] {
                return PtrKind.array.rawValue
            } else if value is [String: Any] || value is KVAccess {
                return PtrKind.object.rawValue
            } else {
                return PtrKind.unknown.rawValue
            }
        }
    }

    func string_len(ptr: PtrRef) -> Int32 {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                return ptr
            }

            guard alloc[ptr] != nil else {
                throw ModuleClient.Error.nullPtr()
            }

            guard let string = alloc[ptr] as? String else {
                throw ModuleClient.Error.castError()
            }

            return Int32(string.utf8.count)
        }
    }

    func read_string(ptr: PtrRef, buf_ptr: RawPtr, len: Int32) {
        self.hostAllocations.withValue { alloc in
            guard ptr >= 0, len >= 0 else {
                return
            }

            guard let string = alloc[ptr] as? String else {
                return
            }

            try? memory.write(
                with: string.utf8.dropLast(string.utf8.count - Int(len)),
                byteOffset: Int(buf_ptr)
            )
        }
    }

    func read_int(ptr: PtrRef) -> Int64 {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                return Int64(ptr)
            }

            guard let value = alloc[ptr] else {
                throw ModuleClient.Error.nullPtr()
            }

            if let int = value as? Int {
                return Int64(int)
            } else if let float = value as? Float {
                return Int64(float)
            } else if let int = Int(value as? String ?? "Error") {
                return Int64(int)
            } else if let bool = value as? Bool {
                return Int64(bool ? 1 : 0)
            } else if let number = value as? NSNumber {
                return number.int64Value
            }

            throw ModuleClient.Error.castError()
        }
    }

    func read_float(ptr: PtrRef) -> Float64 {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                return .init(ptr)
            }

            guard let value = alloc[ptr] else {
                throw ModuleClient.Error.nullPtr()
            }

            if let float = value as? Float {
                return Float64(float)
            } else if let int = value as? Int {
                return Float64(int)
            } else if let float = Float(value as? String ?? "Error") {
                return Float64(float)
            } else if let bool = value as? Bool {
                return Float64(bool ? 1 : 0)
            } else if let number = value as? NSNumber {
                return Float64(number.doubleValue)
            }

            throw ModuleClient.Error.castError()
        }
    }

    func read_bool(ptr: PtrRef) -> Int32 {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0, let value = alloc[ptr] else {
                return 0
            }

            if let bool = value as? Bool {
                return Int32(bool ? 1 : 0)
            } else if let value = value as? Int {
                return Int32(value != 0 ? 1 : 0)
            } else if let value = value as? Float {
                return Int32(value != 0 ? 1 : 0)
            }
            return 0
        }
    }

    func obj_len(ptr: PtrRef) -> Int32 {
        self.hostAllocations.withValue { alloc in
            guard ptr >= 0, let obj = alloc[ptr] else {
                return 0
            }

            return Int32((obj as? [String: Any])?.count ?? 0)
        }
    }

    func obj_get(ptr: PtrRef, key_ptr: RawPtr, key_len: Int32) -> PtrRef {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                return ptr
            }

            guard let obj = alloc[ptr] else {
                throw ModuleClient.Error.nullPtr()
            }

            let key = try memory.string(
                byteOffset: Int(key_ptr),
                length: Int(key_len)
            )

            if let obj = obj as? [String: Any], let value = obj[key] {
                return alloc.add(value)
            } else if let obj = obj as? KVAccess, let value = obj[key] {
                return alloc.add(value)
            } else {
                throw ModuleClient.Error.castError()
            }
        }
    }

    func obj_set(ptr: PtrRef, key_ptr: RawPtr, key_len: Int32, value_ptr: PtrRef) {
        self.hostAllocations.withValue { alloc in
            guard ptr >= 0, var obj = alloc[ptr] as? [String: Any] else {
                return
            }

            guard value_ptr >= 0, let value = alloc[value_ptr] else {
                return
            }

            guard let key = try? memory.string(
                byteOffset: Int(key_ptr),
                length: Int(key_len)
            ) else {
                return
            }

            obj[key] = value
            alloc[ptr] = obj
        }
    }

    func obj_remove(ptr: PtrRef, key_ptr: RawPtr, key_len: Int32) {
        self.hostAllocations.withValue { alloc in
            guard ptr >= 0, var obj = alloc[ptr] as? [String: Any] else {
                return
            }

            guard let key = try? memory.string(
                byteOffset: Int(key_ptr),
                length: Int(key_len)
            ) else {
                return
            }

            obj[key] = nil
            alloc[ptr] = obj
        }
    }

    func obj_keys(ptr: PtrRef) -> PtrRef {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                return ptr
            }

            guard alloc[ptr] != nil else {
                throw ModuleClient.Error.nullPtr()
            }

            guard let obj = alloc[ptr] as? [String: Any] else {
                throw ModuleClient.Error.castError()
            }

            return alloc.add(Array(obj.keys))
        }
    }

    func obj_values(ptr: PtrRef) -> PtrRef {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                return ptr
            }

            guard alloc[ptr] != nil else {
                throw ModuleClient.Error.nullPtr()
            }

            guard let obj = alloc[ptr] as? [String: Any] else {
                throw ModuleClient.Error.castError()
            }

            return alloc.add(Array(obj.values))
        }
    }

    func array_len(ptr: PtrRef) -> Int32 {
        self.hostAllocations.withValue { alloc in
            guard ptr >= 0, let array = alloc[ptr] as? [Any] else {
                return 0
            }

            return Int32(array.count)
        }
    }

    func array_get(ptr: PtrRef, idx: Int32) -> PtrRef {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                return ptr
            }

            guard idx >= 0 else {
                throw ModuleClient.Error.indexOutOfBounds
            }

            guard alloc[ptr] != nil else {
                throw ModuleClient.Error.nullPtr()
            }

            guard let array = alloc[ptr] as? [Any] else {
                throw ModuleClient.Error.castError()
            }

            if array.indices.contains(Int(idx)) {
                return alloc.add(array[Int(idx)])
            }
            throw ModuleClient.Error.indexOutOfBounds
        }
    }

    func array_set(ptr: PtrRef, idx: Int32, value_ptr: PtrRef) {
        self.hostAllocations.withValue { alloc in
            guard ptr >= 0, idx >= 0, value_ptr >= 0 else {
                return
            }

            guard var array = alloc[ptr] as? [Any] else {
                return
            }

            guard let value = alloc[value_ptr] else {
                return
            }

            if array.indices.contains(Int(idx)) {
                array[Int(idx)] = value
            }

            alloc[ptr] = array
        }
    }

    func array_append(ptr: PtrRef, value_ptr: PtrRef) {
        self.hostAllocations.withValue { alloc in
            guard ptr >= 0, value_ptr >= 0 else {
                return
            }

            guard var array = alloc[ptr] as? [Any] else {
                return
            }

            guard let value = alloc[value_ptr] else {
                return
            }

            array.append(value)

            alloc[ptr] = array
        }
    }

    func array_remove(ptr: PtrRef, idx: Int32) {
        self.hostAllocations.withValue { alloc in
            guard ptr >= 0, idx >= 0 else {
                return
            }

            guard var array = alloc[ptr] as? [Any] else {
                return
            }

            if array.indices.contains(Int(idx)) {
                array.remove(at: Int(idx))
            }

            alloc[ptr] = array
        }
    }
}

// MARK: - HTTP Imports

extension HostModuleIntercommunication {
    func request_create(method: Int32) -> ReqRef {
        self.hostAllocations.withValue { alloc in
            alloc.add(WasmRequest(method: .init(rawValue: method) ?? .GET))
        }
    }

    func request_send(ptr: ReqRef) {
        self.hostAllocations.withValue { alloc in
            guard var request = alloc[ptr] as? WasmRequest else {
                return
            }

            guard let urlRequest = request.generateURLRequest() else {
                return
            }

            let semaphore = DispatchSemaphore(value: 0)
            var response: WasmRequest.Response?
            defer { alloc[ptr] = request }

            let dataTask = URLSession.shared.dataTask(with: urlRequest) { data, resp, error in
                defer { semaphore.signal() }

                guard let httpResponse = resp as? HTTPURLResponse else {
                    return
                }

                if let error {
                    response = .init(
                        statusCode: httpResponse.statusCode,
                        data: nil,
                        error: error
                    )
                }

                if let data {
                    response = .init(
                        statusCode: httpResponse.statusCode,
                        data: data,
                        error: nil
                    )
                }
            }
            dataTask.resume()
            semaphore.wait()

            request.response = response
        }
    }

    func request_close(ptr: ReqRef) {
        self.hostAllocations.withValue { $0[ptr] = nil }
    }

    func request_set_url(ptr: ReqRef, url_ptr: RawPtr, url_len: Int32) {
        self.hostAllocations.withValue { alloc in
            guard var request = alloc[ptr] as? WasmRequest else {
                return
            }

            request.url = try? memory.string(
                byteOffset: Int(url_ptr),
                length: Int(url_len)
            )

            alloc[ptr] = request
        }
    }

    func request_set_header(ptr: ReqRef, key_ptr: RawPtr, key_len: Int32, value_ptr: RawPtr, value_len: Int32) {
        self.hostAllocations.withValue { alloc in
            guard var request = alloc[ptr] as? WasmRequest else {
                return
            }

            guard let header = try? memory.string(
                byteOffset: Int(key_ptr),
                length: Int(key_len)
            ) else {
                return
            }

            guard let value = try? memory.string(
                byteOffset: Int(value_ptr),
                length: Int(value_len)
            ) else {
                return
            }

            request.headers[header] = value

            alloc[ptr] = request
        }
    }

    func request_set_body(ptr: ReqRef, data_ptr: PtrRef, data_len: Int32) {
        self.hostAllocations.withValue { alloc in
            guard var request = alloc[ptr] as? WasmRequest else {
                return
            }

            request.body = try? memory.data(
                byteOffset: Int(data_ptr),
                length: Int(data_len)
            )

            alloc[ptr] = request
        }
    }

    func request_set_method(ptr: ReqRef, method: Int32) {
        self.hostAllocations.withValue { alloc in
            guard var request = alloc[ptr] as? WasmRequest else {
                return
            }

            request.method = .init(rawValue: method) ?? .GET

            alloc[ptr] = request
        }
    }

    func request_get_method(ptr: ReqRef) -> Int32 {
        self.hostAllocations.withValue { alloc in
            guard let request = alloc[ptr] as? WasmRequest else {
                return WasmRequest.Method.GET.rawValue
            }
            return request.method.rawValue
        }
    }

    func request_get_url(ptr: ReqRef) -> PtrRef {
        self.handleErrorAlloc { alloc in
            guard let request = alloc[ptr] as? WasmRequest else {
                throw ModuleClient.Error.castError()
            }

            guard let url = request.url else {
                throw ModuleClient.Error.nullPtr()
            }

            return alloc.add(url)
        }
    }

    func request_get_header(ptr: ReqRef, key_ptr: RawPtr, key_len: Int32) -> PtrRef {
        self.handleErrorAlloc { alloc in
            guard let request = alloc[ptr] as? WasmRequest else {
                throw ModuleClient.Error.castError()
            }

            let key = try memory.string(
                byteOffset: Int(key_ptr),
                length: Int(key_len)
            )

            guard let value = request.headers[key] else {
                throw ModuleClient.Error.nullPtr()
            }

            return alloc.add(value)
        }
    }

    func request_get_status_code(ptr: ReqRef) -> Int32 {
        self.handleErrorAlloc { alloc in
            guard let request = alloc[ptr] as? WasmRequest else {
                throw ModuleClient.Error.castError()
            }

            guard let statusCode = request.response?.statusCode else {
                throw ModuleClient.Error.nullPtr()
            }

            return .init(statusCode)
        }
    }

    func request_get_data_len(ptr: ReqRef) -> Int32 {
        self.hostAllocations.withValue { alloc in
            guard let request = alloc[ptr] as? WasmRequest else {
                return 0
            }

            guard let data = request.response?.data else {
                return 0
            }

            return Int32(data.count)
        }
    }

    func request_get_data(ptr: ReqRef, arr_ptr: PtrRef, arr_len: Int32) {
        self.hostAllocations.withValue { alloc in
            guard let request = alloc[ptr] as? WasmRequest else {
                return
            }

            guard let data = request.response?.data else {
                return
            }

            try? memory.write(
                with: data.dropLast(data.count - Int(arr_len)),
                byteOffset: Int(arr_ptr)
            )
        }
    }
}

// MARK: - JSON Imports

extension HostModuleIntercommunication {
    func json_parse(buf_ptr: RawPtr, buf_len: Int32) -> PtrRef {
        self.handleErrorAlloc { alloc in
            let jsonData = try memory.data(
                byteOffset: Int(buf_ptr),
                length: Int(buf_len)
            )

            guard let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) else {
                throw ModuleClient.Error.nullPtr()
            }

            if let json = jsonObject as? [String: Any] {
                return alloc.add(json)
            } else if let json = jsonObject as? [Any] {
                return alloc.add(json)
            } else {
                throw ModuleClient.Error.castError()
            }
        }
    }
}

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

            let nameStr = try? memory.string(
                byteOffset: Int(name_ptr),
                length: Int(name_len)
            )

            return alloc.add(
                SearchFilter.Option.init(
                    id: .init(rawValue: optionIdStr),
                    displayName: nameStr ?? ""
                )
            )
        }
    }

    func create_search_filter(
        id_ptr: RawPtr,
        id_len: Int32,
        name_ptr: RawPtr,
        name_len: Int32,
        options_ptr: RawPtr,
        options_len: Int32,
        multiselect: Int32,
        required: Int32
    ) -> PtrRef {
        self.handleErrorAlloc { alloc in
            let idStr = try memory.string(
                byteOffset: Int(id_ptr),
                length: Int(id_len)
            )

            let nameStr = (try? memory.string(
                byteOffset: Int(name_ptr),
                length: Int(name_len)
            )) ?? ""

            let optionsArrPtr: [Int32] = (try? memory.values(
                byteOffset: Int(options_ptr),
                length: Int(options_len)
            )) ?? []

            let options = optionsArrPtr
                .compactMap { alloc[$0] as? SearchFilter.Option }

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

    func create_search_filters(
        filters_ptr: RawPtr,
        filters_len: Int32
    ) -> PtrRef {
        hostAllocations.withValue { alloc in
            let filtersArrPtr: [Int32] = (try? memory.values(
                byteOffset: .init(filters_ptr),
                length: .init(filters_len)
            )) ?? []

            let filters = filtersArrPtr.compactMap { alloc[$0] as? SearchFilter }
            return alloc.add(filters)
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

    func create_media_paging(
        items_ptr: RawPtr,
        items_count: Int32,
        current_page_ptr: RawPtr,
        current_page_len: Int32,
        next_page_ptr: RawPtr,
        next_page_len: Int32
    ) -> PtrRef {
        hostAllocations.withValue { alloc in
            let itemsArrPtr: [PtrRef] = (try? memory.values(
                byteOffset: .init(items_ptr),
                length: .init(items_count)
            )) ?? []

            let currentPageStr = try? memory.string(
                byteOffset: .init(current_page_ptr),
                length: .init(current_page_len)
            )

            let nextPageStr = try? memory.string(
                byteOffset: .init(next_page_ptr),
                length: .init(next_page_len)
            )

            let medias = itemsArrPtr.compactMap { alloc[$0] as? Media }

            return alloc.add(
                Paging(
                    items: medias,
                    currentPage: currentPageStr ?? "",
                    nextPage: nextPageStr
                )
            )
        }
    }

    func create_discover_listings(
        listings_ptr: RawPtr,
        listings_len: Int32
    ) -> PtrRef {
        hostAllocations.withValue { alloc in
            let listingsPtr: [RawPtr] = (try? memory.values(
                byteOffset: .init(listings_ptr),
                length: .init(listings_len)
            )) ?? []

            let listings = listingsPtr.compactMap { alloc[$0] as? DiscoverListing }
            return alloc.add(listings)
        }
    }

    func create_discover_listing(
        title_ptr: RawPtr,
        title_len: Int32,
        listing_type: RawPtr,
        paging_ptr: PtrRef
    ) -> PtrRef {
        handleErrorAlloc { alloc in
            let title: String = try memory.string(
                byteOffset: .init(title_ptr),
                length: .init(title_ptr)
            )

            guard let paging = alloc[paging_ptr] as? Paging<Media> else {
                throw ModuleClient.Error.castError()
            }

            return alloc.add(
                DiscoverListing(
                    title: title,
                    type: .init(rawValue: .init(listing_type)) ?? .default,
                    paging: paging
                )
            )
        }
    }
}

private extension HostModuleIntercommunication {
    func handleErrorAlloc<R: WasmValue>(
        func: String = #function,
        _ callback: @escaping (inout [PtrRef: Any]) throws -> R
    ) -> R {
        self.hostAllocations.withValue { alloc in
            do {
                return try callback(&alloc)
            } catch let error as WasmInstance.Error {
                return .init(alloc.addError(.wasm3(error)))
            } catch let error as ModuleClient.Error {
                return .init(alloc.addError(error))
            } catch {
                return .init(alloc.addError(.unknown))
            }
        }
    }
}

struct WasmRequest: KVAccess {
    var url: String?
    var method: Method = .GET
    var body: Data?
    var headers: [String: String] = [:]
    var response: Response?

    enum Method: Int32, CustomStringConvertible {
        case GET
        case POST
        case PUT
        case PATCH
        case DELETE

        var description: String {
            switch self {
            case .GET:
                return "GET"
            case .POST:
                return "POST"
            case .PUT:
                return "PUT"
            case .PATCH:
                return "PATCH"
            case .DELETE:
                return "DELETE"
            }
        }
    }

    struct Response: KVAccess {
        let statusCode: Int
        let data: Data?
        let error: Error?
    }

    func generateURLRequest() -> URLRequest? {
        guard let url = self.url, let url = URL(string: url) else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = self.method.description
        self.body.flatMap { request.httpBody = $0 }
        self.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        return request
    }
}

private extension [Int32: Any] {
    func nextId() -> Int32 {
        self.keys.max().flatMap { $0 + 1 } ?? 0
    }

    mutating func add(_ value: Value) -> Int32 {
        let nextId = nextId()
        self[nextId] = value
        return nextId
    }

    mutating func addError(_ value: ModuleClient.Error) -> Int32 {
        let nextId = self.keys.min().flatMap { $0 - 1 } ?? -1
        self[nextId] = value
        return nextId
    }
}
