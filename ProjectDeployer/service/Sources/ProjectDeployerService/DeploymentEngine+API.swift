import Foundation

extension DeploymentEngine {
    func createProject(_ request: CreateProjectRequest) async throws -> ProjectSummary {
        let input = try validatedProjectInput(request)
        let now = Date()
        let project = StoredProject(
            id: request.id,
            name: input.name,
            source: request.source,
            environment: input.environment,
            observedCommit: nil,
            currentReleaseId: nil,
            previousReleaseId: nil,
            desiredState: .stopped,
            lastError: nil,
            createdAt: now,
            updatedAt: now,
            nextPollAt: now,
        )
        try await store.createProject(project)
        return try await summary(project: project, runtimeState: .stopped)
    }

    func updateProject(projectId: String, request: UpdateProjectRequest) async throws -> ProjectSummary {
        try beginOperation(projectId: projectId)
        defer { activeProjects.remove(projectId) }
        let input = try validatedProjectInput(
            id: projectId,
            name: request.name,
            source: request.source,
            environment: request.environment,
        )
        var project = try await project(id: projectId)
        let sourceChanged = project.source != request.source
        project = StoredProject(
            id: project.id,
            name: input.name,
            source: request.source,
            environment: input.environment,
            observedCommit: sourceChanged ? nil : project.observedCommit,
            currentReleaseId: project.currentReleaseId,
            previousReleaseId: project.previousReleaseId,
            desiredState: project.desiredState,
            lastError: nil,
            createdAt: project.createdAt,
            updatedAt: Date(),
            nextPollAt: Date(),
        )
        try await store.saveProject(project)
        return try await summary(project: project)
    }

    func deleteProject(projectId: String, purgeVolumes: Bool) async throws -> DeleteProjectResponse {
        try beginOperation(projectId: projectId)
        defer { activeProjects.remove(projectId) }
        _ = try await project(id: projectId)
        let releases = await store.releases(projectId: projectId)
        try await docker.removeContainerIfPresent(projectId: projectId)
        let removedImages = try await docker.removeImages(releases.compactMap(\.imageTag))
        let removedVolumes = purgeVolumes ? try await docker.removeVolumes(projectId: projectId) : 0
        try git.removeProjectData(projectId: projectId)
        try await store.deleteProject(id: projectId)
        return DeleteProjectResponse(
            projectId: projectId,
            removedImages: removedImages,
            removedVolumes: removedVolumes,
            volumesPurged: purgeVolumes,
        )
    }

    func projects() async throws -> [ProjectSummary] {
        var summaries: [ProjectSummary] = []
        for project in await store.allProjects() {
            try await summaries.append(summary(project: project))
        }
        return summaries
    }

    func details(projectId: String) async throws -> ProjectDetails {
        let project = try await project(id: projectId)
        return try await ProjectDetails(
            project: summary(project: project),
            releases: store.releases(projectId: projectId),
            deployments: store.deployments(projectId: projectId),
        )
    }

    func sync(projectId: String, isBackground: Bool = false) async throws -> OperationResponse {
        try beginOperation(projectId: projectId)
        defer { activeProjects.remove(projectId) }
        do {
            try ensureFreeSpace()
            let response = try await performSync(projectId: projectId, retryFailed: !isBackground)
            try await pruneProjectHistory(projectId: projectId)
            return response
        } catch {
            await saveFailure(projectId: projectId, error: error)
            throw Self.operationError(error, code: "sync_failed")
        }
    }

    func deploy(projectId: String, releaseId: String) async throws -> OperationResponse {
        try beginOperation(projectId: projectId)
        defer { activeProjects.remove(projectId) }
        do {
            let project = try await project(id: projectId)
            guard let release = await store.release(id: releaseId, projectId: projectId) else {
                throw APIError(
                    status: .notFound,
                    code: "release_not_found",
                    message: "The requested release does not exist.",
                )
            }
            return try await deployRelease(project: project, release: release, action: .deploy)
        } catch {
            await saveFailure(projectId: projectId, error: error)
            throw Self.operationError(error, code: "deployment_failed")
        }
    }

    func start(projectId: String) async throws -> OperationResponse {
        try beginOperation(projectId: projectId)
        defer { activeProjects.remove(projectId) }
        do {
            return try await performStart(projectId: projectId)
        } catch {
            await saveFailure(projectId: projectId, error: error)
            throw Self.operationError(error, code: "start_failed")
        }
    }

    func stop(projectId: String) async throws -> OperationResponse {
        try beginOperation(projectId: projectId)
        defer { activeProjects.remove(projectId) }
        do {
            return try await performStop(projectId: projectId)
        } catch {
            await saveFailure(projectId: projectId, error: error)
            throw Self.operationError(error, code: "stop_failed")
        }
    }

    func restart(projectId: String) async throws -> OperationResponse {
        try beginOperation(projectId: projectId)
        defer { activeProjects.remove(projectId) }
        do {
            return try await performRestart(projectId: projectId)
        } catch {
            await saveFailure(projectId: projectId, error: error)
            throw Self.operationError(error, code: "restart_failed")
        }
    }

    func rollback(projectId: String) async throws -> OperationResponse {
        try beginOperation(projectId: projectId)
        defer { activeProjects.remove(projectId) }
        do {
            let project = try await project(id: projectId)
            guard let previousReleaseId = project.previousReleaseId,
                  let release = await store.release(id: previousReleaseId, projectId: projectId)
            else {
                throw APIError(
                    status: .conflict,
                    code: "no_previous_release",
                    message: "The project has no previous release.",
                )
            }
            return try await deployRelease(project: project, release: release, action: .rollback)
        } catch {
            await saveFailure(projectId: projectId, error: error)
            throw Self.operationError(error, code: "rollback_failed")
        }
    }

    func logs(projectId: String, lines: Int) async throws -> ProjectLogsResponse {
        _ = try await project(id: projectId)
        let boundedLines = min(max(lines, 1), 1000)
        return try await ProjectLogsResponse(
            projectId: projectId,
            lines: boundedLines,
            output: docker.logs(projectId: projectId, lines: boundedLines),
        )
    }

    func dueProjectIds(at date: Date = Date()) async -> [String] {
        await store.allProjects().filter { $0.nextPollAt <= date }.map(\.id)
    }

    func reconcileAll() async {
        do {
            try await store.failInterruptedDeployments(at: Date())
        } catch {
            logger.error("Unable to recover interrupted deployment records")
        }
        for storedProject in await store.allProjects() {
            guard !activeProjects.contains(storedProject.id) else { continue }
            do {
                let runtimeState = try await docker.runtimeState(projectId: storedProject.id)
                if storedProject.desiredState == .running, runtimeState != .running {
                    _ = try await start(projectId: storedProject.id)
                } else if storedProject.desiredState == .stopped, runtimeState == .running {
                    _ = try await stop(projectId: storedProject.id)
                }
            } catch {
                await saveFailure(projectId: storedProject.id, error: error)
            }
        }
    }

    private func validatedProjectInput(
        _ request: CreateProjectRequest,
    ) throws -> (name: String, environment: [String: String]) {
        try validatedProjectInput(
            id: request.id,
            name: request.name,
            source: request.source,
            environment: request.environment,
        )
    }

    private func validatedProjectInput(
        id: String,
        name: String,
        source: GitSourceConfiguration,
        environment requestedEnvironment: [String: String]?,
    ) throws -> (name: String, environment: [String: String]) {
        guard DeploymentManifest.isValidProjectID(id) else {
            throw APIError(
                status: .unprocessableContent,
                code: "invalid_project_id",
                message: "Project id must be a lowercase DNS label.",
            )
        }
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (1 ... 100).contains(normalizedName.count) else {
            throw APIError(
                status: .unprocessableContent,
                code: "invalid_project_name",
                message: "Project name must contain from 1 through 100 characters.",
            )
        }
        let sourceIssues = source.validationIssues()
        guard sourceIssues.isEmpty else {
            let codes = sourceIssues.map(\.code).joined(separator: ", ")
            throw APIError(
                status: .unprocessableContent,
                code: "invalid_git_source",
                message: "Git source validation failed: \(codes).",
            )
        }
        let environment = requestedEnvironment ?? [:]
        let namesAreValid = environment.keys.allSatisfy(DeploymentManifest.isValidEnvironmentName)
        let valuesAreValid = environment.values.allSatisfy {
            !$0.contains("\0") && !$0.contains("\n") && !$0.contains("\r")
        }
        guard namesAreValid, valuesAreValid else {
            throw APIError(
                status: .unprocessableContent,
                code: "invalid_environment",
                message: "Environment names or values are invalid.",
            )
        }
        return (normalizedName, environment)
    }

    private func performStart(projectId: String) async throws -> OperationResponse {
        var project = try await project(id: projectId)
        guard let currentReleaseId = project.currentReleaseId,
              let release = await store.release(id: currentReleaseId, projectId: projectId)
        else {
            throw APIError(
                status: .conflict,
                code: "no_current_release",
                message: "The project has no current release.",
            )
        }
        let deployment = try await beginDeployment(project: project, release: release, action: .start)
        do {
            if try await docker.runtimeState(projectId: projectId) == .stopped {
                do {
                    try await docker.start(projectId: projectId)
                } catch {
                    try await docker.runContainer(project: project, release: release)
                }
            }
            try await waitUntilHealthy(release: release)
            project.desiredState = .running
            try await saveSuccessfulOperation(project: project, deployment: deployment)
            return Self.operationResponse(project: project, action: "start", release: release)
        } catch {
            try await finishDeployment(deployment, status: .failed, message: Self.errorMessage(error))
            throw error
        }
    }

    private func performStop(projectId: String) async throws -> OperationResponse {
        var project = try await project(id: projectId)
        let release = await currentRelease(for: project)
        let deployment = try await beginDeployment(project: project, release: release, action: .stop)
        do {
            try await docker.stop(projectId: projectId)
            project.desiredState = .stopped
            try await saveSuccessfulOperation(project: project, deployment: deployment)
            return Self.operationResponse(project: project, action: "stop", release: release)
        } catch {
            try await finishDeployment(deployment, status: .failed, message: Self.errorMessage(error))
            throw error
        }
    }

    private func performRestart(projectId: String) async throws -> OperationResponse {
        var project = try await project(id: projectId)
        guard let release = await currentRelease(for: project) else {
            throw APIError(
                status: .conflict,
                code: "no_current_release",
                message: "The project has no current release.",
            )
        }
        let deployment = try await beginDeployment(project: project, release: release, action: .restart)
        do {
            try await docker.restart(projectId: projectId)
            try await waitUntilHealthy(release: release)
            project.desiredState = .running
            try await saveSuccessfulOperation(project: project, deployment: deployment)
            return Self.operationResponse(project: project, action: "restart", release: release)
        } catch {
            try await finishDeployment(deployment, status: .failed, message: Self.errorMessage(error))
            throw error
        }
    }

    private func saveSuccessfulOperation(
        project originalProject: StoredProject,
        deployment: DeploymentRecord,
    ) async throws {
        var project = originalProject
        project.lastError = nil
        project.updatedAt = Date()
        try await store.saveProject(project)
        try await finishDeployment(deployment, status: .succeeded, message: nil)
    }
}
