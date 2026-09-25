import CSQLite
import Foundation

actor ProjectStore {
    private final class DatabaseHandle: @unchecked Sendable {
        let value: OpaquePointer

        init(_ value: OpaquePointer) {
            self.value = value
        }

        deinit {
            sqlite3_close(value)
        }
    }

    struct StoreError: Error, CustomStringConvertible, Sendable {
        let operation: String
        let detail: String

        var description: String {
            "SQLite \(operation) failed: \(detail)"
        }
    }

    private struct PersistedState: Codable, Sendable {
        var schemaVersion = 1
        var projects: [StoredProject] = []
        var releases: [ReleaseRecord] = []
        var deployments: [DeploymentRecord] = []
    }

    private let database: DatabaseHandle
    private var state: PersistedState

    init(path: String) throws {
        let databaseURL = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(
            at: databaseURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
        )

        guard sqlite3_initialize() == SQLITE_OK else {
            throw StoreError(operation: "initialize", detail: "sqlite3_initialize returned an error")
        }

        var handle: OpaquePointer?
        let openResult = sqlite3_open_v2(
            path,
            &handle,
            SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_PRIVATECACHE,
            nil,
        )
        guard openResult == SQLITE_OK, let handle else {
            let detail = handle.map { String(cString: sqlite3_errmsg($0)) } ?? "database could not be opened"
            if let handle {
                sqlite3_close(handle)
            }
            throw StoreError(operation: "open", detail: detail)
        }

        database = DatabaseHandle(handle)
        state = PersistedState()

        do {
            try Self.execute(
                database: handle,
                sql: """
                CREATE TABLE IF NOT EXISTS application_state (
                    id INTEGER PRIMARY KEY CHECK (id = 1),
                    document BLOB NOT NULL
                );
                """,
            )
            try Self.execute(database: handle, sql: "PRAGMA synchronous = FULL;")
            state = try Self.loadState(database: handle)
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o600],
                ofItemAtPath: path,
            )
        } catch {
            throw error
        }
    }

    func allProjects() -> [StoredProject] {
        state.projects.sorted { $0.createdAt < $1.createdAt }
    }

    func project(id: String) -> StoredProject? {
        state.projects.first { $0.id == id }
    }

    func createProject(_ project: StoredProject) throws {
        guard !state.projects.contains(where: { $0.id == project.id }) else {
            throw APIError(
                status: .conflict,
                code: "project_exists",
                message: "A project with this id already exists.",
            )
        }
        var updatedState = state
        updatedState.projects.append(project)
        try persist(updatedState)
        state = updatedState
    }

    func saveProject(_ project: StoredProject) throws {
        guard let index = state.projects.firstIndex(where: { $0.id == project.id }) else {
            throw APIError(
                status: .notFound,
                code: "project_not_found",
                message: "The requested project does not exist.",
            )
        }
        var updatedState = state
        updatedState.projects[index] = project
        try persist(updatedState)
        state = updatedState
    }

    func releases(projectId: String) -> [ReleaseRecord] {
        state.releases
            .filter { $0.projectId == projectId }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func release(id: String, projectId: String) -> ReleaseRecord? {
        state.releases.first { $0.id == id && $0.projectId == projectId }
    }

    func release(commit: String, projectId: String) -> ReleaseRecord? {
        state.releases.first { $0.commit == commit && $0.projectId == projectId }
    }

    func saveRelease(_ release: ReleaseRecord) throws {
        var updatedState = state
        if let index = updatedState.releases.firstIndex(where: { $0.id == release.id }) {
            updatedState.releases[index] = release
        } else {
            updatedState.releases.append(release)
        }
        try persist(updatedState)
        state = updatedState
    }

    func deployments(projectId: String, limit: Int = 50) -> [DeploymentRecord] {
        Array(
            state.deployments
                .filter { $0.projectId == projectId }
                .sorted { $0.startedAt > $1.startedAt }
                .prefix(limit),
        )
    }

    func saveDeployment(_ deployment: DeploymentRecord) throws {
        var updatedState = state
        if let index = updatedState.deployments.firstIndex(where: { $0.id == deployment.id }) {
            updatedState.deployments[index] = deployment
        } else {
            updatedState.deployments.append(deployment)
        }
        try persist(updatedState)
        state = updatedState
    }

    private func persist(_ updatedState: PersistedState) throws {
        let document = try JSONEncoder().encode(updatedState)
        let sql = """
        INSERT INTO application_state (id, document) VALUES (1, ?)
        ON CONFLICT(id) DO UPDATE SET document = excluded.document;
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database.value, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
            throw databaseError(operation: "prepare state write")
        }
        defer {
            sqlite3_finalize(statement)
        }

        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        let bindResult = document.withUnsafeBytes { bytes in
            sqlite3_bind_blob(statement, 1, bytes.baseAddress, Int32(bytes.count), transient)
        }
        guard bindResult == SQLITE_OK else {
            throw databaseError(operation: "bind state")
        }
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw databaseError(operation: "write state")
        }
    }

    private func databaseError(operation: String) -> StoreError {
        StoreError(operation: operation, detail: String(cString: sqlite3_errmsg(database.value)))
    }

    private static func loadState(database: OpaquePointer) throws -> PersistedState {
        var statement: OpaquePointer?
        let sql = "SELECT document FROM application_state WHERE id = 1;"
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
            throw StoreError(operation: "prepare state read", detail: String(cString: sqlite3_errmsg(database)))
        }
        defer {
            sqlite3_finalize(statement)
        }

        let result = sqlite3_step(statement)
        if result == SQLITE_DONE {
            return PersistedState()
        }
        guard result == SQLITE_ROW,
              let bytes = sqlite3_column_blob(statement, 0)
        else {
            throw StoreError(operation: "read state", detail: String(cString: sqlite3_errmsg(database)))
        }

        let count = Int(sqlite3_column_bytes(statement, 0))
        return try JSONDecoder().decode(PersistedState.self, from: Data(bytes: bytes, count: count))
    }

    private static func execute(database: OpaquePointer, sql: String) throws {
        var errorMessage: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(database, sql, nil, nil, &errorMessage)
        guard result == SQLITE_OK else {
            let detail = errorMessage.map { String(cString: $0) } ?? String(cString: sqlite3_errmsg(database))
            sqlite3_free(errorMessage)
            throw StoreError(operation: "execute", detail: detail)
        }
    }
}
