//
//  HostModuleInterop+Http.swift
//
//
//  Created by ErrorErrorError on 5/9/23.
//
//

import Foundation

// MARK: - HTTP Imports

extension HostModuleInterop {
    func request_create(method: Int32) -> ReqRef {
        hostAllocations.withValue { alloc in
            alloc.add(WasmRequest(method: .init(rawValue: method) ?? .GET))
        }
    }

    func request_send(ptr: ReqRef) {
        hostAllocations.withValue { alloc in
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
        hostAllocations.withValue { $0[ptr] = nil }
    }

    func request_set_url(ptr: ReqRef, url_ptr: RawPtr, url_len: Int32) {
        hostAllocations.withValue { alloc in
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
        hostAllocations.withValue { alloc in
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
        hostAllocations.withValue { alloc in
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
        hostAllocations.withValue { alloc in
            guard var request = alloc[ptr] as? WasmRequest else {
                return
            }

            request.method = .init(rawValue: method) ?? .GET

            alloc[ptr] = request
        }
    }

    func request_get_method(ptr: ReqRef) -> Int32 {
        hostAllocations.withValue { alloc in
            guard let request = alloc[ptr] as? WasmRequest else {
                return WasmRequest.Method.GET.rawValue
            }
            return request.method.rawValue
        }
    }

    func request_get_url(ptr: ReqRef) -> PtrRef {
        handleErrorAlloc { alloc in
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
        handleErrorAlloc { alloc in
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
        handleErrorAlloc { alloc in
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
        hostAllocations.withValue { alloc in
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
        hostAllocations.withValue { alloc in
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

// MARK: - WasmRequest

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
        guard let url, let url = URL(string: url) else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.description
        body.flatMap { request.httpBody = $0 }
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        return request
    }
}
