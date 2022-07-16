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
import PathMonitorClient

struct LocationClient {
  var authorizationStatus: () -> CLAuthorizationStatus
  var requestWhenInUseAuthorization: () -> Void
  var requestLocation: () -> Void
  
  // we could feed the view model through this closure to any live underlying manager.
  // while this is a great approach, it would not let us fully control the dependency.
  // as long as view model has the delegate it will have full access to the live CLLocationManager in every single one of its delegate methods.
  // but we don't want our features viewmodel to know about any live framework or implementation.
  // var setDelegate: (CLLocationManagerDelegate) -> Void
  
  var delegate: AnyPublisher<DelegateEvent, Never>
  
  enum DelegateEvent {
    case didChangeAuthorization(CLAuthorizationStatus)
    case didUpdateLocations([CLLocation])
    case didFailWithError(Error)
  }
}

extension LocationClient {
  static var live: Self  {
    
    // this is only needed for live implementation that's why we're creating this scoped type so that it's only accessible here.
    // also prevents namespace conflicts.
    class Delegate: NSObject, CLLocationManagerDelegate {
      
      var subject: PassthroughSubject<DelegateEvent, Never>
      
      init(subject: PassthroughSubject<DelegateEvent, Never>) {
        self.subject = subject
        super.init()
      }
      
      func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.subject.send(.didChangeAuthorization(status))
      }
      
      func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.subject.send(.didUpdateLocations(locations))
      }
      
      func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.subject.send(.didFailWithError(error))
      }
    }
    
    let locationManager = CLLocationManager()
    let subject = PassthroughSubject<DelegateEvent, Never>()
    var delegate: Delegate? = Delegate(subject: subject)
    locationManager.delegate = delegate
    
    return Self(
      authorizationStatus: CLLocationManager.authorizationStatus,
      requestWhenInUseAuthorization: locationManager.requestWhenInUseAuthorization,
      requestLocation: locationManager.requestLocation,
      delegate: subject
        .handleEvents(receiveCancel: { delegate = nil })
        .eraseToAnyPublisher()
    )
  }
}

public class AppViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
  @Published var currentLocation: Location?
  @Published var isConnected = true
  @Published var weatherResults: [WeatherResponse.ConsolidatedWeather] = []
  
  var weatherRequestCancellable: AnyCancellable?
  var pathUpdateCancellable: AnyCancellable?
  var searchLocationsCancellable: AnyCancellable?
  
  let weatherClient: WeatherClient
  let pathMonitorClient: PathMonitorClient
  
  let locationManager = CLLocationManager()
  
  // we removed the .live default because we don't want the view model to know about a live client
  // so that it isn't always waiting for the module it leaves in to compile first.
  public init(
//    isConnected: Bool = true,
    pathMonitorClient: PathMonitorClient,
    weatherClient: WeatherClient
  ) {
    self.weatherClient = weatherClient
    self.pathMonitorClient = pathMonitorClient
//    let pathMonitor = NWPathMonitor()
//    self.isConnected = isConnected
    
    // now handled by the publisher
//    self.pathMonitorClient.setPathUpdateHandler { [weak self] path in
    
    super.init()
    
    self.pathUpdateCancellable = self.pathMonitorClient.networkPathPublisher
      .map { $0.status == .satisfied }
      // this will prevent two emissions to happen in a row that are the same value
      // with this refactor we can limit the number of refreshes to our feature makes where the path status hasn't changed.
      .removeDuplicates()
      .sink(receiveValue: { [weak self] isConnected in
        guard let self = self else { return }
        self.isConnected = isConnected
        if self.isConnected {
          self.refreshWeather()
        } else {
          self.weatherResults = []
        }
      })
    
    // now handled by the publisher
    // self.pathMonitorClient.start(.main)
    
    // this was causing a bug - we are removing it so that we let the path update drive the refresh call.
    // self.refreshWeather()
    
    self.locationManager.delegate = self
  }
  
  // now handled by the publisher
//  deinit {
//    self.pathMonitorClient.cancel()
//  }
  
  func refreshWeather() {
    guard let location = currentLocation else {
      return
    }
    
    self.weatherResults = []
    
    self.weatherRequestCancellable =  self.weatherClient.weather(location.woeid)
      .sink(
        receiveCompletion: { _ in },
        receiveValue: {[weak self] response in
          self?.weatherResults = response.consolidatedWeather
        })
  }
  
  func locationButtonTapped() {
    // the logic we want to put here is to first check if the user has previously given us access to their location.
    
    switch CLLocationManager.authorizationStatus() {
    case .notDetermined:
      // when we don't know the status - we should request for authorization.
      self.locationManager.requestWhenInUseAuthorization()
    case .restricted:
      // restricted by parental control.
      // TODO: Show an alert
      break
    case .denied:
      // when user already denied us
      // TODO: Show an alert
      break
    case .authorizedAlways, .authorizedWhenInUse:
      // whichever authorization type we were granted we can request the location data.
      self.locationManager.requestLocation()
      
    @unknown default:
      break
    }
  }
  
  // MARK: - CLLocationManagerDelegate
  public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    switch status {
    case .notDetermined:
      // not likely that we get this status after first interaction with location manager.
      break

    case .restricted:
      // TODO: Show an alert
      // this will have a different alert message since it's likely it's intentional.
      break
    case .denied:
      // TODO: Show an alert
      // same as above.
      break
      
    case .authorizedAlways, .authorizedWhenInUse, .authorized:
      self.locationManager.requestLocation()

    @unknown default:
      break
    }
  }
  
  public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.first else { return }
    
    self.searchLocationsCancellable = self.weatherClient.searchLocations(location.coordinate).sink(
      receiveCompletion: { _ in
        // normally we will do an error handling and show alert here if this fails.
      },
      receiveValue: { [weak self] locations in
        self?.currentLocation = locations.first
        self?.refreshWeather()
      }
    )
  }
  
  public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    // the app will just crash if there is an error and this delegate method wasn't called.
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
            action: { self.viewModel.locationButtonTapped() }
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
      .navigationBarTitle(self.viewModel.currentLocation?.title ?? "Weather")
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

