import Foundation
import Hummingbird
import MyBotCore

public struct HealthResponse: ResponseCodable, Equatable, Sendable {
    public let status: String
    public let service: String
    public let apiVersion: String
}

public struct CapabilitiesResponse: ResponseCodable, Equatable, Sendable {
    public let memoryModes: [MemoryMode]
    public let conversationKinds: [ConversationKind]
    public let codexTransport: String
}

struct CreateLibraryRequest: Decodable, Sendable {
    let name: String
    let agentId: UUID?
    let workspacePath: String
    let memoryMode: MemoryMode
}

struct CreateConversationRequest: Decodable, Sendable {
    let title: String
}

struct SendMessageRequest: Decodable, Sendable {
    let content: String
}

public func buildApplication(
    store: MyBotStore,
    host: String = "127.0.0.1",
    port: Int = 11000,
) -> some ApplicationProtocol {
    let router = Router()
    router.add(middleware: APIErrorMiddleware())
    router.add(middleware: CORSMiddleware(allowOrigin: .all))
    addServiceRoutes(to: router)
    addLibraryRoutes(to: router, store: store)
    addConversationRoutes(to: router, store: store)

    return Application(
        router: router,
        configuration: .init(address: .hostname(host, port: port)),
    )
}

private func addServiceRoutes(to router: Router<BasicRequestContext>) {
    router.get("/health") { _, _ -> HealthResponse in
        HealthResponse(status: "ok", service: "mybot-server", apiVersion: "v1")
    }
    router.get("/api/v1/capabilities") { _, _ -> CapabilitiesResponse in
        CapabilitiesResponse(
            memoryModes: MemoryMode.allCases,
            conversationKinds: [.library, .temporary],
            codexTransport: "mac-agent",
        )
    }
}

private func addLibraryRoutes(to router: Router<BasicRequestContext>, store: MyBotStore) {
    router.get("/api/v1/libraries") { _, _ -> [Library] in
        await store.libraries()
    }
    router.post("/api/v1/libraries") { request, context -> Response in
        let body = try await request.decode(as: CreateLibraryRequest.self, context: context)
        let library = try await store.createLibrary(
            name: body.name,
            agentId: body.agentId,
            workspacePath: body.workspacePath,
            memoryMode: body.memoryMode,
        )
        return try context.responseEncoder.encode(library, from: request, context: context)
    }
    router.get("/api/v1/libraries/:libraryId/conversations") { _, context -> [Conversation] in
        let libraryId = try requireUUID("libraryId", context: context)
        return await store.conversations(libraryId: libraryId)
    }
    router.post("/api/v1/libraries/:libraryId/conversations") { request, context -> Response in
        let libraryId = try requireUUID("libraryId", context: context)
        let body = try await request.decode(as: CreateConversationRequest.self, context: context)
        let conversation = try await store.createConversation(
            libraryId: libraryId,
            title: body.title,
            kind: .library,
        )
        return try context.responseEncoder.encode(conversation, from: request, context: context)
    }
}

private func addConversationRoutes(to router: Router<BasicRequestContext>, store: MyBotStore) {
    router.get("/api/v1/conversations/:conversationId/messages") { _, context -> [ChatMessage] in
        let conversationId = try requireUUID("conversationId", context: context)
        return try await store.messages(conversationId: conversationId)
    }
    router.get("/api/v1/conversations/:conversationId/tasks") { _, context -> [CodexTask] in
        let conversationId = try requireUUID("conversationId", context: context)
        return await store.tasks(conversationId: conversationId)
    }
    router.post("/api/v1/conversations/:conversationId/messages") { request, context -> Response in
        let conversationId = try requireUUID("conversationId", context: context)
        let body = try await request.decode(as: SendMessageRequest.self, context: context)
        let prompt = try await store.enqueuePrompt(conversationId: conversationId, content: body.content)
        return try context.responseEncoder.encode(prompt, from: request, context: context)
    }
}

private func requireUUID(_ name: String, context: BasicRequestContext) throws -> UUID {
    let value = try context.parameters.require(name)
    guard let id = UUID(uuidString: value) else {
        throw APIError(status: .badRequest, code: "invalid_id", message: "The resource id is invalid.")
    }
    return id
}
