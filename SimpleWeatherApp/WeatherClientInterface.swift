//
//  WeatherClientInterface.swift
//  SimpleWeatherApp
//
//  Created by Oluwatobi Omotayo on 13/07/2022.
//

import Combine
import CoreLocation
import Foundation

/// A client for accessing weather data for locations.
struct WeatherClient {
  var weather: () -> AnyPublisher<WeatherResponse, Error>
  var searchLocations: (CLLocationCoordinate2D) -> AnyPublisher<[Location], Error>
}

struct Location {
  
}

struct WeatherResponse: Decodable, Equatable {
  var consolidatedWeather: [ConsolidatedWeather]
  
  struct ConsolidatedWeather: Decodable, Equatable {
    var applicableDate: Date
    var id: Int
    var maxTemp: Double
    var minTemp: Double
    var theTemp: Double
  }
}
