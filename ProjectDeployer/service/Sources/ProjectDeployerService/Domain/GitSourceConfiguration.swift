import Foundation

struct GitSourceConfiguration: Codable, Equatable, Sendable {
    struct Trigger: Codable, Equatable, Sendable {
        enum Mode: String, Codable, Sendable {
            case automatic
            case manual
        }

        let mode: Mode
        let includePaths: [String]
        let excludePaths: [String]
    }

    let repositoryURL: String
    let branch: String
    let manifestPath: String
    let pollIntervalSeconds: Int
    let credentialId: String?
    let trigger: Trigger

    func validationIssues() -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        validateRepositoryURL(into: &issues)
        validateBranch(into: &issues)
        validatePaths(into: &issues)
        validatePollInterval(into: &issues)
        validateCredentialId(into: &issues)
        return issues
    }

    private func validateRepositoryURL(into issues: inout [ValidationIssue]) {
        guard let components = URLComponents(string: repositoryURL),
              let scheme = components.scheme?.lowercased(),
              ["https", "ssh"].contains(scheme),
              components.host != nil
        else {
            issues.append(.init(code: "invalid_repository_url", field: "repositoryURL"))
            return
        }

        if components.password != nil || (scheme == "https" && components.user != nil) {
            issues.append(.init(code: "embedded_repository_credential", field: "repositoryURL"))
        }
    }

    private func validateBranch(into issues: inout [ValidationIssue]) {
        let forbiddenCharacters = CharacterSet(charactersIn: " ~^:?*[\\")
        let isInvalid = branch.isEmpty
            || branch.count > 255
            || branch.hasPrefix("-")
            || branch.hasPrefix(".")
            || branch.hasPrefix("/")
            || branch.hasSuffix("/")
            || branch.hasSuffix(".")
            || branch.hasSuffix(".lock")
            || branch.contains("..")
            || branch.contains("@{")
            || branch.contains("//")
            || branch.unicodeScalars.contains(where: forbiddenCharacters.contains)

        if isInvalid {
            issues.append(.init(code: "invalid_branch", field: "branch"))
        }
    }

    private func validatePaths(into issues: inout [ValidationIssue]) {
        if !Self.isSafeRepositoryPath(manifestPath, allowGlob: false) {
            issues.append(.init(code: "invalid_manifest_path", field: "manifestPath"))
        }
        let hasInvalidIncludePath = trigger.includePaths.contains {
            !Self.isSafeRepositoryPath($0, allowGlob: true)
        }
        if trigger.includePaths.count > 64 || hasInvalidIncludePath {
            issues.append(.init(code: "invalid_include_paths", field: "trigger.includePaths"))
        }
        let hasInvalidExcludePath = trigger.excludePaths.contains {
            !Self.isSafeRepositoryPath($0, allowGlob: true)
        }
        if trigger.excludePaths.count > 64 || hasInvalidExcludePath {
            issues.append(.init(code: "invalid_exclude_paths", field: "trigger.excludePaths"))
        }
    }

    private func validatePollInterval(into issues: inout [ValidationIssue]) {
        if !(15 ... 3600).contains(pollIntervalSeconds) {
            issues.append(.init(code: "invalid_poll_interval", field: "pollIntervalSeconds"))
        }
    }

    private func validateCredentialId(into issues: inout [ValidationIssue]) {
        guard let credentialId else {
            return
        }
        if !Self.isIdentifier(credentialId) {
            issues.append(.init(code: "invalid_credential_id", field: "credentialId"))
        }
    }

    private static func isSafeRepositoryPath(_ value: String, allowGlob: Bool) -> Bool {
        guard !value.isEmpty,
              value.count <= 255,
              !value.hasPrefix("/"),
              !value.contains("\0"),
              allowGlob || !value.contains(where: { "*?[".contains($0) })
        else {
            return false
        }
        let components = value.split(separator: "/", omittingEmptySubsequences: false)
        return !components.contains("") && !components.contains(".") && !components.contains("..")
    }

    private static func isIdentifier(_ value: String) -> Bool {
        guard (1 ... 63).contains(value.count), value.first != "-", value.last != "-" else {
            return false
        }
        return value.unicodeScalars.allSatisfy { scalar in
            (97 ... 122).contains(scalar.value)
                || (48 ... 57).contains(scalar.value)
                || scalar.value == 45
        }
    }
}
