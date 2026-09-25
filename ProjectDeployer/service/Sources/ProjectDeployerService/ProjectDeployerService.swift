import Hummingbird
import Logging

@main
struct ProjectDeployerService {
    static func main() async throws {
        let configuration = try ServiceConfiguration()
        var logger = Logger(label: "dev.dcstudio.project-deployer")
        logger.logLevel = configuration.logLevel
        let runtime = try ProjectRuntime(configuration: configuration, logger: logger)
        let application = buildApplication(configuration: configuration, runtime: runtime)
        try await application.runService()
    }
}
