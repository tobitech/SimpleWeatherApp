//
//  ContentView.swift
//  SimpleWeatherApp
//
//  Created by Oluwatobi Omotayo on 12/07/2022.
//

import Combine
import Network
import SwiftUI
import WeatherClient

public class AppViewModel: ObservableObject {
  @Published var isConnected = true
  @Published var weatherResults: [WeatherResponse.ConsolidatedWeather] = []
  
  var weatherRequestCancellable: AnyCancellable?
  
  let weatherClient: WeatherClient
  
  // we removed the .live default because we don't want the view model to know about a live client
  // so that it isn't always waiting for the module it leaves in to compile first.
  public init(
//    isConnected: Bool = true,
    weatherClient: WeatherClient
  ) {
    self.weatherClient = weatherClient
    let pathMonitor = NWPathMonitor()
//    self.isConnected = isConnected
    pathMonitor.pathUpdateHandler = { [weak self] path in
      guard let self = self else { return }
      self.isConnected = path.status == .satisfied
      if self.isConnected {
        self.refreshWeather()
      } else {
        self.weatherResults = []
      }
    }
    pathMonitor.start(queue: .main)
    
    self.refreshWeather()
  }
  
  func refreshWeather() {
    self.weatherResults = []
    
    self.weatherRequestCancellable =  self.weatherClient.weather()
      .sink(
        receiveCompletion: { _ in },
        receiveValue: {[weak self] response in
          self?.weatherResults = response.consolidatedWeather
        })
  }
}

public struct ContentView: View {
  @ObservedObject var viewModel: AppViewModel
  
  public init(viewModel: AppViewModel) {
    self.viewModel = viewModel
  }
  
  public var body: some View {
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
    
    var client = WeatherClient.happyPath
    client.searchLocations = { _ in
      Fail(error: NSError(domain: "", code: 1))
        .eraseToAnyPublisher()
    }
    
    return ContentView(
      viewModel: AppViewModel(
        weatherClient: client
      )
    )
  }
}

let dayOfWeekFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "EEEE"
  return formatter
}()

