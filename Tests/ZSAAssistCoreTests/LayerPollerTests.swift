import Testing
@testable import ZSAAssistCore

/// Returns a canned sequence of layers, then repeats the last one forever.
/// A `nil` entry simulates a failed status call.
private actor ScriptedClient: KeymappClient {
    private var layers: [Int?]

    init(layers: [Int?]) {
        precondition(!layers.isEmpty)
        self.layers = layers
    }

    struct Unreachable: Error {}

    func status() async throws -> KeyboardStatus {
        let layer = layers.count > 1 ? layers.removeFirst() : layers[0]
        guard let layer else { throw Unreachable() }
        return KeyboardStatus(friendlyName: "Test", currentLayer: layer)
    }
}

private func collect(_ poller: LayerPoller, count: Int) async -> [LayerEvent] {
    var events: [LayerEvent] = []
    for await event in poller.events() {
        events.append(event)
        if events.count == count { break }
    }
    return events
}

@Test func emitsConnectedThenTransitions() async {
    let client = ScriptedClient(layers: [0, 0, 2, 2, 0])
    let poller = LayerPoller(client: client, interval: .milliseconds(1))
    let events = await collect(poller, count: 3)
    #expect(events == [
        .connected(KeyboardStatus(friendlyName: "Test", currentLayer: 0)),
        .layerChanged(from: 0, to: 2),
        .layerChanged(from: 2, to: 0),
    ])
}

@Test func reportsConnectionLossAndReconnect() async {
    let client = ScriptedClient(layers: [1, nil, 3])
    let poller = LayerPoller(client: client, interval: .milliseconds(1))
    let events = await collect(poller, count: 3)
    #expect(events[0] == .connected(KeyboardStatus(friendlyName: "Test", currentLayer: 1)))
    guard case .connectionLost = events[1] else {
        Issue.record("expected connectionLost, got \(events[1])")
        return
    }
    #expect(events[2] == .connected(KeyboardStatus(friendlyName: "Test", currentLayer: 3)))
}

@Test func stubClientFollowsSchedule() async throws {
    let client = StubKeymappClient(schedule: [
        .init(layer: 0, seconds: 0.05),
        .init(layer: 2, seconds: 0.05),
    ])
    let first = try await client.status()
    #expect(first.currentLayer == 0)
    try await Task.sleep(for: .milliseconds(60))
    let second = try await client.status()
    #expect(second.currentLayer == 2)
}
