import Testing
@testable import AteliaKit

@Test func endpointBuildsBaseURL() {
    let endpoint = AteliaEndpoint(host: "127.0.0.1", port: 8787, usesTLS: false)
    #expect(endpoint.baseURL.absoluteString == "http://127.0.0.1:8787")
}
