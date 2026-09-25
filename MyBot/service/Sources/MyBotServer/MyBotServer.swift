import Foundation

@main
enum MyBotServer {
    static func main() async throws {
        let environment = ProcessInfo.processInfo.environment
        let host = environment["MYBOT_HOST"] ?? "127.0.0.1"
        let port = Int(environment["MYBOT_PORT"] ?? "11000") ?? 11000
        let dataDirectory = environment["MYBOT_DATA_DIRECTORY"]
            ?? FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/share/mybot", isDirectory: true).path
        let databasePath = URL(fileURLWithPath: dataDirectory).appendingPathComponent("mybot.sqlite").path
        let store = try MyBotStore(path: databasePath)
        try await buildApplication(store: store, host: host, port: port).runService()
    }
}
