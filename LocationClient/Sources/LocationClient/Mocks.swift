import Combine
import CoreLocation

extension LocationClient {
  // you can also upgrade this to a function to take a parameter if you need return new locations with real coordinates
  // static func authorizedWhenInUse(coordinate:) -> Self {
  public static var authorizedWhenInUse: Self {
    
    let subject = PassthroughSubject<DelegateEvent, Never>()
    
    return Self(
      authorizationStatus: { .authorizedWhenInUse },
      // for this mock this endpiot should not even be called, because anyone that wants to call it
      // should first check the authoriazaiton status and for this mock it always returns a valid value.
      requestWhenInUseAuthorization: { },
      // for this one we need a way to communicate to the delegate publisher to send it a delegate event of `didUpdateLocations`
      // we will do that by defining a subject above - just like we did with the path monitory client.
      requestLocation: {
        // now when somone requests a location, we can just supply a location from here.
        // in here you can create actual instances of CLLocation and pass in some coordinates
        subject.send(.didUpdateLocations([CLLocation()]))
      },
      delegate: subject.eraseToAnyPublisher()
    )
  }
  
  public static var notDetermined: Self {
    var status = CLAuthorizationStatus.notDetermined
    let subject = PassthroughSubject<DelegateEvent, Never>()
    
    return Self(
      authorizationStatus: { status },
      requestWhenInUseAuthorization: {
        status = .authorizedWhenInUse
        subject.send(.didChangeAuthorization(status))
      },
      requestLocation: {
        subject.send(.didUpdateLocations([CLLocation()]))
      },
      delegate: subject.eraseToAnyPublisher()
    )
  }
}
