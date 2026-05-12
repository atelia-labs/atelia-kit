import Foundation

/// Product-facing representation of a package manifest payload for validation.
public struct AteliaPackageManifest: Sendable, Codable, Equatable {
    /// Dynamic manifest fields decoded from or encoded to a protocol manifest object.
    public var fields: [String: AteliaPackageManifestValue]

    /// Creates an empty manifest container.
    public init(fields: [String: AteliaPackageManifestValue] = [:]) {
        self.fields = fields
    }

    /// Accesses a manifest field by key.
    public subscript(_ key: String) -> AteliaPackageManifestValue? {
        get { fields[key] }
        set { fields[key] = newValue }
    }

    /// Decodes a manifest from an arbitrary protocol JSON object.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        fields = try container.decode([String: AteliaPackageManifestValue].self)
    }

    /// Encodes the manifest as its original protocol JSON object.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(fields)
    }
}

/// Represents one arbitrary JSON value inside a package manifest.
public indirect enum AteliaPackageManifestValue: Sendable, Codable, Equatable {
    /// JSON object value.
    case object([String: AteliaPackageManifestValue])
    /// JSON array value.
    case array([AteliaPackageManifestValue])
    /// JSON string value.
    case string(String)
    /// JSON number value.
    case number(Decimal)
    /// JSON boolean value.
    case bool(Bool)
    /// JSON null.
    case null

    /// Decodes arbitrary JSON values while preserving shape.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
            return
        }
        if let object = try? container.decode([String: AteliaPackageManifestValue].self) {
            self = .object(object)
            return
        }
        if let array = try? container.decode([AteliaPackageManifestValue].self) {
            self = .array(array)
            return
        }
        if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
            return
        }
        if let decimalValue = try? container.decode(Decimal.self) {
            self = .number(decimalValue)
            return
        }
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
            return
        }

        throw DecodingError.typeMismatch(
            AteliaPackageManifestValue.self,
            .init(
                codingPath: container.codingPath,
                debugDescription: "Expected valid JSON value"
            )
        )
    }

    /// Encodes an arbitrary JSON value in its original shape.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .object(let object):
            try container.encode(object)
        case .array(let array):
            try container.encode(array)
        case .string(let string):
            try container.encode(string)
        case .number(let number):
            try container.encode(number)
        case .bool(let bool):
            try container.encode(bool)
        case .null:
            try container.encodeNil()
        }
    }
}

/// Request body for POST `/v1/packages/validate`.
public struct AteliaPackageValidationRequest: Sendable, Codable, Equatable {
    /// JSON keys for validation request fields.
    private enum CodingKeys: String, CodingKey {
        /// Package manifest to validate.
        case manifest
        /// Whether to allow locally unsigned packages.
        case approveLocalUnsigned = "approve_local_unsigned"
        /// Whether to allow local process runtime for the package.
        case allowLocalProcessRuntime = "allow_local_process_runtime"
        /// Whether to allow source authority changes.
        case approveSourceChange = "approve_source_change"
    }

    /// Extension manifest payload to validate.
    public var manifest: AteliaPackageManifest
    /// Accepts local unsigned package manifests.
    public var approveLocalUnsigned: Bool
    /// Allows local process runtime mode for this validation.
    public var allowLocalProcessRuntime: Bool
    /// Approves source authority change during validation.
    public var approveSourceChange: Bool

    /// Creates a package validation request.
    public init(
        manifest: AteliaPackageManifest,
        approveLocalUnsigned: Bool = false,
        allowLocalProcessRuntime: Bool = false,
        approveSourceChange: Bool = false
    ) {
        self.manifest = manifest
        self.approveLocalUnsigned = approveLocalUnsigned
        self.allowLocalProcessRuntime = allowLocalProcessRuntime
        self.approveSourceChange = approveSourceChange
    }

    /// Decodes validation requests using Secretary's default-false flag contract.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.manifest = try container.decode(AteliaPackageManifest.self, forKey: .manifest)
        self.approveLocalUnsigned = try container.contains(.approveLocalUnsigned)
            ? container.decode(Bool.self, forKey: .approveLocalUnsigned)
            : false
        self.allowLocalProcessRuntime = try container.contains(.allowLocalProcessRuntime)
            ? container.decode(Bool.self, forKey: .allowLocalProcessRuntime)
            : false
        self.approveSourceChange = try container.contains(.approveSourceChange)
            ? container.decode(Bool.self, forKey: .approveSourceChange)
            : false
    }
}

/// Response envelope returned from POST `/v1/packages/validate`.
public struct AteliaPackageValidationResponse: Sendable, Codable, Equatable {
    /// JSON keys for validation response fields.
    private enum CodingKeys: String, CodingKey {
        /// Protocol metadata attached to the validation response.
        case metadata
        /// Validated package manifest.
        case manifest
        /// Determined package boundary.
        case boundary
    }

    /// Protocol metadata attached to the validation response.
    public var metadata: AteliaProtocolMetadata
    /// Validated package manifest with canonical or normalized content.
    public var manifest: AteliaPackageManifest
    /// Package trust boundary determined during validation.
    public var boundary: AteliaPackageTrustIndexEntry.Boundary

    /// Creates a package validation response.
    public init(
        metadata: AteliaProtocolMetadata,
        manifest: AteliaPackageManifest,
        boundary: AteliaPackageTrustIndexEntry.Boundary
    ) {
        self.metadata = metadata
        self.manifest = manifest
        self.boundary = boundary
    }
}
