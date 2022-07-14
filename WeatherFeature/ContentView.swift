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


// we are calling it NetworkPath in order to avoid conflict with other types called Path.
// usually we will just drop the NW namespace for the type we want to mimic.
// in this case that's not possible.
public struct NetworkPath {
  // we will add all the fields that we're interested in accessing from the NWPath.
  public var status: NWPath.Status
}

extension NetworkPath {
  // we need to add a conveniece initializer so that this is easy for us to work with.
  // since status is an enum, we can make one that takes the raw value of the path
  // since our `NetworkPath` is a wrapper it makes sense to make an initializer that takes NWPath.
  public init(rawValue: NWPath) {
    self.status = rawValue.status
  }
}

// All we've done here is written a little struct wrapper
// that exposes endpoints that mimic the endpoints that we would want to call on a path monitor.
public struct PathMonitorClient {
//  public var setPathUpdateHandler: (@escaping (NWPath) -> Void) -> Void
  // now that we've a wrapper we can replace NWPath with that wrapper here.
  public var setPathUpdateHandler: (@escaping (NetworkPath) -> Void) -> Void
  public var start: (DispatchQueue) -> Void
}

extension PathMonitorClient {
  // we're using a computed property here because we need to do some work here that references real Apple code.
  static var live: Self {
    let monitor = NWPathMonitor()
    return Self (
      setPathUpdateHandler: { callback in
        monitor.pathUpdateHandler = { path in
          callback(NetworkPath(rawValue: path))
        }
      },
      start: monitor.start(queue:)
    )
  }
}

extension PathMonitorClient {
  // let's start with a mock that provides ideal internet connectivity.
  static let satisfied = Self(
    setPathUpdateHandler: { callback in
      // NWPath doesn't have a way of constructing this value
      // callback(/*satisified*/)
      callback(NetworkPath(status: .satisfied))
    },
    // we don't need to worry about starting it here
    // we can just start off from a satisfied state
    // that's why we're passing in en empty closure.
    start: { _ in }
  )
  
  static let unsatisfied = Self(
    setPathUpdateHandler: { callback in
      callback(NetworkPath(status: .unsatisfied))
    },
    start: { _ in }
  )
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
    
    // this was causing a bug - we are removing it so that we let the path update drive the refresh call.
    // self.refreshWeather()
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
        pathMonitorClient: .satisfied,
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

