import Foundation
import GRPCCore
import GRPCNIOTransportHTTP2
import ZSAAssistCore

public enum KeymappError: Error, CustomStringConvertible {
    /// Keymapp is reachable but no keyboard is attached (use
    /// `connectAnyKeyboard()` or connect one in the Keymapp UI).
    case noKeyboardConnected
    /// The API socket doesn't exist — Keymapp isn't running or its API
    /// isn't enabled in settings.
    case socketNotFound(path: String)

    public var description: String {
        switch self {
        case .noKeyboardConnected:
            return "Keymapp reports no connected keyboard"
        case .socketNotFound(let path):
            return "Keymapp socket not found at \(path); make sure Keymapp is running and the API is enabled in its settings"
        }
    }
}

/// Real `KeymappClient` backed by Keymapp's gRPC API. On macOS Keymapp
/// serves the API over a Unix domain socket (same resolution order as ZSA's
/// Kontroll: $KEYMAPP_SOCKET, then ~/Library/Application Support, then the
/// App Store container path).
public final class GRPCKeymappClient: KeymappClient, Sendable {
    private let grpc: GRPCClient<HTTP2ClientTransport.Posix>
    private let service: Api_KeyboardService.Client<HTTP2ClientTransport.Posix>
    private let connections: Task<Void, any Error>

    public static func defaultSocketPath() -> String {
        let env = ProcessInfo.processInfo.environment["KEYMAPP_SOCKET"]
        if let env, !env.isEmpty {
            return env
        }
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let standard = "\(home)/Library/Application Support/.keymapp/keymapp.sock"
        if FileManager.default.fileExists(atPath: standard) {
            return standard
        }
        return "\(home)/Library/Containers/io.zsa.keymapp/Data/Library/Application Support/.keymapp/keymapp.sock"
    }

    public init(socketPath: String = GRPCKeymappClient.defaultSocketPath()) throws {
        guard FileManager.default.fileExists(atPath: socketPath) else {
            throw KeymappError.socketNotFound(path: socketPath)
        }
        let transport = try HTTP2ClientTransport.Posix(
            target: .unixDomainSocket(path: socketPath),
            transportSecurity: .plaintext
        )
        let grpc = GRPCClient(transport: transport)
        self.grpc = grpc
        self.service = Api_KeyboardService.Client(wrapping: grpc)
        self.connections = Task { try await grpc.runConnections() }
    }

    deinit {
        grpc.beginGracefulShutdown()
        connections.cancel()
    }

    public func status() async throws -> KeyboardStatus {
        var options = CallOptions.defaults
        options.timeout = .seconds(2)
        let reply = try await service.getStatus(Api_GetStatusRequest(), options: options)
        guard reply.hasConnectedKeyboard else {
            throw KeymappError.noKeyboardConnected
        }
        return KeyboardStatus(
            friendlyName: reply.connectedKeyboard.friendlyName,
            currentLayer: Int(reply.connectedKeyboard.currentLayer)
        )
    }

    /// Asks Keymapp to attach to the first available keyboard.
    @discardableResult
    public func connectAnyKeyboard() async throws -> Bool {
        try await service.connectAnyKeyboard(Api_ConnectAnyKeyboardRequest()).success
    }
}
