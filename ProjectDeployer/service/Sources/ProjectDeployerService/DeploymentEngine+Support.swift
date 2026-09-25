import Foundation

extension DeploymentEngine {
    func waitUntilHealthy(release: ReleaseRecord) async throws {
        guard let manifest = release.manifest, let healthCheck = manifest.healthCheck else {
            return
        }
        guard let hostPort = manifest.ports.first(where: {
            $0.container == healthCheck.port && $0.protocol == .tcp
        })?.host else {
            throw APIError(
                status: .unprocessableContent,
                code: "health_port_missing",
                message: "The health check port is not published as TCP.",
            )
        }
        if healthCheck.startPeriodSeconds > 0 {
            try await Task.sleep(for: .seconds(healthCheck.startPeriodSeconds))
        }
        for attempt in 1 ... healthCheck.retries {
            if await healthChecker.check(healthCheck, hostPort: hostPort) {
                return
            }
            if attempt < healthCheck.retries {
                try await Task.sleep(for: .seconds(1))
            }
        }
        throw APIError(
            status: .internalServerError,
            code: "health_check_failed",
            message: "The release failed its health check.",
        )
    }

    func summary(
        project: StoredProject,
        runtimeState: ProjectStatus? = nil,
    ) async throws -> ProjectSummary {
        let resolvedRuntimeState: ProjectStatus = if let runtimeState {
            runtimeState
        } else {
            try await docker.runtimeState(projectId: project.id)
        }
        return ProjectSummary(
            id: project.id,
            name: project.name,
            source: project.source,
            environmentNames: project.environment.keys.sorted(),
            observedCommit: project.observedCommit,
            currentReleaseId: project.currentReleaseId,
            previousReleaseId: project.previousReleaseId,
            desiredState: project.desiredState,
            runtimeState: resolvedRuntimeState,
            lastError: project.lastError,
            createdAt: project.createdAt,
            updatedAt: project.updatedAt,
        )
    }

    func project(id: String) async throws -> StoredProject {
        guard let project = await store.project(id: id) else {
            throw APIError(
                status: .notFound,
                code: "project_not_found",
                message: "The requested project does not exist.",
            )
        }
        return project
    }

    func currentRelease(for project: StoredProject) async -> ReleaseRecord? {
        guard let id = project.currentReleaseId else {
            return nil
        }
        return await store.release(id: id, projectId: project.id)
    }

    func beginOperation(projectId: String) throws {
        guard activeProjects.insert(projectId).inserted else {
            throw APIError(
                status: .conflict,
                code: "project_busy",
                message: "Another operation is already running for this project.",
            )
        }
    }

    func beginDeployment(
        project: StoredProject,
        release: ReleaseRecord?,
        action: DeploymentAction,
    ) async throws -> DeploymentRecord {
        let deployment = DeploymentRecord(
            id: UUID().uuidString.lowercased(),
            projectId: project.id,
            releaseId: release?.id,
            action: action,
            status: .running,
            message: nil,
            startedAt: Date(),
            finishedAt: nil,
        )
        try await store.saveDeployment(deployment)
        return deployment
    }

    func finishDeployment(
        _ deployment: DeploymentRecord,
        status: DeploymentStatus,
        message: String?,
    ) async throws {
        try await store.saveDeployment(
            DeploymentRecord(
                id: deployment.id,
                projectId: deployment.projectId,
                releaseId: deployment.releaseId,
                action: deployment.action,
                status: status,
                message: message,
                startedAt: deployment.startedAt,
                finishedAt: Date(),
            ),
        )
    }

    func scheduleNextPoll(project: inout StoredProject) {
        project.nextPollAt = Date().addingTimeInterval(TimeInterval(project.source.pollIntervalSeconds))
        project.updatedAt = Date()
    }

    func saveFailure(projectId: String, error: Error) async {
        guard var project = await store.project(id: projectId) else {
            return
        }
        project.lastError = Self.errorMessage(error)
        project.nextPollAt = Date().addingTimeInterval(TimeInterval(project.source.pollIntervalSeconds))
        project.updatedAt = Date()
        do {
            try await store.saveProject(project)
        } catch {
            logger.error("Unable to persist project failure", metadata: ["project": "\(projectId)"])
        }
    }

    static func operationResponse(
        project: StoredProject,
        action: String,
        release: ReleaseRecord?,
    ) -> OperationResponse {
        let status: String = switch action {
        case "sync":
            release?.status.rawValue ?? project.desiredState.rawValue
        case "stop":
            ProjectStatus.stopped.rawValue
        default:
            project.desiredState.rawValue
        }
        return OperationResponse(
            projectId: project.id,
            action: action,
            status: status,
            releaseId: release?.id,
            commit: release?.commit,
            message: release?.message,
        )
    }

    static func operationError(_ error: Error, code: String) -> Error {
        if error is APIError {
            return error
        }
        return APIError(
            status: .internalServerError,
            code: code,
            message: String(describing: error),
        )
    }

    static func errorMessage(_ error: Error) -> String {
        if let error = error as? APIError {
            return error.message
        }
        return String(describing: error)
    }

    static func matches(path: String, pattern: String) -> Bool {
        var expression = "^"
        var index = pattern.startIndex
        while index < pattern.endIndex {
            let character = pattern[index]
            if character == "*" {
                let next = pattern.index(after: index)
                if next < pattern.endIndex, pattern[next] == "*" {
                    expression += ".*"
                    index = pattern.index(after: next)
                } else {
                    expression += "[^/]*"
                    index = next
                }
            } else if character == "?" {
                expression += "[^/]"
                index = pattern.index(after: index)
            } else {
                expression += NSRegularExpression.escapedPattern(for: String(character))
                index = pattern.index(after: index)
            }
        }
        expression += "$"
        return path.range(of: expression, options: .regularExpression) != nil
    }
}

extension ReleaseRecord {
    func updating(status: ReleaseStatus, message: String?) -> ReleaseRecord {
        ReleaseRecord(
            id: id,
            projectId: projectId,
            commit: commit,
            directory: directory,
            imageTag: imageTag,
            imageId: imageId,
            manifest: manifest,
            status: status,
            message: message,
            createdAt: createdAt,
        )
    }
}
