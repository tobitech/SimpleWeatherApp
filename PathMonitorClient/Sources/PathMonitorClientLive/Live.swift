//
//  PathMonitorClientLive.swift
//  
//
//  Created by Oluwatobi Omotayo on 14/07/2022.
//

import Combine
import Foundation
import Network
import PathMonitorClient

extension PathMonitorClient {
  // we're using a computed property here because we need to do some work here that references real Apple code.
  public static func live(queue: DispatchQueue) -> Self {
    let monitor = NWPathMonitor()
    // we need to supply a publisher here that receives network paths over time.
    // one of the most lightest weight ways to create a publisher we can send values to is to create a Subject.
    let subject = PassthroughSubject<NWPath, Never>()
//    monitor.pathUpdateHandler = { path in
//      subject.send(path)
//    }
    monitor.pathUpdateHandler = subject.send
    
    // start the monitor when we subscribe instead of starting it immediately.
    // monitor.start(queue: queue)
    
    return Self (
//      cancel: { monitor.cancel() },
//      setPathUpdateHandler: { callback in
//        monitor.pathUpdateHandler = { path in
//          callback(NetworkPath(rawValue: path))
//        }
//      },
//      start: monitor.start(queue:)
      networkPathPublisher: subject
        .handleEvents(
          receiveSubscription: { _ in monitor.start(queue: queue) },
          receiveCancel: monitor.cancel
        )
        .map(NetworkPath.init(rawValue:))
        .eraseToAnyPublisher()
    )
  }
}
