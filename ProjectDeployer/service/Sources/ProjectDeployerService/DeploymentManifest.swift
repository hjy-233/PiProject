import Foundation

struct DeploymentManifest: Codable, Equatable, Sendable {
    struct Build: Codable, Equatable, Sendable {
        let dockerfile: String
        let context: String
    }

    struct EnvironmentVariable: Codable, Equatable, Sendable {
        let name: String
        let required: Bool
        let secret: Bool
    }

    struct Port: Codable, Equatable, Sendable {
        enum ProtocolName: String, Codable, Sendable {
            case tcp
            case udp
        }

        let container: Int
        let host: Int
        let `protocol`: ProtocolName
    }

    struct Volume: Codable, Equatable, Sendable {
        let name: String
        let containerPath: String
        let readOnly: Bool
    }

    struct HealthCheck: Codable, Equatable, Sendable {
        enum CheckType: String, Codable, Sendable {
            case http
            case tcp
        }

        let type: CheckType
        let path: String?
        let port: Int
        let timeoutSeconds: Int
        let startPeriodSeconds: Int
        let retries: Int
    }

    struct Resources: Codable, Equatable, Sendable {
        let memoryMiB: Int
        let cpuPercent: Int
    }

    enum RestartPolicy: String, Codable, Sendable {
        case never = "no"
        case onFailure = "on-failure"
        case unlessStopped = "unless-stopped"
    }

    let schemaVersion: Int
    let projectId: String
    let platform: String
    let build: Build
    let command: [String]
    let environment: [EnvironmentVariable]
    let ports: [Port]
    let volumes: [Volume]
    let healthCheck: HealthCheck?
    let resources: Resources
    let restartPolicy: RestartPolicy

    func validationIssues() -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        validateIdentity(into: &issues)
        validateBuild(into: &issues)
        validateCommand(into: &issues)
        validateEnvironment(into: &issues)
        validatePorts(into: &issues)
        validateVolumes(into: &issues)
        validateHealthCheck(into: &issues)
        validateResources(into: &issues)
        return issues
    }

    private func validateIdentity(into issues: inout [ValidationIssue]) {
        if schemaVersion != 1 {
            issues.append(.init(code: "unsupported_schema", field: "schemaVersion"))
        }
        if !Self.isDNSLabel(projectId) {
            issues.append(.init(code: "invalid_project_id", field: "projectId"))
        }
        if platform != "linux/arm64" {
            issues.append(.init(code: "unsupported_platform", field: "platform"))
        }
    }

    private func validateBuild(into issues: inout [ValidationIssue]) {
        if !Self.isSafeRelativePath(build.dockerfile, allowCurrentDirectory: false) {
            issues.append(.init(code: "invalid_dockerfile_path", field: "build.dockerfile"))
        }
        if !Self.isSafeRelativePath(build.context, allowCurrentDirectory: true) {
            issues.append(.init(code: "invalid_build_context", field: "build.context"))
        }
    }

    private func validateCommand(into issues: inout [ValidationIssue]) {
        if command.isEmpty || command.count > 64 {
            issues.append(.init(code: "invalid_command", field: "command"))
            return
        }

        if command.contains(where: { $0.isEmpty || $0.count > 4096 || $0.contains("\0") }) {
            issues.append(.init(code: "invalid_command_argument", field: "command"))
        }
    }

    private func validateEnvironment(into issues: inout [ValidationIssue]) {
        var names: Set<String> = []
        for variable in environment {
            if !Self.isEnvironmentName(variable.name) {
                issues.append(.init(code: "invalid_environment_name", field: "environment.name"))
            }
            if !names.insert(variable.name).inserted {
                issues.append(.init(code: "duplicate_environment_name", field: "environment.name"))
            }
        }
    }

    private func validatePorts(into issues: inout [ValidationIssue]) {
        var containerPorts: Set<Int> = []
        var hostPorts: Set<Int> = []
        for port in ports {
            if !(1 ... 65535).contains(port.container) {
                issues.append(.init(code: "invalid_container_port", field: "ports.container"))
            }
            if !(1 ... 65535).contains(port.host) {
                issues.append(.init(code: "invalid_host_port", field: "ports.host"))
            }
            if !containerPorts.insert(port.container).inserted {
                issues.append(.init(code: "duplicate_container_port", field: "ports.container"))
            }
            if !hostPorts.insert(port.host).inserted {
                issues.append(.init(code: "duplicate_host_port", field: "ports.host"))
            }
        }
    }

    private func validateVolumes(into issues: inout [ValidationIssue]) {
        var names: Set<String> = []
        var paths: Set<String> = []
        for volume in volumes {
            if !Self.isDNSLabel(volume.name) {
                issues.append(.init(code: "invalid_volume_name", field: "volumes.name"))
            }
            if !Self.isSafeContainerPath(volume.containerPath) {
                issues.append(.init(code: "invalid_container_path", field: "volumes.containerPath"))
            }
            if !names.insert(volume.name).inserted {
                issues.append(.init(code: "duplicate_volume_name", field: "volumes.name"))
            }
            if !paths.insert(volume.containerPath).inserted {
                issues.append(.init(code: "duplicate_container_path", field: "volumes.containerPath"))
            }
        }
    }

    private func validateHealthCheck(into issues: inout [ValidationIssue]) {
        guard let healthCheck else {
            return
        }

        if !ports.contains(where: { $0.container == healthCheck.port }) {
            issues.append(.init(code: "unknown_health_port", field: "healthCheck.port"))
        }
        if healthCheck.type == .http {
            guard let path = healthCheck.path, path.hasPrefix("/"), !path.contains("..") else {
                issues.append(.init(code: "invalid_health_path", field: "healthCheck.path"))
                return
            }
        }
        if !(1 ... 30).contains(healthCheck.timeoutSeconds) {
            issues.append(.init(code: "invalid_health_timeout", field: "healthCheck.timeoutSeconds"))
        }
        if !(0 ... 300).contains(healthCheck.startPeriodSeconds) {
            issues.append(.init(code: "invalid_health_start_period", field: "healthCheck.startPeriodSeconds"))
        }
        if !(1 ... 10).contains(healthCheck.retries) {
            issues.append(.init(code: "invalid_health_retries", field: "healthCheck.retries"))
        }
    }

    private func validateResources(into issues: inout [ValidationIssue]) {
        if !(16 ... 32768).contains(resources.memoryMiB) {
            issues.append(.init(code: "invalid_memory_limit", field: "resources.memoryMiB"))
        }
        if !(1 ... 100).contains(resources.cpuPercent) {
            issues.append(.init(code: "invalid_cpu_limit", field: "resources.cpuPercent"))
        }
    }

    private static func isDNSLabel(_ value: String) -> Bool {
        guard (1 ... 63).contains(value.count), value.first != "-", value.last != "-" else {
            return false
        }
        return value.unicodeScalars.allSatisfy { scalar in
            (97 ... 122).contains(scalar.value)
                || (48 ... 57).contains(scalar.value)
                || scalar.value == 45
        }
    }

    private static func isEnvironmentName(_ value: String) -> Bool {
        guard let first = value.unicodeScalars.first else {
            return false
        }
        guard first.value == 95 || (65 ... 90).contains(first.value) else {
            return false
        }
        return value.unicodeScalars.dropFirst().allSatisfy { scalar in
            scalar.value == 95
                || (65 ... 90).contains(scalar.value)
                || (48 ... 57).contains(scalar.value)
        }
    }

    private static func isSafeContainerPath(_ value: String) -> Bool {
        guard value.hasPrefix("/"), value != "/", !value.contains("\0") else {
            return false
        }
        let components = value.split(separator: "/", omittingEmptySubsequences: false)
        return !components.contains(".") && !components.contains("..")
    }

    private static func isSafeRelativePath(
        _ value: String,
        allowCurrentDirectory: Bool,
    ) -> Bool {
        if allowCurrentDirectory, value == "." {
            return true
        }
        guard !value.isEmpty, !value.hasPrefix("/"), !value.contains("\0") else {
            return false
        }
        let components = value.split(separator: "/", omittingEmptySubsequences: false)
        return !components.contains("")
            && !components.contains(".")
            && !components.contains("..")
    }
}

struct ValidationIssue: Codable, Equatable, Sendable {
    let code: String
    let field: String
}
