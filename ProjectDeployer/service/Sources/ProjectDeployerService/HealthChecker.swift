import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif
#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

struct HealthChecker: Sendable {
    func check(
        _ healthCheck: DeploymentManifest.HealthCheck,
        hostPort: Int,
    ) async -> Bool {
        switch healthCheck.type {
        case .http:
            await checkHTTP(healthCheck, hostPort: hostPort)
        case .tcp:
            checkTCP(healthCheck, hostPort: hostPort)
        }
    }

    private func checkHTTP(
        _ healthCheck: DeploymentManifest.HealthCheck,
        hostPort: Int,
    ) async -> Bool {
        guard let path = healthCheck.path,
              let url = URL(string: "http://127.0.0.1:\(hostPort)\(path)")
        else {
            return false
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = TimeInterval(healthCheck.timeoutSeconds)
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                return false
            }
            return (200 ..< 400).contains(response.statusCode)
        } catch {
            return false
        }
    }

    private func checkTCP(
        _ healthCheck: DeploymentManifest.HealthCheck,
        hostPort: Int,
    ) -> Bool {
        #if os(Linux)
            let descriptor = socket(AF_INET, Int32(SOCK_STREAM.rawValue), 0)
        #else
            let descriptor = socket(AF_INET, SOCK_STREAM, 0)
        #endif
        guard descriptor >= 0 else {
            return false
        }
        defer {
            #if os(Linux)
                _ = Glibc.close(descriptor)
            #else
                _ = Darwin.close(descriptor)
            #endif
        }

        var timeout = timeval(tv_sec: healthCheck.timeoutSeconds, tv_usec: 0)
        _ = withUnsafePointer(to: &timeout) { pointer in
            setsockopt(
                descriptor,
                SOL_SOCKET,
                SO_SNDTIMEO,
                pointer,
                socklen_t(MemoryLayout<timeval>.size),
            )
        }

        var address = sockaddr_in()
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = in_port_t(UInt16(hostPort).bigEndian)
        let parsed = "127.0.0.1".withCString { value in
            inet_pton(AF_INET, value, &address.sin_addr)
        }
        guard parsed == 1 else {
            return false
        }
        let result = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { socketAddress in
                connect(
                    descriptor,
                    socketAddress,
                    socklen_t(MemoryLayout<sockaddr_in>.size),
                )
            }
        }
        return result == 0
    }
}
