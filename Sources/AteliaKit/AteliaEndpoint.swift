import Foundation

/// Network endpoint used to reach a secretary daemon.
public struct AteliaEndpoint: Sendable, Equatable {
    /// Hostname or IP address of the daemon.
    public var host: String
    /// Port used by the daemon.
    public var port: Int
    /// Whether the endpoint uses TLS.
    public var usesTLS: Bool

    /// Creates a daemon endpoint.
    public init(host: String = "localhost", port: Int = 8080, usesTLS: Bool = false) {
        self.host = host
        self.port = port
        self.usesTLS = usesTLS
    }

    /// Base URL derived from the endpoint settings.
    public var baseURL: URL {
        var components = URLComponents()
        components.scheme = usesTLS ? "https" : "http"
        components.host = host
        components.port = port
        return components.url!
    }
}
