import Foundation

public struct AteliaHealthResponse: Sendable, Codable, Equatable {
    public enum DaemonStatus: String, Sendable, Codable, Equatable {
        case starting
        case running
        case ready
        case degraded
        case stopping
    }

    public enum StorageStatus: String, Sendable, Codable, Equatable {
        case ready
        case migrating
        case readOnly = "read_only"
        case unavailable
    }

    public struct BetaState: Sendable, Codable, Equatable {
        public var scope: String
        public var durability: String
        public var restartSemantics: String
        public var limits: [String]

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

    public var daemonStatus: DaemonStatus
    public var daemonVersion: String
    public var protocolVersion: String
    public var storageVersion: String
    public var storageStatus: StorageStatus
    public var capabilities: [String]
    public var betaState: BetaState?

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
    var secretaryStatus: SecretaryStatus {
        SecretaryStatus(
            phase: daemonStatus.secretaryPhase,
            message: nil
        )
    }
}

public extension AteliaHealthResponse.DaemonStatus {
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
