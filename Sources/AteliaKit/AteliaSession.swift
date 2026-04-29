import Foundation

public struct AteliaSession: Sendable, Equatable, Identifiable {
    public var id: UUID
    public var endpoint: AteliaEndpoint
    public var displayName: String

    public init(
        id: UUID = UUID(),
        endpoint: AteliaEndpoint = AteliaEndpoint(),
        displayName: String = "Local Secretary"
    ) {
        self.id = id
        self.endpoint = endpoint
        self.displayName = displayName
    }
}
