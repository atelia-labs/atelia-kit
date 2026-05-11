import Foundation

/// Actor-backed cache for the latest package trust index response.
public actor AteliaPackageTrustIndexStore {
    private let client: any AteliaClient
    private let session: AteliaSession
    private var latestResponse: AteliaPackageTrustIndexResponse?
    private var packagesByID: [String: AteliaPackageTrustIndexEntry] = [:]
    private var nextReloadGeneration = 0
    private var latestAppliedGeneration = 0
    private var clearGeneration = 0

    /// Creates a trust index store for a client/session pair.
    public init(client: some AteliaClient, session: AteliaSession) {
        self.client = client
        self.session = session
    }

    /// Reloads the latest trust index response from the client.
    public func reload() async throws {
        nextReloadGeneration += 1
        let reloadGeneration = nextReloadGeneration
        let response = try await client.packageTrustIndexResponse(for: session)
        guard reloadGeneration > latestAppliedGeneration,
              reloadGeneration > clearGeneration else {
            return
        }
        latestAppliedGeneration = reloadGeneration
        latestResponse = response
        packagesByID = response.packages.reduce(into: [:]) { index, entry in
            index[entry.packageId] = entry
        }
    }

    /// Clears any cached trust index state.
    public func clear() {
        clearGeneration = nextReloadGeneration
        latestResponse = nil
        packagesByID.removeAll(keepingCapacity: true)
    }

    /// Returns the latest trust index response, if one has been loaded.
    public var response: AteliaPackageTrustIndexResponse? {
        latestResponse
    }

    /// Returns the latest protocol metadata, if one has been loaded.
    public var metadata: AteliaProtocolMetadata? {
        latestResponse?.metadata
    }

    /// Returns the current package trust index entries.
    public var packages: [AteliaPackageTrustIndexEntry] {
        latestResponse?.packages ?? []
    }

    /// Returns a package trust index entry for the given package identifier.
    public func package(id: String) -> AteliaPackageTrustIndexEntry? {
        packagesByID[id]
    }
}
