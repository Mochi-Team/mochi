import ComposableArchitecture
@testable
import ModuleClient
import SharedModels
import XCTest

final class ModuleClientTests: XCTestCase {
  private static let indexModule: Module = {
    let indexURL = Bundle.module.url(forResource: "index", withExtension: "js", subdirectory: "Resources")
      .unsafelyUnwrapped
    return Module(
      moduleLocation: indexURL,
      installDate: .now,
      manifest: .init(
        id: "demo",
        name: "Demo",
        file: "",
        version: .init(0, 0, 1),
        meta: []
      )
    )
  }()

  func testJSLoader() async throws {
    let instance = try ModuleClient.Instance(module: Self.indexModule)

    let value = try await instance.search(SearchQuery(query: ""))
  }

  func testDiscoverListing() async throws {
    let instance = try ModuleClient.Instance(module: Self.indexModule)

    let value = try await instance.discoverListings()
  }
}
