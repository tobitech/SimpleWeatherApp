//
//  SimpleWeatherApp.swift
//  SimpleWeatherApp
//
//  Created by Oluwatobi Omotayo on 12/07/2022.
//

import SwiftUI

@main
struct SimpleWeatherApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView(
        viewModel: AppViewModel()
      )
    }
  }
}
