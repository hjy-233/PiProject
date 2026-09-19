import Hummingbird

@main
struct ProjectDeployerService {
    static func main() async throws {
        let configuration = try ServiceConfiguration()
        let application = buildApplication(configuration: configuration)
        try await application.runService()
    }
}
