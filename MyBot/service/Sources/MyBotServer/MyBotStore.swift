import CSQLite
import Foundation
import MyBotCore

public actor MyBotStore {
    private final class DatabaseHandle: @unchecked Sendable {
        let value: OpaquePointer

        init(_ value: OpaquePointer) {
            self.value = value
        }

        deinit {
            sqlite3_close(value)
        }
    }

    private struct State: Codable, Sendable {
        var schemaVersion = 1
        var libraries: [Library] = []
        var conversations: [Conversation] = []
        var messages: [ChatMessage] = []
        var tasks: [CodexTask] = []
    }

    private let database: DatabaseHandle
    private var state: State

    public init(path: String) throws {
        if path != ":memory:" {
            let databaseURL = URL(fileURLWithPath: path)
            try FileManager.default.createDirectory(
                at: databaseURL.deletingLastPathComponent(),
                withIntermediateDirectories: true,
            )
        }
        guard sqlite3_initialize() == SQLITE_OK else {
            throw StoreError(operation: "initialize", detail: "sqlite3_initialize returned an error")
        }
        var handle: OpaquePointer?
        let result = sqlite3_open_v2(
            path,
            &handle,
            SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_PRIVATECACHE,
            nil,
        )
        guard result == SQLITE_OK, let handle else {
            if let handle {
                sqlite3_close(handle)
            }
            throw StoreError(operation: "open", detail: "database could not be opened")
        }
        database = DatabaseHandle(handle)
        state = State()
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
        state = try Self.load(database: handle)
        if path != ":memory:" {
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: path)
        }
    }

    public func libraries() -> [Library] {
        state.libraries.sorted { $0.createdAt < $1.createdAt }
    }

    public func createLibrary(
        name: String,
        agentId: UUID?,
        workspacePath: String,
        memoryMode: MemoryMode,
    ) throws -> Library {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPath = workspacePath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedPath.isEmpty else {
            throw APIError(
                status: .unprocessableContent,
                code: "invalid_library",
                message: "Name and workspace path are required.",
            )
        }
        let library = Library(
            id: UUID(),
            name: trimmedName,
            agentId: agentId,
            workspacePath: trimmedPath,
            memoryMode: memoryMode,
            createdAt: Date(),
        )
        var updated = state
        updated.libraries.append(library)
        try save(updated)
        state = updated
        return library
    }

    public func conversations(libraryId: UUID?) -> [Conversation] {
        state.conversations
            .filter { $0.libraryId == libraryId }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    public func createConversation(
        libraryId: UUID?,
        title: String,
        kind: ConversationKind,
    ) throws -> Conversation {
        if kind == .library {
            guard let libraryId, state.libraries.contains(where: { $0.id == libraryId }) else {
                throw APIError(
                    status: .notFound,
                    code: "library_not_found",
                    message: "The requested library does not exist.",
                )
            }
        }
        let now = Date()
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let conversation = Conversation(
            id: UUID(),
            libraryId: libraryId,
            kind: kind,
            title: trimmedTitle.isEmpty ? "新对话" : trimmedTitle,
            codexSessionId: nil,
            createdAt: now,
            updatedAt: now,
        )
        var updated = state
        updated.conversations.append(conversation)
        try save(updated)
        state = updated
        return conversation
    }

    public func messages(conversationId: UUID) throws -> [ChatMessage] {
        guard state.conversations.contains(where: { $0.id == conversationId }) else {
            throw APIError(
                status: .notFound,
                code: "conversation_not_found",
                message: "The requested conversation does not exist.",
            )
        }
        return state.messages
            .filter { $0.conversationId == conversationId }
            .sorted { $0.createdAt < $1.createdAt }
    }

    public func enqueuePrompt(conversationId: UUID, content: String) throws -> PromptResponse {
        guard let conversationIndex = state.conversations.firstIndex(where: { $0.id == conversationId }) else {
            throw APIError(
                status: .notFound,
                code: "conversation_not_found",
                message: "The requested conversation does not exist.",
            )
        }
        guard !state.tasks.contains(where: { $0.conversationId == conversationId && $0.state.isActive }) else {
            throw APIError(
                status: .conflict,
                code: "conversation_busy",
                message: "This conversation already has an active task.",
            )
        }
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            throw APIError(
                status: .unprocessableContent,
                code: "empty_message",
                message: "Message content is required.",
            )
        }
        let now = Date()
        let message = ChatMessage(
            id: UUID(),
            conversationId: conversationId,
            role: .user,
            content: trimmedContent,
            createdAt: now,
        )
        let task = CodexTask(
            id: UUID(),
            conversationId: conversationId,
            promptMessageId: message.id,
            state: .queued,
            createdAt: now,
            updatedAt: now,
        )
        let updated = stateByAdding(
            message: message,
            task: task,
            conversationIndex: conversationIndex,
            at: now,
        )
        try save(updated)
        state = updated
        return PromptResponse(message: message, task: task)
    }

    public func tasks(conversationId: UUID) -> [CodexTask] {
        state.tasks
            .filter { $0.conversationId == conversationId }
            .sorted { $0.createdAt > $1.createdAt }
    }
}

private extension MyBotStore {
    private func stateByAdding(
        message: ChatMessage,
        task: CodexTask,
        conversationIndex: Int,
        at date: Date,
    ) -> State {
        var updated = state
        updated.messages.append(message)
        updated.tasks.append(task)
        let existing = updated.conversations[conversationIndex]
        updated.conversations[conversationIndex] = Conversation(
            id: existing.id,
            libraryId: existing.libraryId,
            kind: existing.kind,
            title: existing.title,
            codexSessionId: existing.codexSessionId,
            createdAt: existing.createdAt,
            updatedAt: date,
        )
        return updated
    }

    private func save(_ updated: State) throws {
        let document = try JSONEncoder().encode(updated)
        let sql = """
        INSERT INTO application_state (id, document) VALUES (1, ?)
        ON CONFLICT(id) DO UPDATE SET document = excluded.document;
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database.value, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
            throw databaseError(operation: "prepare write")
        }
        defer { sqlite3_finalize(statement) }
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        let bind = document.withUnsafeBytes { bytes in
            sqlite3_bind_blob(statement, 1, bytes.baseAddress, Int32(bytes.count), transient)
        }
        guard bind == SQLITE_OK, sqlite3_step(statement) == SQLITE_DONE else {
            throw databaseError(operation: "write")
        }
    }

    private func databaseError(operation: String) -> StoreError {
        StoreError(operation: operation, detail: String(cString: sqlite3_errmsg(database.value)))
    }

    private static func load(database: OpaquePointer) throws -> State {
        var statement: OpaquePointer?
        let prepareResult = sqlite3_prepare_v2(
            database,
            "SELECT document FROM application_state WHERE id = 1;",
            -1,
            &statement,
            nil,
        )
        guard prepareResult == SQLITE_OK,
              let statement
        else {
            throw StoreError(operation: "prepare read", detail: String(cString: sqlite3_errmsg(database)))
        }
        defer { sqlite3_finalize(statement) }
        let result = sqlite3_step(statement)
        if result == SQLITE_DONE {
            return State()
        }
        guard result == SQLITE_ROW, let bytes = sqlite3_column_blob(statement, 0) else {
            throw StoreError(operation: "read", detail: String(cString: sqlite3_errmsg(database)))
        }
        return try JSONDecoder().decode(
            State.self,
            from: Data(bytes: bytes, count: Int(sqlite3_column_bytes(statement, 0))),
        )
    }

    private static func execute(database: OpaquePointer, sql: String) throws {
        var errorMessage: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(database, sql, nil, nil, &errorMessage) == SQLITE_OK else {
            let detail = errorMessage.map { String(cString: $0) } ?? String(cString: sqlite3_errmsg(database))
            sqlite3_free(errorMessage)
            throw StoreError(operation: "execute", detail: detail)
        }
    }
}

public struct PromptResponse: Codable, Equatable, Sendable {
    public let message: ChatMessage
    public let task: CodexTask
}

struct StoreError: Error, CustomStringConvertible, Sendable {
    let operation: String
    let detail: String

    var description: String {
        "SQLite \(operation) failed: \(detail)"
    }
}

private extension TaskState {
    var isActive: Bool {
        switch self {
        case .queued, .offered, .running, .cancelling, .connectionLost:
            true
        case .succeeded, .failed, .cancelled:
            false
        }
    }
}
