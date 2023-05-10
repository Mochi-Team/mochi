@testable import ModuleClient
import SharedModels
import XCTest

final class ModuleClientTests: XCTestCase {
    private static let demo1Data: Data = {
        let demo1URL = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .appendingPathComponent("Modules")
            .appendingPathComponent("demo_1.wasm")
        return (try? Data(contentsOf: demo1URL)) ?? .init()
    }()

    override class func setUp() {
        super.setUp()
        // Load content from file to memory
        _ = Self.demo1Data
    }

    func testModuleFilters() async throws {
        let module = Module(
            binaryModule: Self.demo1Data,
            installDate: Date(),
            manifest: .init(
                id: "demo-1",
                name: "demo 1",
                file: "",
                version: .init(0, 0, 1),
                released: .init(),
                meta: [.video]
            )
        )

        let moduleClient = ModuleClient.liveValue

        let items = try await moduleClient.searchFilters(module)

        XCTAssertEqual(items.count, 2)
    }

    func testModuleSearch() async throws {
        let module = Module(
            binaryModule: Self.demo1Data,
            installDate: Date(),
            manifest: .init(
                id: "demo-1",
                name: "demo 1",
                file: "",
                version: .init(0, 0, 1),
                released: .init(),
                meta: [.video]
            )
        )

        let moduleClient = ModuleClient.liveValue

        let listing = try await moduleClient.search(module, .init(query: ""))

        XCTAssertNotNil(listing.items.first?.id)
    }

    func testModuleDiscoveryListing() async throws {
        let module = Module(
            binaryModule: Self.demo1Data,
            installDate: Date(),
            manifest: .init(
                id: "demo-1",
                name: "demo 1",
                file: "",
                version: .init(0, 0, 1),
                released: .init(),
                meta: [.video]
            )
        )

        let moduleClient = ModuleClient.liveValue

        let listing = try await moduleClient.getDiscoverListings(module)

        XCTAssertEqual(listing.first?.title, "Hello")
        XCTAssertEqual(listing.first?.paging.currentPage, "1")
    }

    func testModuleSearchParallel() async throws {
        var expectations = [XCTestExpectation]()
        for count in 0..<10 {
            let expectation = XCTestExpectation(description: "count-\(count)")
            expectations.append(expectation)
            Task.detached { [unowned self] in
                let startDate = Date()
                try await testModuleSearch()
                let endDate = Date()
                let startDateInterval = startDate.timeIntervalSince1970
                let endDateInterval = endDate.timeIntervalSince1970
                let startDateStr = startDate.formatted(date: .omitted, time: .complete)
                let endDateStr = endDate.formatted(date: .omitted, time: .complete)
                print("finished executing (\(count)), took: \(endDateInterval - startDateInterval)s, start: \(startDateStr), end: \(endDateStr)")
                expectation.fulfill()
            }
        }

        await fulfillment(of: expectations)
    }
}
