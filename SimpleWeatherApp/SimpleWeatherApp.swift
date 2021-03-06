//
//  SimpleWeatherApp.swift
//  SimpleWeatherApp
//
//  Created by Oluwatobi Omotayo on 12/07/2022.
//

import SwiftUI
import WeatherClientLive
import WeatherFeature
import PathMonitorClientLive
import LocationClientLive

@main
struct SimpleWeatherApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView(
        // we are setting .live here because this place is where we need to build absolutely everything no matter what.
        // but in content view we could move that into a separate feature module and it's not concerned about live.
        viewModel: AppViewModel(
          locationClient: .live,
          pathMonitorClient: .live(queue: .main),
          weatherClient: .live
        )
      )
    }
  }
}
