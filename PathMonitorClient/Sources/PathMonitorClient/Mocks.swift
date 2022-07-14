import Combine
import Foundation
import Network

extension PathMonitorClient {
  // let's start with a mock that provides ideal internet connectivity.
  public static let satisfied = Self(
    networkPathPublisher: Just(NetworkPath(status: .satisfied)).eraseToAnyPublisher()
    )
//    cancel: { },
//    setPathUpdateHandler: { callback in
      // NWPath doesn't have a way of constructing this value
      // callback(/*satisified*/)
//      callback(NetworkPath(status: .satisfied))
//    },
    // we don't need to worry about starting it here
    // we can just start off from a satisfied state
    // that's why we're passing in en empty closure.
//    start: { _ in }
//  )
  
  public static let unsatisfied = Self(
    networkPathPublisher: Just(NetworkPath(status: .unsatisfied)).eraseToAnyPublisher()
  )
//    cancel: { },
//    setPathUpdateHandler: { callback in
//      callback(NetworkPath(status: .unsatisfied))
//    },
//    start: { _ in }
//  )
  
  
  
  public static let flaky = Self(
    networkPathPublisher: Timer.publish(every: 2, on: .main, in: .default)
      .autoconnect()
      .scan(.satisfied, { status, _ in
        status == .satisfied ? .unsatisfied : .satisfied
      })
      .map { NetworkPath(status: $0) }
      .eraseToAnyPublisher()
  )
//    cancel: { },
//    setPathUpdateHandler: { callback in
//      // to represent an idea of being flaky - we will setup a timer so that every two seconds it will flip the current status.
//
//      var status = NWPath.Status.satisfied
//
//      Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
//        callback(.init(status: status))
//        status = status == .satisfied ? .unsatisfied : .satisfied
//      }
//    },
//    // no-op closure.
//    start: { _ in }
//  )
}
