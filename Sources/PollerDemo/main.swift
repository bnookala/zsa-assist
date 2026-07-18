import Foundation
import ZSAAssistCore

// Usage: zsa-poller-demo [seconds]
// Polls the stub Keymapp client and prints the events the overlay would
// react to. Runs forever unless a duration in seconds is given.

let duration = CommandLine.arguments.dropFirst().first.flatMap(Double.init)

let poller = LayerPoller(client: StubKeymappClient())
let started = ContinuousClock.now

func timestamp() -> String {
    let elapsed = started.duration(to: .now)
    let seconds = Double(elapsed.components.seconds)
        + Double(elapsed.components.attoseconds) * 1e-18
    return String(format: "%6.2fs", seconds)
}

print("Polling stub Keymapp client (Ctrl-C to stop)...")

for await event in poller.events() {
    switch event {
    case .connected(let status):
        print("[\(timestamp())] connected: \(status.friendlyName), layer \(status.currentLayer)")
    case .layerChanged(let from, let to):
        let action = to == 0 ? "overlay would HIDE" : "overlay would SHOW layer \(to)"
        print("[\(timestamp())] layer \(from) -> \(to)  (\(action))")
    case .connectionLost(let description):
        print("[\(timestamp())] connection lost: \(description)")
    }
    if let duration, started.duration(to: .now) > .seconds(duration) {
        break
    }
}
