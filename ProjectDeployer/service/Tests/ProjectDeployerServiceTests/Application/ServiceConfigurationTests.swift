import Logging
@testable import ProjectDeployerService
import Testing

@Suite("Service configuration")
struct ServiceConfigurationTests {
    @Test("defaults are private and predictable")
    func defaults() throws {
        let configuration = try ServiceConfiguration(environment: [:])
        #expect(configuration.host == "127.0.0.1")
        #expect(configuration.port == 10000)
        #expect(configuration.logLevel == .info)
        #expect(configuration.dataRoot.hasSuffix("/.local/share/project-deployer"))
        #expect(configuration.gitExecutable == "/usr/bin/git")
        #expect(configuration.dockerExecutable == "/usr/bin/docker")
        #expect(configuration.pollSweepSeconds == 5)
        #expect(configuration.releaseRetentionCount == 5)
        #expect(configuration.deploymentRetentionCount == 100)
        #expect(configuration.minimumFreeSpaceMiB == 512)
        #expect(configuration.consoleRoot.hasSuffix("/.local/share/project-deployer/console"))
    }

    @Test("environment overrides are parsed")
    func environmentOverrides() throws {
        let configuration = try ServiceConfiguration(environment: [
            "PROJECT_DEPLOYER_HOST": "100.64.0.10",
            "PROJECT_DEPLOYER_PORT": "9090",
            "PROJECT_DEPLOYER_LOG_LEVEL": "debug",
            "PROJECT_DEPLOYER_DATA_ROOT": "/var/lib/project-deployer",
            "PROJECT_DEPLOYER_GIT_EXECUTABLE": "/opt/bin/git",
            "PROJECT_DEPLOYER_DOCKER_EXECUTABLE": "/opt/bin/docker",
            "PROJECT_DEPLOYER_POLL_SWEEP_SECONDS": "12",
            "PROJECT_DEPLOYER_RELEASE_RETENTION": "8",
            "PROJECT_DEPLOYER_DEPLOYMENT_RETENTION": "200",
            "PROJECT_DEPLOYER_MIN_FREE_SPACE_MIB": "1024",
            "PROJECT_DEPLOYER_CONSOLE_ROOT": "/var/lib/project-deployer-console",
        ])
        #expect(configuration.host == "100.64.0.10")
        #expect(configuration.port == 9090)
        #expect(configuration.logLevel == .debug)
        #expect(configuration.dataRoot == "/var/lib/project-deployer")
        #expect(configuration.gitExecutable == "/opt/bin/git")
        #expect(configuration.dockerExecutable == "/opt/bin/docker")
        #expect(configuration.pollSweepSeconds == 12)
        #expect(configuration.releaseRetentionCount == 8)
        #expect(configuration.deploymentRetentionCount == 200)
        #expect(configuration.minimumFreeSpaceMiB == 1024)
        #expect(configuration.consoleRoot == "/var/lib/project-deployer-console")
    }

    @Test("invalid port is rejected")
    func invalidPort() {
        #expect(throws: ServiceConfiguration.ConfigurationError.invalidPort("70000")) {
            try ServiceConfiguration(environment: ["PROJECT_DEPLOYER_PORT": "70000"])
        }
    }

    @Test("invalid log level is rejected")
    func invalidLogLevel() {
        #expect(throws: ServiceConfiguration.ConfigurationError.invalidLogLevel("verbose")) {
            try ServiceConfiguration(environment: ["PROJECT_DEPLOYER_LOG_LEVEL": "verbose"])
        }
    }

    @Test("relative runtime paths are rejected")
    func invalidRuntimePath() {
        #expect(throws: ServiceConfiguration.ConfigurationError.invalidAbsolutePath(
            variable: "PROJECT_DEPLOYER_DATA_ROOT",
            value: "data",
        )) {
            try ServiceConfiguration(environment: ["PROJECT_DEPLOYER_DATA_ROOT": "data"])
        }
    }

    @Test("invalid polling sweep is rejected")
    func invalidPollingSweep() {
        #expect(throws: ServiceConfiguration.ConfigurationError.invalidPollSweep("0")) {
            try ServiceConfiguration(environment: ["PROJECT_DEPLOYER_POLL_SWEEP_SECONDS": "0"])
        }
    }

    @Test("invalid retention is rejected")
    func invalidRetention() {
        #expect(throws: ServiceConfiguration.ConfigurationError.invalidRetention(
            variable: "PROJECT_DEPLOYER_RELEASE_RETENTION",
            value: "1",
        )) {
            try ServiceConfiguration(environment: ["PROJECT_DEPLOYER_RELEASE_RETENTION": "1"])
        }
    }
}
