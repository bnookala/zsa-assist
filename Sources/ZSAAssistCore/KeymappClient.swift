/// A snapshot of the connected keyboard's state, mirroring the fields of
/// Keymapp's gRPC `ConnectedKeyboard` message that the overlay cares about.
public struct KeyboardStatus: Sendable, Equatable {
    public let friendlyName: String
    public let currentLayer: Int

    public init(friendlyName: String, currentLayer: Int) {
        self.friendlyName = friendlyName
        self.currentLayer = currentLayer
    }
}

/// Abstraction over the Keymapp API. The real implementation will call
/// Keymapp's gRPC `GetStatus` over localhost; `StubKeymappClient` simulates
/// it so the overlay UI can be developed without a keyboard attached.
public protocol KeymappClient: Sendable {
    /// One status snapshot. Throws when Keymapp is unreachable or no
    /// keyboard is connected.
    func status() async throws -> KeyboardStatus
}
