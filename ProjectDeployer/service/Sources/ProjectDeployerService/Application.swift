import Hummingbird
import Logging
import ServiceLifecycle

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
    runtime: ProjectRuntime? = nil,
    includeRuntimeServices: Bool = true,
) -> some ApplicationProtocol {
    var logger = Logger(label: "dev.dcstudio.project-deployer")
    logger.logLevel = configuration.logLevel

    let router = Router()
    router.add(middleware: APIErrorMiddleware())
    router.add(middleware: LogRequestsMiddleware(.info))
    addValidationRoutes(to: router)
    if let runtime {
        addProjectRoutes(to: router, runtime: runtime)
        addLifecycleRoutes(to: router, runtime: runtime)
    }
    let services: [any Service] = includeRuntimeServices ? runtime.map { [$0.pollingService] } ?? [] : []
    return Application(
        router: router,
        configuration: .init(
            address: .hostname(configuration.host, port: configuration.port),
        ),
        services: services,
        logger: logger,
    )
}

private func addValidationRoutes(to router: Router<BasicRequestContext>) {
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
}

private func addProjectRoutes(
    to router: Router<BasicRequestContext>,
    runtime: ProjectRuntime,
) {
    router.get("/api/v1/projects") { _, _ -> [ProjectSummary] in
        try await runtime.engine.projects()
    }

    router.post("/api/v1/projects") { request, context -> ProjectSummary in
        let project = try await request.decode(
            as: CreateProjectRequest.self,
            context: context,
        )
        return try await runtime.engine.createProject(project)
    }

    router.get("/api/v1/projects/:id") { _, context -> ProjectDetails in
        let projectId = try context.parameters.require("id")
        return try await runtime.engine.details(projectId: projectId)
    }

    router.post("/api/v1/projects/:id/sync") { _, context -> OperationResponse in
        let projectId = try context.parameters.require("id")
        return try await runtime.engine.sync(projectId: projectId)
    }

    router.post("/api/v1/projects/:id/deploy") { request, context -> OperationResponse in
        let projectId = try context.parameters.require("id")
        let deployment = try await request.decode(
            as: DeployProjectRequest.self,
            context: context,
        )
        return try await runtime.engine.deploy(
            projectId: projectId,
            releaseId: deployment.releaseId,
        )
    }
}

private func addLifecycleRoutes(
    to router: Router<BasicRequestContext>,
    runtime: ProjectRuntime,
) {
    router.post("/api/v1/projects/:id/start") { _, context -> OperationResponse in
        let projectId = try context.parameters.require("id")
        return try await runtime.engine.start(projectId: projectId)
    }

    router.post("/api/v1/projects/:id/stop") { _, context -> OperationResponse in
        let projectId = try context.parameters.require("id")
        return try await runtime.engine.stop(projectId: projectId)
    }

    router.post("/api/v1/projects/:id/restart") { _, context -> OperationResponse in
        let projectId = try context.parameters.require("id")
        return try await runtime.engine.restart(projectId: projectId)
    }

    router.post("/api/v1/projects/:id/rollback") { _, context -> OperationResponse in
        let projectId = try context.parameters.require("id")
        return try await runtime.engine.rollback(projectId: projectId)
    }

    router.get("/api/v1/projects/:id/logs") { request, context -> ProjectLogsResponse in
        let projectId = try context.parameters.require("id")
        let lines = request.uri.queryParameters.get("lines", as: Int.self) ?? 200
        return try await runtime.engine.logs(projectId: projectId, lines: lines)
    }
}
