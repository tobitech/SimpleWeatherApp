import XCTest
@testable import WeatherClient

final class WeatherClientTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(WeatherClient().text, "Hello, World!")
    }
}
