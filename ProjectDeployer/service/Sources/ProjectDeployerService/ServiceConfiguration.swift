import Foundation
import Logging

struct ServiceConfiguration: Equatable, Sendable {
    enum ConfigurationError: Error, Equatable, CustomStringConvertible {
        case emptyHost
        case invalidPort(String)
        case invalidLogLevel(String)

        var description: String {
            switch self {
            case .emptyHost:
                "PROJECT_DEPLOYER_HOST must not be empty."
            case let .invalidPort(value):
                "PROJECT_DEPLOYER_PORT must be an integer from 1 through 65535, received: \(value)."
            case let .invalidLogLevel(value):
                "PROJECT_DEPLOYER_LOG_LEVEL is not supported, received: \(value)."
            }
        }
    }

    let host: String
    let port: Int
    let logLevel: Logger.Level

    init(environment: [String: String] = ProcessInfo.processInfo.environment) throws {
        let host = environment["PROJECT_DEPLOYER_HOST"] ?? "127.0.0.1"
        guard !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConfigurationError.emptyHost
        }

        let portValue = environment["PROJECT_DEPLOYER_PORT"] ?? "8080"
        guard let port = Int(portValue), (1 ... 65535).contains(port) else {
            throw ConfigurationError.invalidPort(portValue)
        }

        let logLevelValue = environment["PROJECT_DEPLOYER_LOG_LEVEL"] ?? "info"
        guard let logLevel = Self.logLevel(from: logLevelValue) else {
            throw ConfigurationError.invalidLogLevel(logLevelValue)
        }

        self.host = host
        self.port = port
        self.logLevel = logLevel
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
}
