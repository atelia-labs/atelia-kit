import Foundation

/// Request payload for rendering canonical tool output in a specific output format.
public struct AteliaToolOutputRenderRequest: Sendable, Codable, Equatable {
    /// JSON keys for render requests.
    private enum CodingKeys: String, CodingKey {
        /// Target tool result reference.
        case toolResult = "tool_result"
        /// Requested output format.
        case format
    }

    /// Canonical tool-result reference used by the renderer.
    public var toolResult: AteliaToolResultRef
    /// Requested output format.
    public var format: AteliaToolOutputRenderFormat

    /// Creates a tool-output render request.
    public init(toolResult: AteliaToolResultRef, format: AteliaToolOutputRenderFormat) {
        self.toolResult = toolResult
        self.format = format
    }
}

/// Rendered tool-output response returned by the daemon.
public struct AteliaToolOutputRenderResponse: Sendable, Codable, Equatable {
    /// JSON keys for render responses.
    private enum CodingKeys: String, CodingKey {
        /// Protocol metadata.
        case metadata
        /// Canonical tool-result reference used for the render.
        case toolResult = "tool_result"
        /// Rendered output format.
        case format
        /// Rendered output text body.
        case renderedOutput = "rendered_output"
        /// Rendered output metadata.
        case renderedOutputMetadata = "rendered_output_metadata"
    }

    /// Protocol metadata returned by the route.
    public var metadata: AteliaProtocolMetadata
    /// Canonical tool-result reference used for the render.
    public var toolResult: AteliaToolResultRef
    /// Rendered output format.
    public var format: AteliaToolOutputRenderFormat
    /// Rendered output body.
    public var renderedOutput: String
    /// Metadata describing render quality and truncation.
    public var renderedOutputMetadata: AteliaRenderedToolOutputMetadata

    /// Creates a tool-output render response.
    public init(
        metadata: AteliaProtocolMetadata,
        toolResult: AteliaToolResultRef,
        format: AteliaToolOutputRenderFormat,
        renderedOutput: String,
        renderedOutputMetadata: AteliaRenderedToolOutputMetadata
    ) {
        self.metadata = metadata
        self.toolResult = toolResult
        self.format = format
        self.renderedOutput = renderedOutput
        self.renderedOutputMetadata = renderedOutputMetadata
    }
}

/// Canonical tool-result reference shape shared by render endpoints.
public struct AteliaToolResultRef: Sendable, Codable, Equatable {
    /// JSON keys for tool-result references.
    private enum CodingKeys: String, CodingKey {
        /// Canonical tool result identifier.
        case toolResultId = "tool_result_id"
        /// Canonical tool invocation identifier.
        case toolInvocationId = "tool_invocation_id"
        /// Job identifier that created the result.
        case jobId = "job_id"
        /// Repository identifier where the result was produced.
        case repositoryId = "repository_id"
        /// MIME type of tool output content.
        case contentType = "content_type"
    }

    /// Canonical tool result identifier.
    public var toolResultId: String
    /// Canonical tool invocation identifier.
    public var toolInvocationId: String
    /// Job identifier that created the result.
    public var jobId: String
    /// Repository identifier where the result was produced.
    public var repositoryId: String
    /// MIME type of tool output content.
    public var contentType: String

    /// Creates a canonical tool-result reference.
    public init(
        toolResultId: String,
        toolInvocationId: String,
        jobId: String,
        repositoryId: String,
        contentType: String
    ) {
        self.toolResultId = toolResultId
        self.toolInvocationId = toolInvocationId
        self.jobId = jobId
        self.repositoryId = repositoryId
        self.contentType = contentType
    }

    /// Creates a renderable tool-result reference from an event when every
    /// render endpoint key is present in the event refs.
    public init?(event: AteliaEvent) {
        let refs = event.refs
        guard let toolResultId = refs.toolResultId,
              let toolInvocationId = refs.toolInvocationId,
              let jobId = refs.jobId,
              let repositoryId = refs.repositoryId,
              let contentType = refs.contentType
        else {
            return nil
        }

        self.init(
            toolResultId: toolResultId,
            toolInvocationId: toolInvocationId,
            jobId: jobId,
            repositoryId: repositoryId,
            contentType: contentType
        )
    }
}

/// Output format accepted by render requests.
public enum AteliaToolOutputRenderFormat: Sendable, Codable, Equatable, RawRepresentable {
    /// Textual, human-targeted formatting.
    case text
    /// Canonical JSON string output.
    case json
    /// Structured TOON output.
    case toon
    /// Unknown future render format.
    case unknown(String)

    /// Creates a known/unknown format from wire value.
    public init(rawValue: String) {
        switch rawValue {
        case "text":
            self = .text
        case "json":
            self = .json
        case "toon":
            self = .toon
        default:
            self = .unknown(rawValue)
        }
    }

    /// Returns the wire value for the selected format.
    public var rawValue: String {
        switch self {
        case .text:
            return "text"
        case .json:
            return "json"
        case .toon:
            return "toon"
        case .unknown(let rawValue):
            return rawValue
        }
    }

    /// Decodes and preserves unknown format values.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Self(rawValue: rawValue)
    }

    /// Encodes the selected format as its wire value.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// Metadata returned with rendered output.
public struct AteliaRenderedToolOutputMetadata: Sendable, Codable, Equatable {
    /// JSON keys for output metadata.
    private enum CodingKeys: String, CodingKey {
        /// Whether render output was degraded or policy-compacted.
        case degraded
        /// Optional reason for rendering fallback.
        case fallbackReason = "fallback_reason"
        /// Optional truncation metadata.
        case truncation
    }

    /// Indicates degraded rendering.
    public var degraded: Bool
    /// Optional human-readable fallback reason.
    public var fallbackReason: String?
    /// Optional truncation metadata.
    public var truncation: AteliaRenderedToolOutputTruncation?

    /// Creates render output metadata.
    public init(
        degraded: Bool,
        fallbackReason: String? = nil,
        truncation: AteliaRenderedToolOutputTruncation? = nil
    ) {
        self.degraded = degraded
        self.fallbackReason = fallbackReason
        self.truncation = truncation
    }
}

/// Truncation metadata returned with rendered output.
public struct AteliaRenderedToolOutputTruncation: Sendable, Codable, Equatable {
    /// JSON keys for output truncation metadata.
    private enum CodingKeys: String, CodingKey {
        /// Total bytes before truncation.
        case originalBytes = "original_bytes"
        /// Total bytes retained.
        case retainedBytes = "retained_bytes"
        /// Truncation reason.
        case reason
    }

    /// Total bytes before truncation.
    public var originalBytes: Int64
    /// Total bytes retained.
    public var retainedBytes: Int64
    /// Truncation reason.
    public var reason: String

    /// Creates truncation metadata.
    public init(
        originalBytes: Int64,
        retainedBytes: Int64,
        reason: String
    ) {
        self.originalBytes = originalBytes
        self.retainedBytes = retainedBytes
        self.reason = reason
    }
}
