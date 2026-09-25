import Foundation
@testable import ProjectDeployerService
import Testing

@Suite("Project store lifecycle", .serialized)
struct ProjectStoreLifecycleTests {
    @Test("pruning protects active releases and bounds history")
    func pruneHistory() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = try ProjectStore(path: root.appendingPathComponent("store.sqlite").path)
        let project = fixtureProject()
        try await store.createProject(project)
        let releases = (0 ..< 5).map { index in
            ReleaseRecord(
                id: "release-\(index)",
                projectId: project.id,
                commit: String(repeating: String(index), count: 40),
                directory: root.appendingPathComponent("release-\(index)").path,
                imageTag: "example:\(index)",
                imageId: nil,
                manifest: nil,
                status: .ready,
                message: nil,
                createdAt: Date(timeIntervalSince1970: TimeInterval(index)),
            )
        }
        for release in releases {
            try await store.saveRelease(release)
        }

        let removed = try await store.prune(
            projectId: project.id,
            keepingReleaseIds: ["release-0"],
            releaseLimit: 2,
            deploymentLimit: 10,
        )

        #expect(Set(removed.map(\.id)) == ["release-1", "release-2"])
        #expect(await Set(store.releases(projectId: project.id).map(\.id)) == [
            "release-0",
            "release-3",
            "release-4",
        ])
    }

    @Test("deleting a project removes its persisted history")
    func deleteProject() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = try ProjectStore(path: root.appendingPathComponent("store.sqlite").path)
        let project = fixtureProject()
        try await store.createProject(project)
        try await store.saveRelease(
            ReleaseRecord(
                id: "release",
                projectId: project.id,
                commit: String(repeating: "a", count: 40),
                directory: "",
                imageTag: nil,
                imageId: nil,
                manifest: nil,
                status: .skipped,
                message: nil,
                createdAt: Date(),
            ),
        )

        try await store.deleteProject(id: project.id)

        #expect(await store.project(id: project.id) == nil)
        #expect(await store.releases(projectId: project.id).isEmpty)
    }

    private func fixtureProject() -> StoredProject {
        let now = Date()
        return StoredProject(
            id: "hello-service",
            name: "Hello Service",
            source: .validFixture,
            environment: [:],
            observedCommit: nil,
            currentReleaseId: nil,
            previousReleaseId: nil,
            desiredState: .stopped,
            lastError: nil,
            createdAt: now,
            updatedAt: now,
            nextPollAt: now,
        )
    }
}
