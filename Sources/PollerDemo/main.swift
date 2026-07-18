import Foundation
import KeymappGRPC
import ZSAAssistCore

// Usage: zsa-poller-demo [seconds] [--stub] [--socket PATH]
// Polls Keymapp (or the stub with --stub) and prints the events the overlay
// would react to. Runs forever unless a duration in seconds is given.

setvbuf(stdout, nil, _IOLBF, 0)

var duration: Double?
var useStub = false
var socketOverride: String?

var arguments = ArraySlice(CommandLine.arguments.dropFirst())
while let argument = arguments.popFirst() {
    switch argument {
    case "--stub":
        useStub = true
    case "--socket":
        guard let path = arguments.popFirst() else {
            FileHandle.standardError.write(Data("--socket requires a path\n".utf8))
            exit(2)
        }
        socketOverride = path
    default:
        guard let seconds = Double(argument) else {
            FileHandle.standardError.write(Data("unrecognized argument: \(argument)\n".utf8))
            exit(2)
        }
        duration = seconds
    }
}

let client: any KeymappClient
if useStub {
    client = StubKeymappClient()
    print("Polling stub Keymapp client (Ctrl-C to stop)...")
} else {
    do {
        let socketPath = socketOverride ?? GRPCKeymappClient.defaultSocketPath()
        let real = try GRPCKeymappClient(socketPath: socketPath)
        do {
            _ = try await real.status()
        } catch KeymappError.noKeyboardConnected {
            print("No keyboard attached; asking Keymapp to connect to the first available one...")
            try await real.connectAnyKeyboard()
        }
        client = real
        print("Polling Keymapp at \(socketPath) (Ctrl-C to stop)...")
    } catch {
        print("Could not reach Keymapp: \(error)")
        print("Is Keymapp running with its API enabled (Keymapp settings)? Or run with --stub.")
        exit(1)
    }
}

let poller = LayerPoller(client: client)
let started = ContinuousClock.now

// Exit after the requested duration even if no events ever arrive
// (e.g. Keymapp reachable but no keyboard attached).
if let duration {
    Task {
        try? await Task.sleep(for: .seconds(duration))
        exit(0)
    }
}

func timestamp() -> String {
    let elapsed = started.duration(to: .now)
    let seconds = Double(elapsed.components.seconds)
        + Double(elapsed.components.attoseconds) * 1e-18
    return String(format: "%6.2fs", seconds)
}

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
