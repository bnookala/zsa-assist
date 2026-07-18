/// Events the overlay layer reacts to.
public enum LayerEvent: Sendable, Equatable {
    /// First successful status call (or first after a connection loss).
    case connected(KeyboardStatus)
    /// The active layer changed between two consecutive polls.
    case layerChanged(from: Int, to: Int)
    /// A status call failed — after we had been connected, or on the first
    /// attempt (emitted once per outage, not once per failed poll).
    case connectionLost(description: String)
}

/// Polls a `KeymappClient` on a fixed interval and turns raw status
/// snapshots into a stream of transitions. The overlay window subscribes to
/// `events()` and shows/hides itself on `layerChanged`.
public struct LayerPoller: Sendable {
    private let client: any KeymappClient
    private let interval: Duration

    public init(client: any KeymappClient, interval: Duration = .milliseconds(50)) {
        self.client = client
        self.interval = interval
    }

    /// An infinite stream of layer events; cancel the consuming task (or
    /// break out of iteration) to stop polling.
    public func events() -> AsyncStream<LayerEvent> {
        AsyncStream { continuation in
            let task = Task {
                var lastLayer: Int?
                var reportedDown = false
                while !Task.isCancelled {
                    do {
                        let status = try await client.status()
                        if lastLayer == nil {
                            continuation.yield(.connected(status))
                        } else if let last = lastLayer, last != status.currentLayer {
                            continuation.yield(.layerChanged(from: last, to: status.currentLayer))
                        }
                        lastLayer = status.currentLayer
                        reportedDown = false
                    } catch {
                        if lastLayer != nil || !reportedDown {
                            continuation.yield(.connectionLost(description: String(describing: error)))
                        }
                        lastLayer = nil
                        reportedDown = true
                    }
                    do {
                        try await Task.sleep(for: interval)
                    } catch {
                        break
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
