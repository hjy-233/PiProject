import Foundation
import Hummingbird
import HummingbirdTesting
import MyBotCore
@testable import MyBotServer
import Testing

@Suite("MyBot server", .serialized)
struct ApplicationTests {
    @Test("health endpoint identifies the service")
    func health() async throws {
        let application = try buildApplication(store: MyBotStore(path: ":memory:"))
        try await application.test(.router) { client in
            try await client.execute(uri: "/health", method: .get) { response in
                #expect(response.status == .ok)
                let value = try JSONDecoder().decode(HealthResponse.self, from: response.body)
                #expect(value.service == "mybot-server")
                #expect(value.apiVersion == "v1")
            }
        }
    }

    @Test("capabilities expose supported conversation and memory modes")
    func capabilities() async throws {
        let application = try buildApplication(store: MyBotStore(path: ":memory:"))
        try await application.test(.router) { client in
            try await client.execute(uri: "/api/v1/capabilities", method: .get) { response in
                #expect(response.status == .ok)
                let value = try JSONDecoder().decode(CapabilitiesResponse.self, from: response.body)
                #expect(value.memoryModes == MemoryMode.allCases)
                #expect(value.conversationKinds == [.library, .temporary])
                #expect(value.codexTransport == "mac-agent")
            }
        }
    }

    @Test("library conversation and prompt persist through the API")
    func conversationFlow() async throws {
        let application = try buildApplication(store: MyBotStore(path: ":memory:"))
        try await application.test(.router) { client in
            let library = try await client.execute(
                uri: "/api/v1/libraries",
                method: .post,
                headers: [.contentType: "application/json"],
                body: ByteBuffer(
                    string: #"{"name":"PiProject","workspacePath":"/tmp/project","memoryMode":"codexDefault"}"#,
                ),
            ) { response in
                #expect(response.status == .ok)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(Library.self, from: response.body)
            }
            let conversation = try await client.execute(
                uri: "/api/v1/libraries/\(library.id)/conversations",
                method: .post,
                headers: [.contentType: "application/json"],
                body: ByteBuffer(string: #"{"title":"First task"}"#),
            ) { response in
                #expect(response.status == .ok)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(Conversation.self, from: response.body)
            }
            try await client.execute(
                uri: "/api/v1/conversations/\(conversation.id)/messages",
                method: .post,
                headers: [.contentType: "application/json"],
                body: ByteBuffer(string: #"{"content":"Inspect the repository"}"#),
            ) { response in
                #expect(response.status == .ok)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let value = try decoder.decode(PromptResponse.self, from: response.body)
                #expect(value.task.state == .queued)
                #expect(value.message.content == "Inspect the repository")
            }
        }
    }

    @Test("libraries survive reopening the database")
    func databasePersistence() async throws {
        let databaseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("mybot-test-\(UUID().uuidString).sqlite")
        defer { try? FileManager.default.removeItem(at: databaseURL) }

        let firstStore = try MyBotStore(path: databaseURL.path)
        _ = try await firstStore.createLibrary(
            name: "Persistent library",
            agentId: nil,
            workspacePath: "/tmp/persistent",
            memoryMode: .library,
        )

        let reopenedStore = try MyBotStore(path: databaseURL.path)
        let libraries = await reopenedStore.libraries()
        #expect(libraries.count == 1)
        #expect(libraries.first?.name == "Persistent library")
    }
}
