import Foundation

extension GitClient {
    func inspect(
        projectId: String,
        source: GitSourceConfiguration,
    ) async throws -> GitSourceInspectionResponse {
        let references = try await remoteReferences(source: source)
        let branches = references.map(\.branch).sorted()
        guard let commit = references.first(where: { $0.branch == source.branch })?.commit else {
            throw GitError(detail: "The selected remote branch does not exist.")
        }
        let repository = try await inspectionRepository(source: source)
        defer {
            try? FileManager.default.removeItem(at: repository)
        }
        let result = try await runner.run(
            executable: executable,
            arguments: [
                "--git-dir", repository.path,
                "show", "FETCH_HEAD:\(source.manifestPath)",
            ],
        )
        return manifestInspection(
            result: result,
            projectId: projectId,
            branches: branches,
            commit: commit,
        )
    }

    func credentialIds() throws -> [String] {
        let directory = dataRoot.appendingPathComponent("credentials", isDirectory: true)
        let values = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
        )
        return try values.compactMap { url in
            let values = try url.resourceValues(forKeys: [.isRegularFileKey])
            return values.isRegularFile == true ? url.lastPathComponent : nil
        }.sorted()
    }

    private func remoteReferences(
        source: GitSourceConfiguration,
    ) async throws -> [(commit: String, branch: String)] {
        let result = try await runner.requireSuccess(
            executable: executable,
            arguments: ["ls-remote", "--heads", source.repositoryURL],
            environment: environment(for: source),
        )
        return result.standardOutput
            .split(whereSeparator: \Character.isNewline)
            .compactMap(Self.remoteReference)
    }

    private func inspectionRepository(source: GitSourceConfiguration) async throws -> URL {
        let repository = dataRoot
            .appendingPathComponent("tmp", isDirectory: true)
            .appendingPathComponent("source-inspection-\(UUID().uuidString.lowercased()).git", isDirectory: true)
        do {
            _ = try await runner.requireSuccess(
                executable: executable,
                arguments: ["init", "--bare", repository.path],
            )
            _ = try await runner.requireSuccess(
                executable: executable,
                arguments: [
                    "--git-dir", repository.path,
                    "fetch", "--depth=1", "--no-tags",
                    source.repositoryURL, "refs/heads/\(source.branch)",
                ],
                environment: environment(for: source),
            )
            return repository
        } catch {
            try? FileManager.default.removeItem(at: repository)
            throw error
        }
    }

    private func manifestInspection(
        result: CommandResult,
        projectId: String,
        branches: [String],
        commit: String,
    ) -> GitSourceInspectionResponse {
        guard result.succeeded else {
            return response(branches: branches, commit: commit, exists: false)
        }
        guard let data = result.standardOutput.data(using: .utf8), data.count <= 1_048_576 else {
            return response(
                branches: branches,
                commit: commit,
                issues: [.init(code: "manifest_size_invalid", field: "manifest")],
            )
        }
        guard let manifest = try? JSONDecoder().decode(DeploymentManifest.self, from: data) else {
            return response(
                branches: branches,
                commit: commit,
                issues: [.init(code: "manifest_json_invalid", field: "manifest")],
            )
        }
        var issues = manifest.validationIssues()
        if manifest.projectId != projectId {
            issues.append(.init(code: "manifest_project_mismatch", field: "projectId"))
        }
        return response(
            branches: branches,
            commit: commit,
            manifest: manifest,
            issues: issues,
        )
    }

    private func response(
        branches: [String],
        commit: String,
        exists: Bool = true,
        manifest: DeploymentManifest? = nil,
        issues: [ValidationIssue] = [],
    ) -> GitSourceInspectionResponse {
        GitSourceInspectionResponse(
            branches: branches,
            commit: commit,
            manifestExists: exists,
            manifestValid: manifest != nil && issues.isEmpty,
            manifest: manifest,
            issues: issues,
        )
    }

    private static func remoteReference(_ line: Substring) -> (commit: String, branch: String)? {
        let parts = line.split(whereSeparator: \Character.isWhitespace)
        guard parts.count == 2,
              isCommit(String(parts[0])),
              parts[1].hasPrefix("refs/heads/")
        else {
            return nil
        }
        return (String(parts[0]), String(parts[1].dropFirst("refs/heads/".count)))
    }
}
