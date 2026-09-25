import Foundation

public enum MemoryMode: String, Codable, CaseIterable, Equatable, Sendable {
    case codexDefault
    case library
    case none
}

public enum ConversationKind: String, Codable, Equatable, Sendable {
    case library
    case temporary
}

public enum TaskState: String, Codable, Equatable, Sendable {
    case queued
    case offered
    case running
    case cancelling
    case succeeded
    case failed
    case cancelled
    case connectionLost
}

public enum AgentState: String, Codable, Equatable, Sendable {
    case offline
    case online
    case busy
}

public enum TaskEventKind: String, Codable, Equatable, Sendable {
    case sessionStarted
    case assistantText
    case commandStarted
    case commandOutput
    case fileChanged
    case warning
    case completed
    case failed
    case cancelled
}

public struct Library: Codable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let agentId: UUID?
    public let workspacePath: String
    public let memoryMode: MemoryMode
    public let createdAt: Date

    public init(
        id: UUID,
        name: String,
        agentId: UUID?,
        workspacePath: String,
        memoryMode: MemoryMode,
        createdAt: Date,
    ) {
        self.id = id
        self.name = name
        self.agentId = agentId
        self.workspacePath = workspacePath
        self.memoryMode = memoryMode
        self.createdAt = createdAt
    }
}

public struct Conversation: Codable, Equatable, Sendable {
    public let id: UUID
    public let libraryId: UUID?
    public let kind: ConversationKind
    public let title: String
    public let codexSessionId: UUID?
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: UUID,
        libraryId: UUID?,
        kind: ConversationKind,
        title: String,
        codexSessionId: UUID?,
        createdAt: Date,
        updatedAt: Date,
    ) {
        self.id = id
        self.libraryId = libraryId
        self.kind = kind
        self.title = title
        self.codexSessionId = codexSessionId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum MessageRole: String, Codable, Equatable, Sendable {
    case user
    case assistant
    case system
}

public struct ChatMessage: Codable, Equatable, Sendable {
    public let id: UUID
    public let conversationId: UUID
    public let role: MessageRole
    public let content: String
    public let createdAt: Date

    public init(id: UUID, conversationId: UUID, role: MessageRole, content: String, createdAt: Date) {
        self.id = id
        self.conversationId = conversationId
        self.role = role
        self.content = content
        self.createdAt = createdAt
    }
}

public struct CodexTask: Codable, Equatable, Sendable {
    public let id: UUID
    public let conversationId: UUID
    public let promptMessageId: UUID
    public let state: TaskState
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: UUID,
        conversationId: UUID,
        promptMessageId: UUID,
        state: TaskState,
        createdAt: Date,
        updatedAt: Date,
    ) {
        self.id = id
        self.conversationId = conversationId
        self.promptMessageId = promptMessageId
        self.state = state
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct TaskEvent: Codable, Equatable, Sendable {
    public let taskId: UUID
    public let sequence: Int
    public let kind: TaskEventKind
    public let summary: String
    public let createdAt: Date

    public init(
        taskId: UUID,
        sequence: Int,
        kind: TaskEventKind,
        summary: String,
        createdAt: Date,
    ) {
        self.taskId = taskId
        self.sequence = sequence
        self.kind = kind
        self.summary = summary
        self.createdAt = createdAt
    }
}
