@testable import ProjectDeployerService
import Testing

extension GitSourceConfiguration {
    static var validFixture: Self {
        .init(
            repositoryURL: "ssh://git@github.com/dcstudio/example.git",
            branch: "main",
            manifestPath: "project-deployer.json",
            pollIntervalSeconds: 60,
            credentialId: "github-deploy-key",
            trigger: .init(
                mode: .automatic,
                includePaths: ["Sources/**", "Package.swift"],
                excludePaths: ["docs/**"],
            ),
        )
    }
}

@Suite("Git source configuration")
struct GitSourceConfigurationTests {
    @Test("valid fixture has no issues")
    func validSource() {
        #expect(GitSourceConfiguration.validFixture.validationIssues().isEmpty)
    }

    @Test("unsafe source settings produce stable issue codes")
    func invalidSource() {
        let source = GitSourceConfiguration(
            repositoryURL: "file:///tmp/repository",
            branch: "../main.lock",
            manifestPath: "../project-deployer.json",
            pollIntervalSeconds: 1,
            credentialId: "Invalid_Key",
            trigger: .init(
                mode: .automatic,
                includePaths: ["/Sources/**"],
                excludePaths: ["../secrets/**"],
            ),
        )

        let codes = Set(source.validationIssues().map(\.code))
        #expect(codes.contains("invalid_repository_url"))
        #expect(codes.contains("invalid_branch"))
        #expect(codes.contains("invalid_manifest_path"))
        #expect(codes.contains("invalid_poll_interval"))
        #expect(codes.contains("invalid_credential_id"))
        #expect(codes.contains("invalid_include_paths"))
        #expect(codes.contains("invalid_exclude_paths"))
    }
}
