import Foundation
import Hummingbird

enum ProjectStatus: String, Codable, Sendable {
    case idle
    case syncing
    case building
    case deploying
    case running
    case stopped
    case failed
}

enum ReleaseStatus: String, Codable, Sendable {
    case ready
    case running
    case failed
    case skipped
}

enum DeploymentAction: String, Codable, Sendable {
    case deploy
    case start
    case stop
    case restart
    case rollback
}

enum DeploymentStatus: String, Codable, Sendable {
    case running
    case succeeded
    case failed
}

struct CreateProjectRequest: Codable, Sendable {
    let id: String
    let name: String
    let source: GitSourceConfiguration
    let environment: [String: String]?
}

struct UpdateProjectRequest: Codable, Sendable {
    let name: String
    let source: GitSourceConfiguration
    let environment: [String: String]?
}

struct DeleteProjectResponse: ResponseCodable, Equatable, Sendable {
    let projectId: String
    let removedImages: Int
    let removedVolumes: Int
    let volumesPurged: Bool
}

struct DeployProjectRequest: Codable, Sendable {
    let releaseId: String
}

struct StoredProject: Codable, Equatable, Sendable {
    let id: String
    let name: String
    let source: GitSourceConfiguration
    let environment: [String: String]
    var observedCommit: String?
    var currentReleaseId: String?
    var previousReleaseId: String?
    var desiredState: ProjectStatus
    var lastError: String?
    let createdAt: Date
    var updatedAt: Date
    var nextPollAt: Date
}

struct ReleaseRecord: Codable, Equatable, Sendable {
    let id: String
    let projectId: String
    let commit: String
    let directory: String
    let imageTag: String?
    let imageId: String?
    let manifest: DeploymentManifest?
    let status: ReleaseStatus
    let message: String?
    let createdAt: Date
}

struct DeploymentRecord: Codable, Equatable, Sendable {
    let id: String
    let projectId: String
    let releaseId: String?
    let action: DeploymentAction
    let status: DeploymentStatus
    let message: String?
    let startedAt: Date
    let finishedAt: Date?
}

struct ProjectSummary: ResponseCodable, Equatable, Sendable {
    let id: String
    let name: String
    let source: GitSourceConfiguration
    let environmentNames: [String]
    let observedCommit: String?
    let currentReleaseId: String?
    let previousReleaseId: String?
    let desiredState: ProjectStatus
    let runtimeState: ProjectStatus
    let lastError: String?
    let createdAt: Date
    let updatedAt: Date
}

struct ProjectDetails: ResponseCodable, Equatable, Sendable {
    let project: ProjectSummary
    let releases: [ReleaseRecord]
    let deployments: [DeploymentRecord]
}

struct OperationResponse: ResponseCodable, Equatable, Sendable {
    let projectId: String
    let action: String
    let status: String
    let releaseId: String?
    let commit: String?
    let message: String?
}

struct ProjectLogsResponse: ResponseCodable, Equatable, Sendable {
    let projectId: String
    let lines: Int
    let output: String
}
