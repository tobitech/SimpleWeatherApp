//
//  WeatherClientLive.swift
//  SimpleWeatherApp
//
//  Created by Oluwatobi Omotayo on 13/07/2022.
//

import Combine
import Foundation

extension WeatherClient {
  static let live = Self(
    weather: {
      URLSession.shared.dataTaskPublisher(
        for: URL(
          string: "https://www.metaweather.com/api/location/2459115"
        )!
      )
      .map { data, _ in data }
      .decode(type: WeatherResponse.self, decoder: weatherJsonDecoder)
      .receive(on: DispatchQueue.main)
      .eraseToAnyPublisher()
    },
    searchLocations: { _ in
      fatalError()
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
