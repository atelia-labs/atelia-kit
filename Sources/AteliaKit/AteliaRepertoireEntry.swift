import Foundation

public struct AteliaRepertoireEntry: Sendable, Codable, Equatable, Identifiable {
    public enum RiskTier: String, Sendable, Codable, Equatable {
        case r0
        case r1
        case r2
        case r3
        case r4
    }

    public enum Scope: String, Sendable, Codable, Equatable {
        case workspace
        case repository
        case branch
        case thread
    }

    public enum InvocationStyle: String, Sendable, Codable, Equatable {
        case sync
        case async
        case streaming
        case background
    }

    public enum Visibility: String, Sendable, Codable, Equatable {
        case agent
        case human
        case both
    }

    public enum Availability: Sendable, Codable, Equatable {
        case available
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

    public var id: String
    public var label: String
    public var declaredEffect: String
    public var riskTier: RiskTier
    public var scope: Scope
    public var invocationStyle: InvocationStyle
    public var availability: Availability
    public var visibility: Visibility
    public var permission: Bool
    public var runnableNow: Bool

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
