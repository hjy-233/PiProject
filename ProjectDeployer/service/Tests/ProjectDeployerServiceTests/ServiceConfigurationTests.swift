import Logging
@testable import ProjectDeployerService
import Testing

@Suite("Service configuration")
struct ServiceConfigurationTests {
    @Test("defaults are private and predictable")
    func defaults() throws {
        let configuration = try ServiceConfiguration(environment: [:])
        #expect(configuration.host == "127.0.0.1")
        #expect(configuration.port == 8080)
        #expect(configuration.logLevel == .info)
    }

    @Test("environment overrides are parsed")
    func environmentOverrides() throws {
        let configuration = try ServiceConfiguration(environment: [
            "PROJECT_DEPLOYER_HOST": "100.64.0.10",
            "PROJECT_DEPLOYER_PORT": "9090",
            "PROJECT_DEPLOYER_LOG_LEVEL": "debug",
        ])
        #expect(configuration.host == "100.64.0.10")
        #expect(configuration.port == 9090)
        #expect(configuration.logLevel == .debug)
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
}
