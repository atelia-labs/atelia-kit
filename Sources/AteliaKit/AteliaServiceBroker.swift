import Foundation

/// Request used to authorize a package-to-package AEP service call.
public struct AteliaAuthorizeServiceCallRequest: Sendable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case callerPackageId = "caller_package_id"
        case callerComponentId = "caller_component_id"
        case callerExtensionId = "caller_extension_id"
        case calleePackageId = "callee_package_id"
        case calleeComponentId = "callee_component_id"
        case calleeExtensionId = "callee_extension_id"
        case service
        case method
        case schemaVersion = "schema_version"
        case requiredPermissions = "required_permissions"
        case requiredPermission = "required_permission"
    }

    public var callerPackageId: String
    public var callerComponentId: String?
    public var calleePackageId: String
    public var calleeComponentId: String?
    public var service: String
    public var method: String
    public var schemaVersion: String
    /// Canonical wire key is `required_permissions` (array). A singular
    /// `required_permission` is accepted for backward compatibility.
    public var requiredPermissions: [String]

    public init(
        callerPackageId: String,
        callerComponentId: String? = nil,
        calleePackageId: String,
        calleeComponentId: String? = nil,
        service: String,
        method: String,
        schemaVersion: String,
        requiredPermissions: [String] = []
    ) {
        self.callerPackageId = callerPackageId
        self.callerComponentId = callerComponentId
        self.calleePackageId = calleePackageId
        self.calleeComponentId = calleeComponentId
        self.service = service
        self.method = method
        self.schemaVersion = schemaVersion
        self.requiredPermissions = requiredPermissions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.callerPackageId = try container.decodePreferredString(
            canonical: .callerPackageId,
            fallback: .callerExtensionId
        )
        self.callerComponentId = try container.decodeIfPresent(String.self, forKey: .callerComponentId)
        self.calleePackageId = try container.decodePreferredString(
            canonical: .calleePackageId,
            fallback: .calleeExtensionId
        )
        self.calleeComponentId = try container.decodeIfPresent(String.self, forKey: .calleeComponentId)
        self.service = try container.decode(String.self, forKey: .service)
        self.method = try container.decode(String.self, forKey: .method)
        self.schemaVersion = try container.decode(String.self, forKey: .schemaVersion)
        if container.contains(.requiredPermissions) {
            self.requiredPermissions = try container.decode([String].self, forKey: .requiredPermissions)
        } else {
            self.requiredPermissions = try container.decodeIfPresent(String.self, forKey: .requiredPermission)
                .map { [$0] } ?? []
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(callerPackageId, forKey: .callerPackageId)
        try container.encodeIfPresent(callerComponentId, forKey: .callerComponentId)
        try container.encode(calleePackageId, forKey: .calleePackageId)
        try container.encodeIfPresent(calleeComponentId, forKey: .calleeComponentId)
        try container.encode(service, forKey: .service)
        try container.encode(method, forKey: .method)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(requiredPermissions, forKey: .requiredPermissions)
    }
}

/// Authorization grant returned by Secretary's AEP service broker control plane.
public struct AteliaServiceCallGrant: Sendable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case callerPackageId = "caller_package_id"
        case callerComponentId = "caller_component_id"
        case callerExtensionId = "caller_extension_id"
        case calleePackageId = "callee_package_id"
        case calleeComponentId = "callee_component_id"
        case calleeExtensionId = "callee_extension_id"
        case callerVersion = "caller_version"
        case calleeVersion = "callee_version"
        case service
        case method
        case schemaVersion = "schema_version"
        case requiredPermissions = "required_permissions"
        case requiredPermission = "required_permission"
    }

    public var callerPackageId: String
    public var callerComponentId: String?
    public var callerVersion: String
    public var calleePackageId: String
    public var calleeComponentId: String?
    public var calleeVersion: String
    public var service: String
    public var method: String
    public var schemaVersion: String
    /// Canonical wire key is `required_permissions` (array). A singular
    /// `required_permission` is accepted for backward compatibility.
    public var requiredPermissions: [String]

    public init(
        callerPackageId: String,
        callerComponentId: String? = nil,
        callerVersion: String,
        calleePackageId: String,
        calleeComponentId: String? = nil,
        calleeVersion: String,
        service: String,
        method: String,
        schemaVersion: String,
        requiredPermissions: [String] = []
    ) {
        self.callerPackageId = callerPackageId
        self.callerComponentId = callerComponentId
        self.callerVersion = callerVersion
        self.calleePackageId = calleePackageId
        self.calleeComponentId = calleeComponentId
        self.calleeVersion = calleeVersion
        self.service = service
        self.method = method
        self.schemaVersion = schemaVersion
        self.requiredPermissions = requiredPermissions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.callerPackageId = try container.decodePreferredString(
            canonical: .callerPackageId,
            fallback: .callerExtensionId
        )
        self.callerComponentId = try container.decodeIfPresent(String.self, forKey: .callerComponentId)
        self.callerVersion = try container.decode(String.self, forKey: .callerVersion)
        self.calleePackageId = try container.decodePreferredString(
            canonical: .calleePackageId,
            fallback: .calleeExtensionId
        )
        self.calleeComponentId = try container.decodeIfPresent(String.self, forKey: .calleeComponentId)
        self.calleeVersion = try container.decode(String.self, forKey: .calleeVersion)
        self.service = try container.decode(String.self, forKey: .service)
        self.method = try container.decode(String.self, forKey: .method)
        self.schemaVersion = try container.decode(String.self, forKey: .schemaVersion)
        if container.contains(.requiredPermissions) {
            self.requiredPermissions = try container.decode([String].self, forKey: .requiredPermissions)
        } else {
            self.requiredPermissions = try container.decodeIfPresent(String.self, forKey: .requiredPermission)
                .map { [$0] } ?? []
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(callerPackageId, forKey: .callerPackageId)
        try container.encodeIfPresent(callerComponentId, forKey: .callerComponentId)
        try container.encode(callerVersion, forKey: .callerVersion)
        try container.encode(calleePackageId, forKey: .calleePackageId)
        try container.encodeIfPresent(calleeComponentId, forKey: .calleeComponentId)
        try container.encode(calleeVersion, forKey: .calleeVersion)
        try container.encode(service, forKey: .service)
        try container.encode(method, forKey: .method)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(requiredPermissions, forKey: .requiredPermissions)
    }
}

/// Response envelope returned by Secretary after service call authorization.
public struct AteliaAuthorizeServiceCallResponse: Sendable, Codable, Equatable {
    public var metadata: AteliaProtocolMetadata
    public var grant: AteliaServiceCallGrant

    public init(
        metadata: AteliaProtocolMetadata,
        grant: AteliaServiceCallGrant
    ) {
        self.metadata = metadata
        self.grant = grant
    }
}

/// Request used to execute a live package-to-package AEP service call.
public struct AteliaServiceCallRequest: Sendable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case callerPackageId = "caller_package_id"
        case callerComponentId = "caller_component_id"
        case callerExtensionId = "caller_extension_id"
        case calleePackageId = "callee_package_id"
        case calleeComponentId = "callee_component_id"
        case calleeExtensionId = "callee_extension_id"
        case service
        case method
        case schemaVersion = "schema_version"
        case requiredPermissions = "required_permissions"
        case requiredPermission = "required_permission"
    }

    public var callerPackageId: String
    public var callerComponentId: String?
    public var calleePackageId: String
    public var calleeComponentId: String?
    public var service: String
    public var method: String
    public var schemaVersion: String
    /// Canonical wire key is `required_permissions` (array). A singular
    /// `required_permission` is accepted for backward compatibility.
    public var requiredPermissions: [String]

    public init(
        callerPackageId: String,
        callerComponentId: String? = nil,
        calleePackageId: String,
        calleeComponentId: String? = nil,
        service: String,
        method: String,
        schemaVersion: String,
        requiredPermissions: [String] = []
    ) {
        self.callerPackageId = callerPackageId
        self.callerComponentId = callerComponentId
        self.calleePackageId = calleePackageId
        self.calleeComponentId = calleeComponentId
        self.service = service
        self.method = method
        self.schemaVersion = schemaVersion
        self.requiredPermissions = requiredPermissions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.callerPackageId = try container.decodePreferredString(
            canonical: .callerPackageId,
            fallback: .callerExtensionId
        )
        self.callerComponentId = try container.decodeIfPresent(String.self, forKey: .callerComponentId)
        self.calleePackageId = try container.decodePreferredString(
            canonical: .calleePackageId,
            fallback: .calleeExtensionId
        )
        self.calleeComponentId = try container.decodeIfPresent(String.self, forKey: .calleeComponentId)
        self.service = try container.decode(String.self, forKey: .service)
        self.method = try container.decode(String.self, forKey: .method)
        self.schemaVersion = try container.decode(String.self, forKey: .schemaVersion)
        if container.contains(.requiredPermissions) {
            self.requiredPermissions = try container.decode([String].self, forKey: .requiredPermissions)
        } else {
            self.requiredPermissions = try container.decodeIfPresent(String.self, forKey: .requiredPermission)
                .map { [$0] } ?? []
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(callerPackageId, forKey: .callerPackageId)
        try container.encodeIfPresent(callerComponentId, forKey: .callerComponentId)
        try container.encode(calleePackageId, forKey: .calleePackageId)
        try container.encodeIfPresent(calleeComponentId, forKey: .calleeComponentId)
        try container.encode(service, forKey: .service)
        try container.encode(method, forKey: .method)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(requiredPermissions, forKey: .requiredPermissions)
    }
}

/// Result returned by a live service call execution.
public struct AteliaServiceCallExecutionResult: Sendable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case status
        case outcome
        case reason
        case reasonCode = "reason_code"
    }

    public var status: String
    public var outcome: String
    public var reason: String
    public var reasonCode: String

    public init(
        status: String,
        outcome: String,
        reason: String,
        reasonCode: String
    ) {
        self.status = status
        self.outcome = outcome
        self.reason = reason
        self.reasonCode = reasonCode
    }
}

/// Response envelope returned by Secretary after live service execution.
public struct AteliaServiceCallResponse: Sendable, Codable, Equatable {
    public var metadata: AteliaProtocolMetadata
    public var grant: AteliaServiceCallGrant
    public var result: AteliaServiceCallExecutionResult

    public init(
        metadata: AteliaProtocolMetadata,
        grant: AteliaServiceCallGrant,
        result: AteliaServiceCallExecutionResult
    ) {
        self.metadata = metadata
        self.grant = grant
        self.result = result
    }
}

private extension KeyedDecodingContainer {
    func decodePreferredString(
        canonical: Key,
        fallback legacy: Key
    ) throws -> String {
        if contains(canonical) {
            guard let value = try decodeIfPresent(String.self, forKey: canonical) else {
                let debugPath = codingPath + [canonical]
                throw DecodingError.valueNotFound(
                    String.self,
                    DecodingError.Context(
                        codingPath: debugPath,
                        debugDescription: "Expected `\(canonical.stringValue)` to be a non-null string."
                    )
                )
            }
            return value
        }

        return try decode(String.self, forKey: legacy)
    }
}
