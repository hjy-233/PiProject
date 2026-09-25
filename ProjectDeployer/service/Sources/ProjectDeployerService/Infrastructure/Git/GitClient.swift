import Foundation

struct GitClient: Sendable {
    struct GitError: Error, CustomStringConvertible, Sendable {
        let detail: String

        var description: String {
            detail
        }
    }

    let executable: String
    let dataRoot: URL
    let runner: CommandRunner

    func remoteCommit(for project: StoredProject) async throws -> String {
        let reference = "refs/heads/\(project.source.branch)"
        let result = try await runner.requireSuccess(
            executable: executable,
            arguments: [
                "ls-remote",
                "--exit-code",
                project.source.repositoryURL,
                reference,
            ],
            environment: environment(for: project.source),
        )
        guard let line = result.standardOutput.split(whereSeparator: \Character.isNewline).first,
              let commit = line.split(whereSeparator: \Character.isWhitespace).first.map(String.init),
              Self.isCommit(commit)
        else {
            throw GitError(detail: "The remote branch did not return a valid commit SHA.")
        }
        return commit
    }

    func fetch(commit: String, for project: StoredProject) async throws {
        let mirror = mirrorURL(projectId: project.id)
        try FileManager.default.createDirectory(
            at: mirror.deletingLastPathComponent(),
            withIntermediateDirectories: true,
        )
        if !FileManager.default.fileExists(atPath: mirror.path) {
            _ = try await runner.requireSuccess(
                executable: executable,
                arguments: ["init", "--bare", mirror.path],
            )
            _ = try await runner.requireSuccess(
                executable: executable,
                arguments: ["--git-dir", mirror.path, "remote", "add", "origin", project.source.repositoryURL],
            )
        } else {
            _ = try await runner.requireSuccess(
                executable: executable,
                arguments: ["--git-dir", mirror.path, "remote", "set-url", "origin", project.source.repositoryURL],
            )
        }

        let remoteReference = "refs/remotes/origin/\(project.source.branch)"
        let refspec = "+refs/heads/\(project.source.branch):\(remoteReference)"
        _ = try await runner.requireSuccess(
            executable: executable,
            arguments: [
                "--git-dir",
                mirror.path,
                "fetch",
                "--no-tags",
                "--prune",
                "origin",
                refspec,
            ],
            environment: environment(for: project.source),
        )
        let resolved = try await runner.requireSuccess(
            executable: executable,
            arguments: ["--git-dir", mirror.path, "rev-parse", "\(remoteReference)^{commit}"],
        )
        guard resolved.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines) == commit else {
            throw GitError(detail: "The fetched commit did not match the observed remote commit.")
        }
    }

    func changedPaths(
        projectId: String,
        from previousCommit: String,
        to commit: String,
    ) async throws -> [String] {
        let result = try await runner.requireSuccess(
            executable: executable,
            arguments: [
                "--git-dir",
                mirrorURL(projectId: projectId).path,
                "diff",
                "--name-only",
                previousCommit,
                commit,
                "--",
            ],
        )
        return result.standardOutput
            .split(whereSeparator: \Character.isNewline)
            .map(String.init)
    }

    func checkout(commit: String, projectId: String) async throws -> URL {
        let release = releaseURL(projectId: projectId, commit: commit)
        if FileManager.default.fileExists(atPath: release.path) {
            return release
        }
        try FileManager.default.createDirectory(
            at: release.deletingLastPathComponent(),
            withIntermediateDirectories: true,
        )
        let mirror = mirrorURL(projectId: projectId)
        _ = try await runner.requireSuccess(
            executable: executable,
            arguments: ["--git-dir", mirror.path, "worktree", "prune"],
        )
        do {
            _ = try await runner.requireSuccess(
                executable: executable,
                arguments: [
                    "--git-dir",
                    mirror.path,
                    "worktree",
                    "add",
                    "--detach",
                    release.path,
                    commit,
                ],
            )
        } catch {
            if FileManager.default.fileExists(atPath: release.path) {
                try? FileManager.default.removeItem(at: release)
            }
            throw error
        }
        return release
    }

    func removeProjectData(projectId: String) throws {
        let mirror = mirrorURL(projectId: projectId)
        let project = dataRoot
            .appendingPathComponent("projects", isDirectory: true)
            .appendingPathComponent(projectId, isDirectory: true)
        if FileManager.default.fileExists(atPath: mirror.path) {
            try FileManager.default.removeItem(at: mirror)
        }
        if FileManager.default.fileExists(atPath: project.path) {
            try FileManager.default.removeItem(at: project)
        }
    }

    func removeReleaseDirectory(_ release: ReleaseRecord) throws {
        guard !release.directory.isEmpty else {
            return
        }
        let candidate = URL(fileURLWithPath: release.directory).standardizedFileURL
        let releasesRoot = dataRoot
            .appendingPathComponent("projects", isDirectory: true)
            .appendingPathComponent(release.projectId, isDirectory: true)
            .appendingPathComponent("releases", isDirectory: true)
            .standardizedFileURL
        guard candidate.path.hasPrefix(releasesRoot.path + "/") else {
            throw GitError(detail: "Refusing to remove a release outside the project data directory.")
        }
        if FileManager.default.fileExists(atPath: candidate.path) {
            try FileManager.default.removeItem(at: candidate)
        }
    }

    private func mirrorURL(projectId: String) -> URL {
        dataRoot
            .appendingPathComponent("repositories", isDirectory: true)
            .appendingPathComponent("\(projectId).git", isDirectory: true)
    }

    private func releaseURL(projectId: String, commit: String) -> URL {
        dataRoot
            .appendingPathComponent("projects", isDirectory: true)
            .appendingPathComponent(projectId, isDirectory: true)
            .appendingPathComponent("releases", isDirectory: true)
            .appendingPathComponent(commit, isDirectory: true)
    }

    func environment(for source: GitSourceConfiguration) throws -> [String: String] {
        var values = [
            "GIT_TERMINAL_PROMPT": "0",
            "GIT_OPTIONAL_LOCKS": "0",
        ]
        guard URLComponents(string: source.repositoryURL)?.scheme?.lowercased() == "ssh" else {
            if source.credentialId != nil {
                throw GitError(detail: "HTTPS credentials are not supported by this version.")
            }
            return values
        }

        if let credentialId = source.credentialId {
            let key = dataRoot
                .appendingPathComponent("credentials", isDirectory: true)
                .appendingPathComponent(credentialId)
            let knownHosts = dataRoot.appendingPathComponent("known_hosts")
            guard FileManager.default.fileExists(atPath: key.path),
                  FileManager.default.fileExists(atPath: knownHosts.path)
            else {
                throw GitError(
                    detail: "The SSH credential or ProjectDeployer known_hosts file is missing.",
                )
            }
            values["GIT_SSH_COMMAND"] = [
                "/usr/bin/ssh",
                "-F /dev/null",
                "-i \(Self.shellQuoted(key.path))",
                "-o BatchMode=yes",
                "-o IdentitiesOnly=yes",
                "-o StrictHostKeyChecking=yes",
                "-o UserKnownHostsFile=\(Self.shellQuoted(knownHosts.path))",
            ].joined(separator: " ")
        } else {
            values["GIT_SSH_COMMAND"] = "/usr/bin/ssh -F /dev/null -o BatchMode=yes"
        }
        return values
    }

    static func isCommit(_ value: String) -> Bool {
        (40 ... 64).contains(value.count) && value.unicodeScalars.allSatisfy { scalar in
            (48 ... 57).contains(scalar.value) || (97 ... 102).contains(scalar.value)
        }
    }

    private static func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}
