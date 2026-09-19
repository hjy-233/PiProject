@testable import ProjectDeployerService
import Testing

extension DeploymentManifest {
    static var validFixture: Self {
        .init(
            schemaVersion: 1,
            projectId: "hello-service",
            platform: "linux/arm64",
            build: .init(dockerfile: "Dockerfile", context: "."),
            command: ["/app/hello-service", "--port", "8080"],
            environment: [
                .init(name: "APP_TOKEN", required: true, secret: true),
            ],
            ports: [
                .init(container: 8080, host: 18080, protocol: .tcp),
            ],
            volumes: [
                .init(name: "data", containerPath: "/app/data", readOnly: false),
            ],
            healthCheck: .init(
                type: .http,
                path: "/health",
                port: 8080,
                timeoutSeconds: 3,
                startPeriodSeconds: 10,
                retries: 3,
            ),
            resources: .init(memoryMiB: 256, cpuPercent: 50),
            restartPolicy: .unlessStopped,
        )
    }
}

@Suite("Deployment manifest")
struct DeploymentManifestTests {
    @Test("valid fixture has no issues")
    func validManifest() {
        #expect(DeploymentManifest.validFixture.validationIssues().isEmpty)
    }

    @Test("invalid fields produce stable issue codes")
    func invalidManifest() {
        let manifest = DeploymentManifest(
            schemaVersion: 2,
            projectId: "Invalid_Project",
            platform: "linux/amd64",
            build: .init(dockerfile: "../Dockerfile", context: "/tmp"),
            command: [],
            environment: [
                .init(name: "bad-name", required: true, secret: false),
                .init(name: "bad-name", required: false, secret: false),
            ],
            ports: [
                .init(container: 0, host: 70000, protocol: .tcp),
            ],
            volumes: [
                .init(name: "Bad_Volume", containerPath: "../data", readOnly: false),
            ],
            healthCheck: .init(
                type: .http,
                path: "health",
                port: 9999,
                timeoutSeconds: 0,
                startPeriodSeconds: 301,
                retries: 0,
            ),
            resources: .init(memoryMiB: 0, cpuPercent: 101),
            restartPolicy: .unlessStopped,
        )

        let codes = Set(manifest.validationIssues().map(\.code))
        #expect(codes.contains("unsupported_schema"))
        #expect(codes.contains("invalid_project_id"))
        #expect(codes.contains("unsupported_platform"))
        #expect(codes.contains("invalid_dockerfile_path"))
        #expect(codes.contains("invalid_build_context"))
        #expect(codes.contains("invalid_command"))
        #expect(codes.contains("duplicate_environment_name"))
        #expect(codes.contains("invalid_container_port"))
        #expect(codes.contains("invalid_host_port"))
        #expect(codes.contains("invalid_container_path"))
        #expect(codes.contains("unknown_health_port"))
        #expect(codes.contains("invalid_health_path"))
        #expect(codes.contains("invalid_memory_limit"))
        #expect(codes.contains("invalid_cpu_limit"))
    }
}
