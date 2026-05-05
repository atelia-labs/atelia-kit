import Foundation

/// Repertoire entry describing an available protocol action.
public struct AteliaRepertoireEntry: Sendable, Codable, Equatable, Identifiable {
    /// Risk classification for the entry.
    public enum RiskTier: String, Sendable, Codable, Equatable {
        /// Lowest-risk action tier.
        case r0
        /// Low-risk action tier.
        case r1
        /// Moderate-risk action tier.
        case r2
        /// High-risk action tier.
        case r3
        /// Highest-risk action tier.
        case r4
    }

    /// Scope where the entry applies.
    public enum Scope: String, Sendable, Codable, Equatable {
        /// Applies across the workspace.
        case workspace
        /// Applies to a repository.
        case repository
        /// Applies to a branch.
        case branch
        /// Applies to a thread.
        case thread
    }

    /// Invocation model used by the entry.
    public enum InvocationStyle: String, Sendable, Codable, Equatable {
        /// Runs synchronously.
        case sync
        /// Runs asynchronously.
        case async
        /// Streams results as they become available.
        case streaming
        /// Runs in the background.
        case background
    }

    /// Visibility of the entry to different audiences.
    public enum Visibility: String, Sendable, Codable, Equatable {
        /// Visible to agents.
        case agent
        /// Visible to humans.
        case human
        /// Visible to both agents and humans.
        case both
    }

    /// Availability state for the entry.
    public enum Availability: Sendable, Codable, Equatable {
        /// The entry can be run now.
        case available
        /// The entry is unavailable, with a reason.
        case unavailable(reason: String)

        private enum CodingKeys: String, CodingKey {
            case state
            case reason
        }

        private enum State: String, Codable {
            case available
            case unavailable
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            switch try container.decode(State.self, forKey: .state) {
            case .available:
                self = .available
            case .unavailable:
                self = .unavailable(reason: try container.decode(String.self, forKey: .reason))
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .available:
                try container.encode(State.available, forKey: .state)
            case .unavailable(let reason):
                try container.encode(State.unavailable, forKey: .state)
                try container.encode(reason, forKey: .reason)
            }
        }
    }

    /// Stable identifier for the entry.
    public var id: String
    /// Human-readable entry label.
    public var label: String
    /// Declared effect of running the entry.
    public var declaredEffect: String
    /// Risk tier assigned to the entry.
    public var riskTier: RiskTier
    /// Scope where the entry applies.
    public var scope: Scope
    /// Invocation style used by the entry.
    public var invocationStyle: InvocationStyle
    /// Availability of the entry.
    public var availability: Availability
    /// Audience visibility for the entry.
    public var visibility: Visibility
    /// Whether the current user or agent has permission to run it.
    public var permission: Bool
    /// Whether the entry can be run right now.
    public var runnableNow: Bool

    /// Creates a repertoire entry.
    public init(
        id: String,
        label: String,
        declaredEffect: String,
        riskTier: RiskTier,
        scope: Scope,
        invocationStyle: InvocationStyle,
        availability: Availability,
        visibility: Visibility,
        permission: Bool,
        runnableNow: Bool
    ) {
        self.id = id
        self.label = label
        self.declaredEffect = declaredEffect
        self.riskTier = riskTier
        self.scope = scope
        self.invocationStyle = invocationStyle
        self.availability = availability
        self.visibility = visibility
        self.permission = permission
        self.runnableNow = runnableNow
    }
}
