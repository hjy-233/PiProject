import Foundation
import Logging

actor DeploymentEngine {
    let store: ProjectStore
    let git: GitClient
    let docker: DockerClient
    let healthChecker: HealthChecker
    let logger: Logger
    var activeProjects: Set<String> = []

    init(
        store: ProjectStore,
        git: GitClient,
        docker: DockerClient,
        healthChecker: HealthChecker = HealthChecker(),
        logger: Logger,
    ) {
        self.store = store
        self.git = git
        self.docker = docker
        self.healthChecker = healthChecker
        self.logger = logger
    }
}
