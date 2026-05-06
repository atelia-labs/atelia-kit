import Foundation

/// Health payload returned by the secretary daemon.
public struct AteliaHealthResponse: Sendable, Codable, Equatable {
    /// High-level daemon state.
    public enum DaemonStatus: Sendable, Codable, Equatable, RawRepresentable {
        /// The daemon is starting up.
        case starting
        /// The daemon is running but not yet ready for use.
        case running
        /// The daemon is ready for requests.
        case ready
        /// The daemon is operating with reduced health.
        case degraded
        /// The daemon is shutting down.
        case stopping
        /// A daemon status this client version does not know yet.
        case unknown(String)

        public init(rawValue: String) {
            switch rawValue {
            case "starting":
                self = .starting
            case "running":
                self = .running
            case "ready":
                self = .ready
            case "degraded":
                self = .degraded
            case "stopping":
                self = .stopping
            default:
                self = .unknown(rawValue)
            }
        }

        public var rawValue: String {
            switch self {
            case .starting:
                return "starting"
            case .running:
                return "running"
            case .ready:
                return "ready"
            case .degraded:
                return "degraded"
            case .stopping:
                return "stopping"
            case .unknown(let rawValue):
                return rawValue
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            self = Self(rawValue: rawValue)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
    }

    /// Storage state reported by the daemon.
    public enum StorageStatus: Sendable, Codable, Equatable, RawRepresentable {
        /// Storage is ready for use.
        case ready
        /// Storage is migrating between versions or layouts.
        case migrating
        /// Storage is available in read-only mode.
        case readOnly
        /// Storage is not currently available.
        case unavailable
        /// A storage status this client version does not know yet.
        case unknown(String)

        public init(rawValue: String) {
            switch rawValue {
            case "ready":
                self = .ready
            case "migrating":
                self = .migrating
            case "read_only":
                self = .readOnly
            case "unavailable":
                self = .unavailable
            default:
                self = .unknown(rawValue)
            }
        }

        public var rawValue: String {
            switch self {
            case .ready:
                return "ready"
            case .migrating:
                return "migrating"
            case .readOnly:
                return "read_only"
            case .unavailable:
                return "unavailable"
            case .unknown(let rawValue):
                return rawValue
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            self = Self(rawValue: rawValue)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
    }

    /// Optional beta metadata surfaced by the daemon.
    public struct BetaState: Sendable, Codable, Equatable {
        private enum CodingKeys: String, CodingKey {
            case scope
            case durability
            case restartSemantics = "restart_semantics"
            case limits
        }

        /// Scope covered by the beta state.
        public var scope: String
        /// Durability expectations for the beta feature.
        public var durability: String
        /// Restart behavior for the beta feature.
        public var restartSemantics: String
        /// Operational limits or constraints for the beta feature.
        public var limits: [String]

        /// Creates a beta-state payload.
        public init(
            scope: String,
            durability: String,
            restartSemantics: String,
            limits: [String] = []
        ) {
            self.scope = scope
            self.durability = durability
            self.restartSemantics = restartSemantics
            self.limits = limits
        }
    }

    private enum CodingKeys: String, CodingKey {
        case daemonStatus = "daemon_status"
        case daemonVersion = "daemon_version"
        case protocolVersion = "protocol_version"
        case storageVersion = "storage_version"
        case storageStatus = "storage_status"
        case capabilities
        case betaState = "beta_state"
    }

    /// Current daemon status.
    public var daemonStatus: DaemonStatus
    /// Version of the daemon process.
    public var daemonVersion: String
    /// Protocol version supported by the daemon.
    public var protocolVersion: String
    /// Version of the storage layer.
    public var storageVersion: String
    /// Current storage status.
    public var storageStatus: StorageStatus
    /// Capability flags advertised by the daemon.
    public var capabilities: [String]
    /// Optional beta metadata advertised by the daemon.
    public var betaState: BetaState?

    /// Creates a health payload.
    public init(
        daemonStatus: DaemonStatus,
        daemonVersion: String,
        protocolVersion: String,
        storageVersion: String,
        storageStatus: StorageStatus,
        capabilities: [String],
        betaState: BetaState? = nil
    ) {
        self.daemonStatus = daemonStatus
        self.daemonVersion = daemonVersion
        self.protocolVersion = protocolVersion
        self.storageVersion = storageVersion
        self.storageStatus = storageStatus
        self.capabilities = capabilities
        self.betaState = betaState
    }
}

public extension AteliaHealthResponse {
    /// Derived secretary status mapped from the daemon health response.
    var secretaryStatus: SecretaryStatus {
        SecretaryStatus(
            phase: daemonStatus.secretaryPhase,
            message: nil
        )
    }
}

public extension AteliaHealthResponse.DaemonStatus {
    /// Maps daemon health into the secretary status model.
    var secretaryPhase: SecretaryStatus.Phase {
        switch self {
        case .starting:
            return .starting
        case .running:
            return .starting
        case .ready:
            return .ready
        case .degraded:
            return .degraded
        case .stopping:
            return .offline
        case .unknown:
            return .degraded
        }
    }
}
