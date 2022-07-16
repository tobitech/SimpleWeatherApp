//
//  LocationClientLive.swift
//  
//
//  Created by Oluwatobi Omotayo on 16/07/2022.
//

import Combine
import CoreLocation
import Foundation
import LocationClient

extension LocationClient {
  public static var live: Self  {
    
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
