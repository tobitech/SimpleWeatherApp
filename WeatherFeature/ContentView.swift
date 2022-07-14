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

// All we've done here is written a little struct wrapper
// that exposes endpoints that mimic the endpoints that we would want to call on a path monitor.
public struct PathMonitorClient {
  public var setPathUpdateHandler: (@escaping (NWPath) -> Void) -> Void
  public var start: (DispatchQueue) -> Void
}

extension PathMonitorClient {
  // we're using a computed property here because we need to do some work here that references real Apple code.
  static var live: Self {
    let monitor = NWPathMonitor()
    return Self (
      setPathUpdateHandler: { monitor.pathUpdateHandler = $0 },
      start: monitor.start(queue:)
    )
  }
}

public class AppViewModel: ObservableObject {
  @Published var isConnected = true
  @Published var weatherResults: [WeatherResponse.ConsolidatedWeather] = []
  
  var weatherRequestCancellable: AnyCancellable?
  
  let weatherClient: WeatherClient
  
  // we removed the .live default because we don't want the view model to know about a live client
  // so that it isn't always waiting for the module it leaves in to compile first.
  public init(
//    isConnected: Bool = true,
    pathMonitorClient: PathMonitorClient,
    weatherClient: WeatherClient
  ) {
    self.weatherClient = weatherClient
//    let pathMonitor = NWPathMonitor()
//    self.isConnected = isConnected
    pathMonitorClient.setPathUpdateHandler { [weak self] path in
      guard let self = self else { return }
      self.isConnected = path.status == .satisfied
      if self.isConnected {
        self.refreshWeather()
      } else {
        self.weatherResults = []
      }
    }
    pathMonitorClient.start(.main)
    
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
        pathMonitorClient: .live,
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

