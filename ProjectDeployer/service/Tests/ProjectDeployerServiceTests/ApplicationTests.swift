import Foundation
import Hummingbird
import HummingbirdTesting
@testable import ProjectDeployerService
import Testing

@Suite("Application")
struct ApplicationTests {
    @Test("health endpoint returns service identity")
    func health() async throws {
        let application = try buildApplication(configuration: ServiceConfiguration(environment: [:]))

        try await application.test(.router) { client in
            try await client.execute(uri: "/health", method: .get) { response in
                #expect(response.status == .ok)
                let health = try JSONDecoder().decode(HealthResponse.self, from: response.body)
                #expect(health.status == "ok")
                #expect(health.service == "project-deployer")
                #expect(health.apiVersion == "v1")
            }
        }
    }

    @Test("manifest validation endpoint accepts a valid manifest")
    func manifestValidation() async throws {
        let application = try buildApplication(configuration: ServiceConfiguration(environment: [:]))
        let body = try JSONEncoder().encode(DeploymentManifest.validFixture)

        try await application.test(.router) { client in
            try await client.execute(
                uri: "/api/v1/manifests/validate",
                method: .post,
                headers: [.contentType: "application/json"],
                body: .init(data: body),
            ) { response in
                #expect(response.status == .ok)
                let result = try JSONDecoder().decode(ManifestValidationResponse.self, from: response.body)
                #expect(result.valid)
                #expect(result.issues.isEmpty)
            }
        }
    }

    @Test("Git source validation endpoint accepts a safe source")
    func gitSourceValidation() async throws {
        let application = try buildApplication(configuration: ServiceConfiguration(environment: [:]))
        let body = try JSONEncoder().encode(GitSourceConfiguration.validFixture)

        try await application.test(.router) { client in
            try await client.execute(
                uri: "/api/v1/sources/git/validate",
                method: .post,
                headers: [.contentType: "application/json"],
                body: .init(data: body),
            ) { response in
                #expect(response.status == .ok)
                let result = try JSONDecoder().decode(GitSourceValidationResponse.self, from: response.body)
                #expect(result.valid)
                #expect(result.issues.isEmpty)
            }
        }
    }

    @Test("unknown endpoints use the stable error envelope")
    func unknownEndpoint() async throws {
        let application = try buildApplication(configuration: ServiceConfiguration(environment: [:]))

        try await application.test(.router) { client in
            try await client.execute(uri: "/missing", method: .get) { response in
                #expect(response.status == .notFound)
                let result = try JSONDecoder().decode(APIErrorEnvelope.self, from: response.body)
                #expect(result.error.code == "not_found")
            }
        }
    }

    @Test("malformed JSON uses the stable error envelope")
    func malformedJSON() async throws {
        let application = try buildApplication(configuration: ServiceConfiguration(environment: [:]))

        try await application.test(.router) { client in
            try await client.execute(
                uri: "/api/v1/manifests/validate",
                method: .post,
                headers: [.contentType: "application/json"],
                body: .init(string: "{"),
            ) { response in
                #expect(response.status == .badRequest)
                let result = try JSONDecoder().decode(APIErrorEnvelope.self, from: response.body)
                #expect(result.error.code == "invalid_request")
            }
        }
    }
}
