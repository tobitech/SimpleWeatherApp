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
public struct WeatherClient {
  public var weather: () -> AnyPublisher<WeatherResponse, Error>
  public var searchLocations: (CLLocationCoordinate2D) -> AnyPublisher<[Location], Error>
}


public struct WeatherResponse: Decodable, Equatable {
  public var consolidatedWeather: [ConsolidatedWeather]
  
  public struct ConsolidatedWeather: Decodable, Equatable {
    public var applicableDate: Date
    public var id: Int
    public var maxTemp: Double
    public var minTemp: Double
    public var theTemp: Double
  }
}

public struct Location {
  
}
