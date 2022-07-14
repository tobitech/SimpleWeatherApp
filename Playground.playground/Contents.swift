import Network

let pathMonitor = NWPathMonitor()

pathMonitor.pathUpdateHandler = { path in
  print(path.status)
}

pathMonitor.start(queue: .main)


