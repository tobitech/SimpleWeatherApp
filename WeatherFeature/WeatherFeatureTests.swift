//
//  WeatherFeatureTests.swift
//  WeatherFeatureTests
//
//  Created by Oluwatobi Omotayo on 13/07/2022.
//

import XCTest
import Combine
import LocationClient
import PathMonitorClient
import WeatherClient
@testable import WeatherFeature

class WeatherFeatureTests: XCTestCase {
  
  func testBasics() {
    
    let moderateWeather = WeatherResponse(
      consolidatedWeather: [
        .init(
          applicableDate: Date(timeIntervalSinceReferenceDate: 0),
          id: 1,
          maxTemp: 30,
          minTemp: 20,
          theTemp: 25
        )
      ]
    )

    let lagos = Location(
      title: "Lagos",
      woeid: 1
    )

    let viewModel = AppViewModel(
      locationClient: LocationClient(
        authorizationStatus: { fatalError() },
        requestWhenInUseAuthorization: { fatalError() },
        requestLocation: { fatalError() },
        // Futures are eager publishers, it will do its work immediately it's subscribed to and run the fatalError
        // that's why we wrapped it inside a Defferred Publisher.
        delegate: Deferred { Future { _ in fatalError() } }.eraseToAnyPublisher()
      ),
      pathMonitorClient: .satisfied,
      weatherClient: WeatherClient(
        weather: { _ in
          Just(moderateWeather)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        },
        searchLocations: { _ in
          Just([lagos])
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        }
      )
    )

    XCTAssertEqual(viewModel.currentLocation, lagos)
    XCTAssertEqual(viewModel.isConnected, true)
    XCTAssertEqual(viewModel.weatherResults, moderateWeather.consolidatedWeather)
  }
}

