import Foundation
import Logging
import ServiceLifecycle

struct ProjectRuntime: Sendable {
    let engine: DeploymentEngine
    let pollingService: ProjectPollingService

    init(configuration: ServiceConfiguration, logger: Logger) throws {
        let dataRoot = URL(fileURLWithPath: configuration.dataRoot, isDirectory: true)
        try FileManager.default.createDirectory(
            at: dataRoot,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700],
        )
        let credentials = dataRoot.appendingPathComponent("credentials", isDirectory: true)
        try FileManager.default.createDirectory(
            at: credentials,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700],
        )
        let temporaryDirectory = dataRoot.appendingPathComponent("tmp", isDirectory: true)
        let runner = try CommandRunner(temporaryDirectory: temporaryDirectory)
        let store = try ProjectStore(
            path: dataRoot.appendingPathComponent("project-deployer.sqlite").path,
        )
        let git = GitClient(
            executable: configuration.gitExecutable,
            dataRoot: dataRoot,
            runner: runner,
        )
        let docker = DockerClient(
            executable: configuration.dockerExecutable,
            dataRoot: dataRoot,
            runner: runner,
        )
        let engine = DeploymentEngine(
            store: store,
            git: git,
            docker: docker,
            logger: logger,
        )
        self.engine = engine
        pollingService = ProjectPollingService(
            engine: engine,
            sweepSeconds: configuration.pollSweepSeconds,
            logger: logger,
        )
    }
}

struct ProjectPollingService: Service {
    let engine: DeploymentEngine
    let sweepSeconds: Int
    let logger: Logger

    func run() async throws {
        try await cancelWhenGracefulShutdown {
            try await runPollingLoop()
        }
    }

    private func runPollingLoop() async throws {
        await engine.reconcileAll()
        while !Task.isCancelled {
            let projectIds = await engine.dueProjectIds()
            for projectId in projectIds {
                do {
                    _ = try await engine.sync(projectId: projectId, isBackground: true)
                } catch let error as APIError where error.code == "project_busy" {
                    continue
                } catch {
                    logger.error(
                        "Background project sync failed",
                        metadata: [
                            "project": "\(projectId)",
                            "error": "\(String(describing: error))",
                        ],
                    )
                }
            }
            do {
                try await Task.sleep(for: .seconds(sweepSeconds))
            } catch is CancellationError {
                return
            }
        }
    }
}
