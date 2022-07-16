//
//  WeatherClientLive.swift
//  SimpleWeatherApp
//
//  Created by Oluwatobi Omotayo on 13/07/2022.
//

import Combine
import Foundation
import WeatherClient

extension WeatherClient {
  public static let live = Self(
    weather: { id in
      URLSession.shared.dataTaskPublisher(
        for: URL(
          string: "https://www.metaweather.com/api/location/\(id)"
        )!
      )
      .map { data, _ in data }
      .decode(type: WeatherResponse.self, decoder: weatherJsonDecoder)
      .receive(on: DispatchQueue.main)
      .eraseToAnyPublisher()
    },
    searchLocations: { coordinate in
      URLSession.shared.dataTaskPublisher(
        for: URL(
          string: "https://www.metaweather.com/api/location/search?latlong=\(coordinate.latitude),\(coordinate.longitude)"
        )!
      )
      .map { data, _ in data }
      .decode(type: [Location].self, decoder: weatherJsonDecoder)
      .receive(on: DispatchQueue.main)
      .eraseToAnyPublisher()
    }
  )
}

private let weatherJsonDecoder: JSONDecoder = {
  let jsonDecoder = JSONDecoder()
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy-MM-dd"
  jsonDecoder.dateDecodingStrategy = .formatted(formatter)
  jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
  return jsonDecoder
}()
