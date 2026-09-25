import Foundation

extension DockerClient {
    func removeImages(_ imageTags: [String]) async throws -> Int {
        var removed = 0
        for imageTag in Set(imageTags) {
            let result = try await runner.run(
                executable: executable,
                arguments: ["image", "rm", imageTag],
                environment: environment,
            )
            if result.succeeded {
                removed += 1
            } else if !result.standardError.contains("No such image") {
                throw CommandError(
                    command: "docker image rm",
                    exitCode: result.exitCode,
                    detail: result.standardError.trimmingCharacters(in: .whitespacesAndNewlines),
                )
            }
        }
        return removed
    }

    func removeVolumes(projectId: String) async throws -> Int {
        let result = try await runner.requireSuccess(
            executable: executable,
            arguments: [
                "volume",
                "ls",
                "--quiet",
                "--filter",
                "name=project-deployer-\(projectId)-",
            ],
            environment: environment,
        )
        let names = result.standardOutput.split(whereSeparator: \Character.isNewline).map(String.init)
        guard !names.isEmpty else {
            return 0
        }
        _ = try await runner.requireSuccess(
            executable: executable,
            arguments: ["volume", "rm"] + names,
            environment: environment,
        )
        return names.count
    }
}
