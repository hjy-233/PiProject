import Foundation
import Hummingbird
import HummingbirdTesting
import Logging
@testable import ProjectDeployerService
import Testing

@Suite("Project runtime", .serialized)
struct ProjectRuntimeTests {
    @Test("project creation is persisted and duplicate ids are rejected")
    func projectCreationAndPersistence() async throws {
        let dataRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: dataRoot)
        }
        let configuration = try ServiceConfiguration(environment: [
            "PROJECT_DEPLOYER_DATA_ROOT": dataRoot.path,
            "PROJECT_DEPLOYER_DOCKER_EXECUTABLE": "/usr/bin/false",
        ])
        let request = CreateProjectRequest(
            id: "hello-service",
            name: "Hello Service",
            source: .validFixture,
            environment: ["APP_TOKEN": "secret"],
        )
        let requestBody = try JSONEncoder().encode(request)
        try await testProjectAPI(configuration: configuration, requestBody: requestBody)

        let reopenedStore = try ProjectStore(
            path: dataRoot.appendingPathComponent("project-deployer.sqlite").path,
        )
        let persistedProject = await reopenedStore.project(id: "hello-service")
        #expect(persistedProject?.name == "Hello Service")
        #expect(persistedProject?.environment == ["APP_TOKEN": "secret"])
    }

    private func testProjectAPI(
        configuration: ServiceConfiguration,
        requestBody: Data,
    ) async throws {
        let runtime = try ProjectRuntime(
            configuration: configuration,
            logger: Logger(label: "project-deployer-tests"),
        )
        let application = buildApplication(
            configuration: configuration,
            runtime: runtime,
            includeRuntimeServices: false,
        )
        try await application.test(.router) { client in
            try await client.execute(
                uri: "/api/v1/projects",
                method: .post,
                headers: [.contentType: "application/json"],
                body: .init(data: requestBody),
            ) { response in
                #expect(response.status == .ok)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let project = try decoder.decode(ProjectSummary.self, from: response.body)
                #expect(project.id == "hello-service")
                #expect(project.environmentNames == ["APP_TOKEN"])
                #expect(project.desiredState == .stopped)
                #expect(project.runtimeState == .stopped)
            }

            try await client.execute(
                uri: "/api/v1/projects",
                method: .post,
                headers: [.contentType: "application/json"],
                body: .init(data: requestBody),
            ) { response in
                #expect(response.status == .conflict)
                let error = try JSONDecoder().decode(APIErrorEnvelope.self, from: response.body)
                #expect(error.error.code == "project_exists")
            }
        }
    }
}
