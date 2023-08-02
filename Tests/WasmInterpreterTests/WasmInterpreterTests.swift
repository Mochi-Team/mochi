@testable import WasmInterpreter
import XCTest

final class WasmInterpreterTests: XCTestCase {
    func testCallingFunctionsWithSameImplementation() throws {
        let mod = try ConstantModule()

        try (1...10).forEach { XCTAssertEqual(65_536, try mod.constant(version: $0)) }

        XCTAssertThrowsError(try mod.constant(version: 12)) { error in
            guard case let .functions(.failedToFindFunction(named, error)) = error as? WasmInstance.Error else {
                XCTFail("unknown error found \(error.localizedDescription)")
                return
            }
            XCTAssertEqual("constant_12", named)
            XCTAssertEqual("function lookup failed", error)
        }
    }

    func testPassingAndReturning32BitValues() throws {
        let mod = try AddModule()
        XCTAssertEqual(0, try mod.add(-1, 1))
        XCTAssertEqual(0, try mod.add(0, 0))
        XCTAssertEqual(3, try mod.add(1, 2))
        XCTAssertEqual(910_861, try mod.add(13_425, 897_436))
    }

    func testPassingAndReturning64BitValues() throws {
        let mod = try FibonacciModule()
        XCTAssertEqual(0, try mod.calculateValue(at: 0))
        XCTAssertEqual(1, try mod.calculateValue(at: 1))
        XCTAssertEqual(1, try mod.calculateValue(at: 2))
        XCTAssertEqual(5, try mod.calculateValue(at: 5))
        XCTAssertEqual(75_025, try mod.calculateValue(at: 25))
    }

    func testUsingImportedFunction() throws {
        let mod = try ImportedAddModule()
        XCTAssertEqual(-3_291, try mod.askModuleToCallImportedFunction())
    }

    func testConcurrentModulesWithImportedFunctions() throws {
        let mod1 = try ImportedAddModule()
        let mod2 = try ImportedAddModule()

        DispatchQueue.global().async {
            XCTAssertEqual(-3_291, try? mod1.askModuleToCallImportedFunction())
        }

        DispatchQueue.global().async {
            XCTAssertEqual(-3_291, try? mod2.askModuleToCallImportedFunction())
        }
    }

    func testAccessingAndModifyingHeapMemory() throws {
        let mod = try MemoryModule()

        XCTAssertEqual("\u{0}\u{0}\u{0}\u{0}", try mod.string(at: 0, length: 4))

        let hello = "Hello, everyone! 👋"
        try mod.write(hello, to: 0)
        XCTAssertEqual(hello, try mod.string(at: 0, length: hello.utf8.count))

        let numbers = [1, 2, 3, 4]
        try mod.write(numbers, to: 0)
        XCTAssertEqual(numbers, try mod.integers(at: 0, length: 4))

        let fortyTwo = [42]
        try mod.write(fortyTwo, to: 1)
        XCTAssertEqual(42, try mod.integers(at: 1, length: 1).first)

        XCTAssertEqual(10_753, try mod.integers(at: 0, length: 1).first)

        let goodbye = "Goodbye!"
        XCTAssertNoThrow(try mod.writeASCIICharacters(in: goodbye, to: 2))
        XCTAssertEqual(goodbye, try mod.asciiString(at: 2, length: goodbye.count))

        XCTAssertEqual("👋", try mod.string(at: 17, length: "👋".utf8.count))
    }

    func testAccessingInvalidMemoryAddresses() throws {
        let mod = try MemoryModule()
        let size = 64 * 1_024 // 1 page size = 64 KiB

        let message = "Hello"

        let validOffset = size - message.utf8.count
        XCTAssertNoThrow(try mod.write(message, to: validOffset))
        XCTAssertEqual(
            message,
            try mod.string(at: validOffset, length: message.utf8.count)
        )

        let invalidOffset = size - message.utf8.count + 1
        XCTAssertThrowsError(try mod.write(message, to: invalidOffset)) { error in
            guard let wasmError = error as? WasmInstance.Error else {
                return XCTFail("unknown error thrown \(error.localizedDescription)")
            }

            guard case .memory(.invalidMemoryAccess) = wasmError else {
                return XCTFail("unknown wasm error occured \(wasmError.localizedDescription)")
            }
        }

        // Ensure memory hasn't been modified
        XCTAssertEqual(
            message,
            try mod.string(at: validOffset, length: message.utf8.count)
        )
    }

    static var allTests = [
        (
            "testCallingTwoFunctionsWithSameImplementation",
            testCallingFunctionsWithSameImplementation
        ),
        ("testPassingAndReturning32BitValues", testPassingAndReturning32BitValues),
        ("testPassingAndReturning64BitValues", testPassingAndReturning64BitValues),
        ("testUsingImportedFunction", testUsingImportedFunction),
        (
            "testConcurrentModulesWithImportedFunctions",
            testConcurrentModulesWithImportedFunctions
        ),
        ("testAccessingAndModifyingHeapMemory", testAccessingAndModifyingHeapMemory),
        ("testAccessingInvalidMemoryAddresses", testAccessingInvalidMemoryAddresses)
    ]
}
