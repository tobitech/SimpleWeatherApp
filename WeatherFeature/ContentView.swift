//
//  ContentView.swift
//  SimpleWeatherApp
//
//  Created by Oluwatobi Omotayo on 12/07/2022.
//

import Combine
import CoreLocation
import SwiftUI
import WeatherClient

class AppViewModel: ObservableObject {
  @Published var isConnected: Bool
  @Published var weatherResults: [WeatherResponse.ConsolidatedWeather] = []
  
  var weatherRequestCancellable: AnyCancellable?
  
  // we removed the .live default because we don't want the view model to know about a live client
  // so that it isn't always waiting for the module it leaves in to compile first.
  init(isConnected: Bool = true, weatherClient: WeatherClient) {
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

