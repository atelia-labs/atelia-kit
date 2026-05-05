import Foundation

/// Health payload returned by the secretary daemon.
public struct AteliaHealthResponse: Sendable, Codable, Equatable {
    /// High-level daemon state.
    public enum DaemonStatus: String, Sendable, Codable, Equatable {
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
    }

    /// Storage state reported by the daemon.
    public enum StorageStatus: String, Sendable, Codable, Equatable {
        /// Storage is ready for use.
        case ready
        /// Storage is migrating between versions or layouts.
        case migrating
        /// Storage is available in read-only mode.
        case readOnly = "read_only"
        /// Storage is not currently available.
        case unavailable
    }

    /// Optional beta metadata surfaced by the daemon.
    public struct BetaState: Sendable, Codable, Equatable {
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
        case .running, .ready:
            return .ready
        case .degraded:
            return .degraded
        case .stopping:
            return .offline
        }
    }
}
