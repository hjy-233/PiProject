import Foundation
import Logging

actor DeploymentEngine {
    let store: ProjectStore
    let git: GitClient
    let docker: DockerClient
    let healthChecker: HealthChecker
    let logger: Logger
    let releaseRetentionCount: Int
    let deploymentRetentionCount: Int
    let minimumFreeSpaceBytes: Int64
    var activeProjects: Set<String> = []

    init(
        store: ProjectStore,
        git: GitClient,
        docker: DockerClient,
        healthChecker: HealthChecker = HealthChecker(),
        logger: Logger,
        releaseRetentionCount: Int = 5,
        deploymentRetentionCount: Int = 100,
        minimumFreeSpaceMiB: Int = 512,
    ) {
        self.store = store
        self.git = git
        self.docker = docker
        self.healthChecker = healthChecker
        self.logger = logger
        self.releaseRetentionCount = releaseRetentionCount
        self.deploymentRetentionCount = deploymentRetentionCount
        minimumFreeSpaceBytes = Int64(minimumFreeSpaceMiB) * 1_048_576
    }
}
