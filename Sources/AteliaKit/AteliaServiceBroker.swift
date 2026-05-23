import Foundation

/// Request used to authorize a package-to-package AEP service call.
public struct AteliaAuthorizeServiceCallRequest: Sendable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case callerExtensionId = "caller_extension_id"
        case calleeExtensionId = "callee_extension_id"
        case service
        case method
        case schemaVersion = "schema_version"
        case requiredPermission = "required_permission"
    }

    public var callerExtensionId: String
    public var calleeExtensionId: String
    public var service: String
    public var method: String
    public var schemaVersion: String
    public var requiredPermission: String?

    public init(
        callerExtensionId: String,
        calleeExtensionId: String,
        service: String,
        method: String,
        schemaVersion: String,
        requiredPermission: String? = nil
    ) {
        self.callerExtensionId = callerExtensionId
        self.calleeExtensionId = calleeExtensionId
        self.service = service
        self.method = method
        self.schemaVersion = schemaVersion
        self.requiredPermission = requiredPermission
    }
}

/// Authorization grant returned by Secretary's AEP service broker control plane.
public struct AteliaServiceCallGrant: Sendable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case callerExtensionId = "caller_extension_id"
        case callerVersion = "caller_version"
        case calleeExtensionId = "callee_extension_id"
        case calleeVersion = "callee_version"
        case service
        case method
        case schemaVersion = "schema_version"
        case requiredPermission = "required_permission"
    }

    public var callerExtensionId: String
    public var callerVersion: String
    public var calleeExtensionId: String
    public var calleeVersion: String
    public var service: String
    public var method: String
    public var schemaVersion: String
    public var requiredPermission: String

    public init(
        callerExtensionId: String,
        callerVersion: String,
        calleeExtensionId: String,
        calleeVersion: String,
        service: String,
        method: String,
        schemaVersion: String,
        requiredPermission: String
    ) {
        self.callerExtensionId = callerExtensionId
        self.callerVersion = callerVersion
        self.calleeExtensionId = calleeExtensionId
        self.calleeVersion = calleeVersion
        self.service = service
        self.method = method
        self.schemaVersion = schemaVersion
        self.requiredPermission = requiredPermission
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
        case callerExtensionId = "caller_extension_id"
        case calleeExtensionId = "callee_extension_id"
        case service
        case method
        case schemaVersion = "schema_version"
        case requiredPermission = "required_permission"
    }

    public var callerExtensionId: String
    public var calleeExtensionId: String
    public var service: String
    public var method: String
    public var schemaVersion: String
    public var requiredPermission: String?

    public init(
        callerExtensionId: String,
        calleeExtensionId: String,
        service: String,
        method: String,
        schemaVersion: String,
        requiredPermission: String? = nil
    ) {
        self.callerExtensionId = callerExtensionId
        self.calleeExtensionId = calleeExtensionId
        self.service = service
        self.method = method
        self.schemaVersion = schemaVersion
        self.requiredPermission = requiredPermission
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
