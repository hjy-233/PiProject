import Hummingbird
import Logging

struct HealthResponse: ResponseCodable, Equatable, Sendable {
    let status: String
    let service: String
    let apiVersion: String
}

struct ManifestValidationResponse: ResponseCodable, Equatable, Sendable {
    let valid: Bool
    let issues: [ValidationIssue]

    init(issues: [ValidationIssue]) {
        valid = issues.isEmpty
        self.issues = issues
    }
}

struct GitSourceValidationResponse: ResponseCodable, Equatable, Sendable {
    let valid: Bool
    let issues: [ValidationIssue]

    init(issues: [ValidationIssue]) {
        valid = issues.isEmpty
        self.issues = issues
    }
}

func buildApplication(
    configuration: ServiceConfiguration,
) -> some ApplicationProtocol {
    var logger = Logger(label: "dev.dcstudio.project-deployer")
    logger.logLevel = configuration.logLevel

    let router = Router()
    router.add(middleware: APIErrorMiddleware())
    router.add(middleware: LogRequestsMiddleware(.info))

    router.get("/health") { _, _ -> HealthResponse in
        HealthResponse(
            status: "ok",
            service: "project-deployer",
            apiVersion: "v1",
        )
    }

    router.post("/api/v1/manifests/validate") { request, context -> ManifestValidationResponse in
        let manifest = try await request.decode(
            as: DeploymentManifest.self,
            context: context,
        )
        return ManifestValidationResponse(issues: manifest.validationIssues())
    }

    router.post("/api/v1/sources/git/validate") { request, context -> GitSourceValidationResponse in
        let source = try await request.decode(
            as: GitSourceConfiguration.self,
            context: context,
        )
        return GitSourceValidationResponse(issues: source.validationIssues())
    }

    return Application(
        router: router,
        configuration: .init(
            address: .hostname(configuration.host, port: configuration.port),
        ),
        logger: logger,
    )
}
