@testable import ProjectDeployerService
import Testing

@Suite("Docker client")
struct DockerClientTests {
    @Test("missing container messages from supported Docker versions are recognized")
    func missingContainerMessages() {
        #expect(DockerClient.isMissingContainerError("Error: No such object: project-deployer-demo"))
        #expect(DockerClient.isMissingContainerError("Error response from daemon: No such container: demo"))
        #expect(!DockerClient.isMissingContainerError("permission denied"))
    }
}
