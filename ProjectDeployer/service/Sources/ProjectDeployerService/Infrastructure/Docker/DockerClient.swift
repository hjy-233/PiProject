import Foundation

struct BuiltImage: Equatable, Sendable {
    let tag: String
    let id: String
}

struct DockerClient: Sendable {
    struct DockerError: Error, CustomStringConvertible, Sendable {
        let detail: String

        var description: String {
            detail
        }
    }

    let executable: String
    let dataRoot: URL
    let runner: CommandRunner

    func build(
        project: StoredProject,
        commit: String,
        releaseDirectory: URL,
        manifest: DeploymentManifest,
    ) async throws -> BuiltImage {
        let dockerfile = try repositoryURL(
            path: manifest.build.dockerfile,
            inside: releaseDirectory,
        )
        let context = try repositoryURL(
            path: manifest.build.context,
            inside: releaseDirectory,
        )
        let tag = "project-deployer/\(project.id):\(commit.prefix(12))"
        _ = try await runner.requireSuccess(
            executable: executable,
            arguments: [
                "build",
                "--platform",
                "linux/arm64",
                "--file",
                dockerfile.path,
                "--tag",
                tag,
                context.path,
            ],
            environment: environment,
        )
        let inspection = try await runner.requireSuccess(
            executable: executable,
            arguments: ["image", "inspect", "--format", "{{.Id}}", tag],
            environment: environment,
        )
        let imageId = inspection.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard imageId.hasPrefix("sha256:") else {
            throw DockerError(detail: "Docker did not return a valid image id.")
        }
        return BuiltImage(tag: tag, id: imageId)
    }

    func runContainer(
        project: StoredProject,
        release: ReleaseRecord,
    ) async throws {
        guard let manifest = release.manifest, let imageTag = release.imageTag else {
            throw DockerError(detail: "The release is not ready to run.")
        }
        try validateEnvironment(project: project, manifest: manifest)
        try writeEnvironmentFile(project: project, manifest: manifest)
        try await removeContainerIfPresent(projectId: project.id)

        var arguments = baseContainerArguments(project: project, release: release, manifest: manifest)

        if !manifest.environment.isEmpty {
            arguments.append(contentsOf: ["--env-file", environmentFileURL(projectId: project.id).path])
        }
        for port in manifest.ports {
            arguments.append(contentsOf: [
                "--publish",
                "\(port.host):\(port.container)/\(port.protocol.rawValue)",
            ])
        }
        for volume in manifest.volumes {
            let suffix = volume.readOnly ? ":ro" : ""
            arguments.append(contentsOf: [
                "--volume",
                "project-deployer-\(project.id)-\(volume.name):\(volume.containerPath)\(suffix)",
            ])
        }
        arguments.append(imageTag)
        arguments.append(contentsOf: manifest.command)
        _ = try await runner.requireSuccess(
            executable: executable,
            arguments: arguments,
            environment: environment,
        )
    }

    func start(projectId: String) async throws {
        _ = try await runner.requireSuccess(
            executable: executable,
            arguments: ["start", containerName(projectId: projectId)],
            environment: environment,
        )
    }

    func stop(projectId: String) async throws {
        let inspection = try await inspect(projectId: projectId)
        guard inspection != nil else {
            return
        }
        _ = try await runner.requireSuccess(
            executable: executable,
            arguments: ["stop", "--time", "10", containerName(projectId: projectId)],
            environment: environment,
        )
    }

    func restart(projectId: String) async throws {
        _ = try await runner.requireSuccess(
            executable: executable,
            arguments: ["restart", "--time", "10", containerName(projectId: projectId)],
            environment: environment,
        )
    }

    func removeContainerIfPresent(projectId: String) async throws {
        guard try await inspect(projectId: projectId) != nil else {
            return
        }
        _ = try await runner.requireSuccess(
            executable: executable,
            arguments: ["rm", "--force", containerName(projectId: projectId)],
            environment: environment,
        )
    }

    func runtimeState(projectId: String) async throws -> ProjectStatus {
        guard let value = try await inspect(projectId: projectId) else {
            return .stopped
        }
        let components = value.split(separator: "|", maxSplits: 1).map(String.init)
        if components.first == "true" {
            return .running
        }
        if components.count == 2, components[1] == "exited" {
            return .stopped
        }
        return .failed
    }

    func logs(projectId: String, lines: Int) async throws -> String {
        guard try await inspect(projectId: projectId) != nil else {
            throw DockerError(detail: "The project container does not exist.")
        }
        let result = try await runner.requireSuccess(
            executable: executable,
            arguments: ["logs", "--tail", String(lines), containerName(projectId: projectId)],
            environment: environment,
        )
        if result.standardError.isEmpty {
            return result.standardOutput
        }
        return result.standardOutput + result.standardError
    }

    private func inspect(projectId: String) async throws -> String? {
        let result = try await runner.run(
            executable: executable,
            arguments: [
                "container",
                "inspect",
                "--format",
                "{{.State.Running}}|{{.State.Status}}",
                containerName(projectId: projectId),
            ],
            environment: environment,
        )
        guard result.succeeded else {
            if Self.isMissingContainerError(result.standardError) {
                return nil
            }
            throw CommandError(
                command: "docker inspect",
                exitCode: result.exitCode,
                detail: result.standardError.trimmingCharacters(in: .whitespacesAndNewlines),
            )
        }
        return result.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func isMissingContainerError(_ value: String) -> Bool {
        value.contains("No such object") || value.contains("No such container")
    }

    private func validateEnvironment(
        project: StoredProject,
        manifest: DeploymentManifest,
    ) throws {
        let declarations = Dictionary(uniqueKeysWithValues: manifest.environment.map { ($0.name, $0) })
        let unknownNames = Set(project.environment.keys).subtracting(declarations.keys)
        guard unknownNames.isEmpty else {
            throw DockerError(detail: "Project environment contains variables not declared by the manifest.")
        }
        let missingNames = manifest.environment
            .filter { $0.required && project.environment[$0.name] == nil }
            .map(\.name)
        guard missingNames.isEmpty else {
            throw DockerError(
                detail: "Required environment values are missing: \(missingNames.joined(separator: ", ")).",
            )
        }
    }

    private func writeEnvironmentFile(
        project: StoredProject,
        manifest: DeploymentManifest,
    ) throws {
        let url = environmentFileURL(projectId: project.id)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true,
        )
        let names = Set(manifest.environment.map(\.name))
        let contents = project.environment
            .filter { names.contains($0.key) }
            .sorted { $0.key < $1.key }
            .map { key, value in
                "\(key)=\(Self.environmentValue(value))"
            }
            .joined(separator: "\n")
        try Data((contents + "\n").utf8).write(to: url, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }

    private func environmentFileURL(projectId: String) -> URL {
        dataRoot
            .appendingPathComponent("projects", isDirectory: true)
            .appendingPathComponent(projectId, isDirectory: true)
            .appendingPathComponent("environment", isDirectory: false)
    }

    var environment: [String: String] {
        ["DOCKER_CONFIG": dataRoot.appendingPathComponent("docker-config", isDirectory: true).path]
    }

    private func baseContainerArguments(
        project: StoredProject,
        release: ReleaseRecord,
        manifest: DeploymentManifest,
    ) -> [String] {
        [
            "run", "--detach",
            "--name", containerName(projectId: project.id),
            "--label", "dev.dcstudio.project-deployer.managed=true",
            "--label", "dev.dcstudio.project-deployer.project=\(project.id)",
            "--label", "dev.dcstudio.project-deployer.release=\(release.id)",
            "--restart", manifest.restartPolicy.rawValue,
            "--log-opt", "max-size=10m",
            "--log-opt", "max-file=3",
            "--memory", "\(manifest.resources.memoryMiB)m",
            "--cpus", Self.cpuLimit(percent: manifest.resources.cpuPercent),
        ]
    }

    private func repositoryURL(path: String, inside releaseDirectory: URL) throws -> URL {
        let candidate = path == "."
            ? releaseDirectory.standardizedFileURL
            : releaseDirectory.appendingPathComponent(path).standardizedFileURL
        let root = releaseDirectory.standardizedFileURL.path
        guard candidate.path == root || candidate.path.hasPrefix(root + "/") else {
            throw DockerError(detail: "A build path escaped the release directory.")
        }
        return candidate
    }

    private func containerName(projectId: String) -> String {
        "project-deployer-\(projectId)"
    }

    private static func cpuLimit(percent: Int) -> String {
        String(
            format: "%.2f",
            locale: Locale(identifier: "en_US_POSIX"),
            Double(percent) / 100,
        )
    }

    private static func environmentValue(_ value: String) -> String {
        value
    }
}
