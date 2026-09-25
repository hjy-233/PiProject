import Foundation
import Logging

struct ServiceConfiguration: Equatable, Sendable {
    enum ConfigurationError: Error, Equatable, CustomStringConvertible {
        case emptyHost
        case invalidPort(String)
        case invalidLogLevel(String)
        case invalidAbsolutePath(variable: String, value: String)
        case invalidPollSweep(String)
        case invalidRetention(variable: String, value: String)

        var description: String {
            switch self {
            case .emptyHost:
                "PROJECT_DEPLOYER_HOST must not be empty."
            case let .invalidPort(value):
                "PROJECT_DEPLOYER_PORT must be an integer from 1 through 65535, received: \(value)."
            case let .invalidLogLevel(value):
                "PROJECT_DEPLOYER_LOG_LEVEL is not supported, received: \(value)."
            case let .invalidAbsolutePath(variable, value):
                "\(variable) must be an absolute path, received: \(value)."
            case let .invalidPollSweep(value):
                "PROJECT_DEPLOYER_POLL_SWEEP_SECONDS must be from 1 through 60, received: \(value)."
            case let .invalidRetention(variable, value):
                "\(variable) is invalid, received: \(value)."
            }
        }
    }

    let host: String
    let port: Int
    let logLevel: Logger.Level
    let dataRoot: String
    let gitExecutable: String
    let dockerExecutable: String
    let pollSweepSeconds: Int
    let releaseRetentionCount: Int
    let deploymentRetentionCount: Int
    let minimumFreeSpaceMiB: Int

    init(environment: [String: String] = ProcessInfo.processInfo.environment) throws {
        let host = environment["PROJECT_DEPLOYER_HOST"] ?? "127.0.0.1"
        guard !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConfigurationError.emptyHost
        }

        let portValue = environment["PROJECT_DEPLOYER_PORT"] ?? "10000"
        guard let port = Int(portValue), (1 ... 65535).contains(port) else {
            throw ConfigurationError.invalidPort(portValue)
        }

        let logLevelValue = environment["PROJECT_DEPLOYER_LOG_LEVEL"] ?? "info"
        guard let logLevel = Self.logLevel(from: logLevelValue) else {
            throw ConfigurationError.invalidLogLevel(logLevelValue)
        }

        let defaultDataRoot = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/share/project-deployer", isDirectory: true)
            .path
        let dataRoot = environment["PROJECT_DEPLOYER_DATA_ROOT"] ?? defaultDataRoot
        try Self.validateAbsolutePath(dataRoot, variable: "PROJECT_DEPLOYER_DATA_ROOT")

        let gitExecutable = environment["PROJECT_DEPLOYER_GIT_EXECUTABLE"] ?? "/usr/bin/git"
        try Self.validateAbsolutePath(gitExecutable, variable: "PROJECT_DEPLOYER_GIT_EXECUTABLE")

        let dockerExecutable = environment["PROJECT_DEPLOYER_DOCKER_EXECUTABLE"] ?? "/usr/bin/docker"
        try Self.validateAbsolutePath(dockerExecutable, variable: "PROJECT_DEPLOYER_DOCKER_EXECUTABLE")

        let pollSweepValue = environment["PROJECT_DEPLOYER_POLL_SWEEP_SECONDS"] ?? "5"
        guard let pollSweepSeconds = Int(pollSweepValue), (1 ... 60).contains(pollSweepSeconds) else {
            throw ConfigurationError.invalidPollSweep(pollSweepValue)
        }

        let releaseRetentionCount = try Self.positiveInteger(
            environment["PROJECT_DEPLOYER_RELEASE_RETENTION"] ?? "5",
            variable: "PROJECT_DEPLOYER_RELEASE_RETENTION",
            range: 2 ... 50,
        )
        let deploymentRetentionCount = try Self.positiveInteger(
            environment["PROJECT_DEPLOYER_DEPLOYMENT_RETENTION"] ?? "100",
            variable: "PROJECT_DEPLOYER_DEPLOYMENT_RETENTION",
            range: 10 ... 10000,
        )
        let minimumFreeSpaceMiB = try Self.positiveInteger(
            environment["PROJECT_DEPLOYER_MIN_FREE_SPACE_MIB"] ?? "512",
            variable: "PROJECT_DEPLOYER_MIN_FREE_SPACE_MIB",
            range: 128 ... 1_048_576,
        )

        self.host = host
        self.port = port
        self.logLevel = logLevel
        self.dataRoot = dataRoot
        self.gitExecutable = gitExecutable
        self.dockerExecutable = dockerExecutable
        self.pollSweepSeconds = pollSweepSeconds
        self.releaseRetentionCount = releaseRetentionCount
        self.deploymentRetentionCount = deploymentRetentionCount
        self.minimumFreeSpaceMiB = minimumFreeSpaceMiB
    }

    private static func logLevel(from value: String) -> Logger.Level? {
        switch value.lowercased() {
        case "trace":
            .trace
        case "debug":
            .debug
        case "info":
            .info
        case "notice":
            .notice
        case "warning":
            .warning
        case "error":
            .error
        case "critical":
            .critical
        default:
            nil
        }
    }

    private static func validateAbsolutePath(
        _ value: String,
        variable: String,
    ) throws {
        guard value.hasPrefix("/"), !value.contains("\0"), !value.contains("\n") else {
            throw ConfigurationError.invalidAbsolutePath(variable: variable, value: value)
        }
    }

    private static func positiveInteger(
        _ value: String,
        variable: String,
        range: ClosedRange<Int>,
    ) throws -> Int {
        guard let result = Int(value), range.contains(result) else {
            throw ConfigurationError.invalidRetention(variable: variable, value: value)
        }
        return result
    }
}
