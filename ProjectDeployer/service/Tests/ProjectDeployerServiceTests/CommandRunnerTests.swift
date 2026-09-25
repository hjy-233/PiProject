import Foundation
@testable import ProjectDeployerService
import Testing

@Suite("Command runner")
struct CommandRunnerTests {
    @Test("cancelling a command terminates its child process")
    func cancellationTerminatesProcess() async throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }
        let runner = try CommandRunner(temporaryDirectory: temporaryDirectory)
        let task = Task {
            try await runner.run(executable: "/bin/sleep", arguments: ["30"])
        }

        try await Task.sleep(for: .milliseconds(100))
        task.cancel()
        let result = try await task.value

        #expect(!result.succeeded)
    }
}
