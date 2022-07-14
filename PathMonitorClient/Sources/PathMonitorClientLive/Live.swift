//
//  PathMonitorClientLive.swift
//  
//
//  Created by Oluwatobi Omotayo on 14/07/2022.
//

import Foundation
import Network
import PathMonitorClient

extension PathMonitorClient {
  // we're using a computed property here because we need to do some work here that references real Apple code.
  public static var live: Self {
    let monitor = NWPathMonitor()
    return Self (
      cancel: { monitor.cancel() },
      setPathUpdateHandler: { callback in
        monitor.pathUpdateHandler = { path in
          callback(NetworkPath(rawValue: path))
        }
      },
      start: monitor.start(queue:)
    )
  }
}
