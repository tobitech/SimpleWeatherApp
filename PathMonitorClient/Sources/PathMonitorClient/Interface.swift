import Foundation
import Network

// we are calling it NetworkPath in order to avoid conflict with other types called Path.
// usually we will just drop the NW namespace for the type we want to mimic.
// in this case that's not possible.
public struct NetworkPath {
  // we will add all the fields that we're interested in accessing from the NWPath.
  public var status: NWPath.Status
  
  public init(status: NWPath.Status) {
    self.status = status
  }
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
  public var cancel: () -> Void
  //  public var setPathUpdateHandler: (@escaping (NWPath) -> Void) -> Void
  // now that we've a wrapper we can replace NWPath with that wrapper here.
  public var setPathUpdateHandler: (@escaping (NetworkPath) -> Void) -> Void
  public var start: (DispatchQueue) -> Void
  
  public init(
    cancel: @escaping () -> Void,
    setPathUpdateHandler: @escaping (@escaping (NetworkPath) -> Void) -> Void,
    start: @escaping (DispatchQueue) -> Void
  ) {
    self.cancel = cancel
    self.setPathUpdateHandler = setPathUpdateHandler
    self.start = start
  }
}
