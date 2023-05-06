//
//  ImportHandlerTests.swift
//  
//
//  Created by ErrorErrorError on 4/26/23.
//  
//

@testable import ModuleClient
import XCTest

final class ImportHandlerTests: XCTestCase {
    private struct JsonDemo: Codable {
        let title: String
        let titleOptional: String?
        let number: Int
        let numberOptional: Int?
        let bool: Bool
        // swiftlint:disable discouraged_optional_boolean
        let boolOptional: Bool?
        let object: Nested
        let objectOptional: Nested?

        struct Nested: Codable {
            let string: String
        }
    }

    private let jsonDemo = JsonDemo(
        title: "Hello",
        titleOptional: nil,
        number: 54,
        numberOptional: nil,
        bool: true,
        boolOptional: nil,
        object: .init(string: "Hi"),
        objectOptional: nil
    )

    private let jsonStrDemo = """
    {
        "title": "Hello",
        "titleOpional": null,
        "number": 54,
        "numberOptional": null,
        "bool": true,
        "boolOptional": null,
        "object": { "string": "Hi" },
        "objectOptional": null
    }
    """

    func testJsonCreationAndAccess() throws {
        let memory = LocalMemoryInstance()
        let importHandlers = HostModuleIntercommunication(memory: memory)

        let buffered = jsonStrDemo.data(using: .utf8) ?? .init()

        try importHandlers.memory.write(with: buffered, byteOffset: 0)

        let jsonPtr = importHandlers.json_parse(buf_ptr: 0, buf_len: Int32(buffered.count))
        XCTAssertGreaterThanOrEqual(jsonPtr, 0)

        let keysPtr = importHandlers.obj_keys(ptr: jsonPtr)
        XCTAssertGreaterThanOrEqual(keysPtr, 0)

        let keysLen = importHandlers.array_len(ptr: keysPtr)
        XCTAssertEqual(keysLen, 8)

        let keyArr = importHandlers.getHostObject(keysPtr)
        XCTAssertTrue(keyArr is [Any])

        let titleKey = "title"
        let titleKeyPtrRaw = 1
        try importHandlers.memory.write(with: titleKey, byteOffset: titleKeyPtrRaw)

        let valuePtr = importHandlers.obj_get(
            ptr: jsonPtr,
            key_ptr: RawPtr(titleKeyPtrRaw),
            key_len: Int32(titleKey.count)
        )
        XCTAssertGreaterThanOrEqual(valuePtr, 0)

        let valuePtrKind = importHandlers.ptr_kind(ptr: valuePtr)
        XCTAssertEqual(valuePtrKind, PtrKind.string.rawValue)

        let value = importHandlers.getHostObject(valuePtr)
        XCTAssertTrue(value is String)
        XCTAssertTrue((value as? String) == "Hello")
    }
}
