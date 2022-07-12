//
//  ContentView.swift
//  SimpleWeatherApp
//
//  Created by Oluwatobi Omotayo on 12/07/2022.
//

import Combine
import SwiftUI

class AppViewModel: ObservableObject {
  @Published var isConnected: Bool
  @Published var weatherResults: [WeatherResponse.ConsolidatedWeather] = []
  
  var weatherRequestCancellable: AnyCancellable?
  
  init(isConnected: Bool = true, weatherClient: WeatherClientProtocol = WeatherClient()) {
    self.isConnected = isConnected
    
    self.weatherRequestCancellable =  weatherClient.weather()
      .sink(
        receiveCompletion: { _ in },
        receiveValue: {[weak self] response in
          self?.weatherResults = response.consolidatedWeather
        })
  }
}

struct ContentView: View {
  @ObservedObject var viewModel: AppViewModel
  
  var body: some View {
    NavigationView {
      ZStack(alignment: .bottom) {
        ZStack(alignment: .bottomTrailing) {
          List {
            ForEach(self.viewModel.weatherResults, id: \.id) { weather in
              VStack(alignment: .leading) {
                Text(dayOfWeekFormatter.string(from: weather.applicableDate).capitalized)
                  .font(.title)
                
                Text("Current temp: \(weather.theTemp, specifier: "%.1f")°C")
                Text("Max temp: \(weather.maxTemp, specifier: "%.1f")°C")
                Text("Min temp: \(weather.minTemp, specifier: "%.1f")°C")
              }
            }
          }
          
          Button(
            action: {  }
          ) {
            Image(systemName: "location.fill")
              .foregroundColor(.white)
              .frame(width: 60, height: 60)
          }
          .background(Color.black)
          .clipShape(Circle())
          .padding()
        }
        
        if !self.viewModel.isConnected {
          HStack {
            Image(systemName: "exclamationmark.octagon.fill")
            
            Text("Not connected to internet")
          }
          .foregroundColor(.white)
          .padding()
          .background(Color.red)
        }
      }
      .navigationBarTitle("Weather")
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView(
      viewModel: AppViewModel(weatherClient: MockWeatherClient())
    )
  }
}

let dayOfWeekFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "EEEE"
  return formatter
}()

protocol WeatherClientProtocol {
  // describe the signature of making a weather request here.
  func weather() -> AnyPublisher<WeatherResponse, Error>
}

struct WeatherClient: WeatherClientProtocol {
  func weather() -> AnyPublisher<WeatherResponse, Error> {
    URLSession.shared.dataTaskPublisher(for: URL(string: "https://www.metaweather.com/api/location/2459115")!)
      .map { data, _ in data }
      .decode(type: WeatherResponse.self, decoder: weatherJsonDecoder)
      .receive(on: DispatchQueue.main)
      .eraseToAnyPublisher()
  }
}

struct MockWeatherClient: WeatherClientProtocol {
  func weather() -> AnyPublisher<WeatherResponse, Error> {
    Just(
      WeatherResponse(
        consolidatedWeather: [
          .init(applicableDate: Date(), id: 1, maxTemp: 30, minTemp: 10, theTemp: 20),
          .init(applicableDate: Date().addingTimeInterval(86400), id: 2, maxTemp: -10, minTemp: -30, theTemp: -20)
        ]
      )
    )
     // Just publishers have a Never error that's why we need to set the failure type below.
      .setFailureType(to: Error.self)
      // to simulate what happens when weather API takes time to return a response.
      .delay(for: 2, scheduler: DispatchQueue.main)
//    Fail(error: NSError(domain: "", code: 1, userInfo: nil))
      .eraseToAnyPublisher()
  }
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

private let weatherJsonDecoder: JSONDecoder = {
  let jsonDecoder = JSONDecoder()
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy-MM-dd"
  jsonDecoder.dateDecodingStrategy = .formatted(formatter)
  jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
  return jsonDecoder
}()
