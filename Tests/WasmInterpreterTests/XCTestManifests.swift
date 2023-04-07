import XCTest

#if !canImport(ObjectiveC)
    public func allTests() -> [XCTestCaseEntry] {
        [
            testCase(WasmInterpreterTests.allTests),
            testCase(CWasm3Tests.allTests)
        ]
    }
#endif
