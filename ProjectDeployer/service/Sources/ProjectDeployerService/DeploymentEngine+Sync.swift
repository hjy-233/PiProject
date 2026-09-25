import Foundation

extension DeploymentEngine {
    func performSync(
        projectId: String,
        retryFailed: Bool,
    ) async throws -> OperationResponse {
        var project = try await project(id: projectId)
        project.lastError = nil
        project.updatedAt = Date()
        try await store.saveProject(project)

        let commit = try await git.remoteCommit(for: project)
        if let unchanged = await unchangedRelease(project: project, commit: commit, retryFailed: retryFailed) {
            scheduleNextPoll(project: &project)
            try await store.saveProject(project)
            return OperationResponse(
                projectId: projectId,
                action: "sync",
                status: "unchanged",
                releaseId: unchanged.id,
                commit: commit,
                message: nil,
            )
        }

        try await git.fetch(commit: commit, for: project)
        let shouldBuild = try await shouldBuild(project: project, commit: commit)
        project.observedCommit = commit
        scheduleNextPoll(project: &project)
        try await store.saveProject(project)
        guard shouldBuild else {
            return try await recordSkippedRelease(project: project, commit: commit)
        }
        return try await buildRelease(project: project, commit: commit)
    }

    func deployRelease(
        project originalProject: StoredProject,
        release: ReleaseRecord,
        action: DeploymentAction,
    ) async throws -> OperationResponse {
        guard release.status == .ready || release.status == .running else {
            throw APIError(
                status: .conflict,
                code: "release_not_ready",
                message: "Only a ready release can be deployed.",
            )
        }
        var project = originalProject
        let oldRelease = await currentRelease(for: project)
        let deployment = try await beginDeployment(project: project, release: release, action: action)
        do {
            try await docker.runContainer(project: project, release: release)
            try await waitUntilHealthy(release: release)
            if let oldRelease, oldRelease.id != release.id {
                try await store.saveRelease(oldRelease.updating(status: .ready, message: nil))
            }
            try await store.saveRelease(release.updating(status: .running, message: nil))
            project.previousReleaseId = project.currentReleaseId == release.id
                ? project.previousReleaseId
                : project.currentReleaseId
            project.currentReleaseId = release.id
            project.desiredState = .running
            project.lastError = nil
            project.updatedAt = Date()
            try await store.saveProject(project)
            try await finishDeployment(deployment, status: .succeeded, message: nil)
            return Self.operationResponse(project: project, action: action.rawValue, release: release)
        } catch {
            throw await recoverFailedDeployment(
                project: project,
                failedRelease: release,
                oldRelease: oldRelease,
                deployment: deployment,
                error: error,
            )
        }
    }

    private func unchangedRelease(
        project: StoredProject,
        commit: String,
        retryFailed: Bool,
    ) async -> ReleaseRecord? {
        guard project.observedCommit == commit,
              let existing = await store.release(commit: commit, projectId: project.id),
              !retryFailed || existing.status != .failed
        else {
            return nil
        }
        return existing
    }

    private func recordSkippedRelease(
        project: StoredProject,
        commit: String,
    ) async throws -> OperationResponse {
        let release = ReleaseRecord(
            id: UUID().uuidString.lowercased(),
            projectId: project.id,
            commit: commit,
            directory: "",
            imageTag: nil,
            imageId: nil,
            manifest: nil,
            status: .skipped,
            message: "Changed paths did not match the deployment trigger.",
            createdAt: Date(),
        )
        try await store.saveRelease(release)
        return Self.operationResponse(project: project, action: "sync", release: release)
    }

    private func buildRelease(
        project: StoredProject,
        commit: String,
    ) async throws -> OperationResponse {
        let releaseId = UUID().uuidString.lowercased()
        let releaseDirectory = try await git.checkout(commit: commit, projectId: project.id)
        let release: ReleaseRecord
        do {
            let manifest = try loadManifest(project: project, releaseDirectory: releaseDirectory)
            let image = try await docker.build(
                project: project,
                commit: commit,
                releaseDirectory: releaseDirectory,
                manifest: manifest,
            )
            release = ReleaseRecord(
                id: releaseId,
                projectId: project.id,
                commit: commit,
                directory: releaseDirectory.path,
                imageTag: image.tag,
                imageId: image.id,
                manifest: manifest,
                status: .ready,
                message: nil,
                createdAt: Date(),
            )
            try await store.saveRelease(release)
        } catch {
            await saveFailedRelease(
                id: releaseId,
                project: project,
                commit: commit,
                directory: releaseDirectory,
                error: error,
            )
            throw error
        }
        if project.source.trigger.mode == .automatic {
            return try await deployRelease(project: project, release: release, action: .deploy)
        }
        return Self.operationResponse(project: project, action: "sync", release: release)
    }

    private func saveFailedRelease(
        id: String,
        project: StoredProject,
        commit: String,
        directory: URL,
        error: Error,
    ) async {
        try? await store.saveRelease(
            ReleaseRecord(
                id: id,
                projectId: project.id,
                commit: commit,
                directory: directory.path,
                imageTag: nil,
                imageId: nil,
                manifest: nil,
                status: .failed,
                message: Self.errorMessage(error),
                createdAt: Date(),
            ),
        )
    }

    private func recoverFailedDeployment(
        project originalProject: StoredProject,
        failedRelease: ReleaseRecord,
        oldRelease: ReleaseRecord?,
        deployment: DeploymentRecord,
        error: Error,
    ) async -> APIError {
        var project = originalProject
        try? await docker.removeContainerIfPresent(projectId: project.id)
        try? await store.saveRelease(
            failedRelease.updating(status: .failed, message: Self.errorMessage(error)),
        )
        let rollbackMessage = await restoreOldRelease(
            oldRelease,
            excludingReleaseId: failedRelease.id,
            project: &project,
        )
        let message = [Self.errorMessage(error), rollbackMessage]
            .compactMap(\.self)
            .joined(separator: " ")
        project.lastError = message
        project.updatedAt = Date()
        try? await store.saveProject(project)
        try? await finishDeployment(deployment, status: .failed, message: message)
        return APIError(status: .internalServerError, code: "deployment_failed", message: message)
    }

    private func restoreOldRelease(
        _ oldRelease: ReleaseRecord?,
        excludingReleaseId: String,
        project: inout StoredProject,
    ) async -> String? {
        guard let oldRelease, oldRelease.id != excludingReleaseId else {
            project.desiredState = .stopped
            return nil
        }
        do {
            try await docker.runContainer(project: project, release: oldRelease)
            try await waitUntilHealthy(release: oldRelease)
            project.desiredState = .running
            return "Previous release was restored."
        } catch {
            project.desiredState = .stopped
            return "Previous release restoration failed: \(Self.errorMessage(error))"
        }
    }

    private func shouldBuild(project: StoredProject, commit: String) async throws -> Bool {
        guard let currentReleaseId = project.currentReleaseId,
              let current = await store.release(id: currentReleaseId, projectId: project.id)
        else {
            return true
        }
        let changedPaths = try await git.changedPaths(
            projectId: project.id,
            from: current.commit,
            to: commit,
        )
        if changedPaths.contains(project.source.manifestPath) {
            return true
        }
        let remainingPaths = changedPaths.filter { path in
            !project.source.trigger.excludePaths.contains { Self.matches(path: path, pattern: $0) }
        }
        if project.source.trigger.includePaths.isEmpty {
            return !remainingPaths.isEmpty
        }
        return remainingPaths.contains { path in
            project.source.trigger.includePaths.contains { Self.matches(path: path, pattern: $0) }
        }
    }

    private func loadManifest(
        project: StoredProject,
        releaseDirectory: URL,
    ) throws -> DeploymentManifest {
        let manifestURL = releaseDirectory
            .appendingPathComponent(project.source.manifestPath)
            .standardizedFileURL
        let root = releaseDirectory.standardizedFileURL.path
        guard manifestURL.path.hasPrefix(root + "/"),
              FileManager.default.fileExists(atPath: manifestURL.path)
        else {
            throw APIError(
                status: .unprocessableContent,
                code: "manifest_missing",
                message: "The deployment manifest does not exist in the release.",
            )
        }
        let attributes = try FileManager.default.attributesOfItem(atPath: manifestURL.path)
        let size = (attributes[.size] as? NSNumber)?.intValue ?? 0
        guard (1 ... 1_048_576).contains(size) else {
            throw APIError(
                status: .unprocessableContent,
                code: "manifest_size_invalid",
                message: "The deployment manifest must not exceed 1 MiB.",
            )
        }
        let manifest = try JSONDecoder().decode(
            DeploymentManifest.self,
            from: Data(contentsOf: manifestURL),
        )
        guard manifest.validationIssues().isEmpty, manifest.projectId == project.id else {
            throw APIError(
                status: .unprocessableContent,
                code: "manifest_invalid",
                message: "The deployment manifest is invalid or belongs to another project.",
            )
        }
        return manifest
    }
}
