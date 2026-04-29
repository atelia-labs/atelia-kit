import Foundation

public struct AteliaEndpoint: Sendable, Equatable {
    public var host: String
    public var port: Int
    public var usesTLS: Bool

    public init(host: String = "localhost", port: Int = 8787, usesTLS: Bool = false) {
        self.host = host
        self.port = port
        self.usesTLS = usesTLS
    }

    public var baseURL: URL {
        var components = URLComponents()
        components.scheme = usesTLS ? "https" : "http"
        components.host = host
        components.port = port
        return components.url!
    }
}
