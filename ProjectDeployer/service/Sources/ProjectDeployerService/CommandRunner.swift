import Foundation
#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#endif

struct CommandResult: Equatable, Sendable {
    let exitCode: Int32
    let standardOutput: String
    let standardError: String

    var succeeded: Bool {
        exitCode == 0
    }
}

struct CommandError: Error, CustomStringConvertible, Sendable {
    let command: String
    let exitCode: Int32
    let detail: String

    var description: String {
        "\(command) exited with code \(exitCode): \(detail)"
    }
}

actor CommandRunner {
    private let temporaryDirectory: URL
    private let outputLimit = 2 * 1024 * 1024

    init(temporaryDirectory: URL) throws {
        self.temporaryDirectory = temporaryDirectory
        try FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true,
        )
    }

    func run(
        executable: String,
        arguments: [String],
        currentDirectory: URL? = nil,
        environment overrides: [String: String] = [:],
    ) async throws -> CommandResult {
        guard executable.hasPrefix("/"), FileManager.default.isExecutableFile(atPath: executable) else {
            throw CommandError(command: executable, exitCode: -1, detail: "Executable is unavailable.")
        }

        let identifier = UUID().uuidString.lowercased()
        let standardOutputURL = temporaryDirectory.appendingPathComponent("\(identifier).stdout")
        let standardErrorURL = temporaryDirectory.appendingPathComponent("\(identifier).stderr")
        _ = FileManager.default.createFile(atPath: standardOutputURL.path, contents: nil)
        _ = FileManager.default.createFile(atPath: standardErrorURL.path, contents: nil)
        defer {
            try? FileManager.default.removeItem(at: standardOutputURL)
            try? FileManager.default.removeItem(at: standardErrorURL)
        }

        let standardOutputHandle = try FileHandle(forWritingTo: standardOutputURL)
        let standardErrorHandle = try FileHandle(forWritingTo: standardErrorURL)
        defer {
            try? standardOutputHandle.close()
            try? standardErrorHandle.close()
        }

        let process = Self.makeProcess(
            executable: executable,
            arguments: arguments,
            currentDirectory: currentDirectory,
            environment: overrides,
            outputHandles: (standardOutputHandle, standardErrorHandle),
        )

        let runningProcess = RunningProcess()
        let exitCode = try await Self.execute(process, state: runningProcess)

        try standardOutputHandle.synchronize()
        try standardErrorHandle.synchronize()
        let standardOutput = try readTail(of: standardOutputURL)
        let standardError = try readTail(of: standardErrorURL)
        return CommandResult(
            exitCode: exitCode,
            standardOutput: standardOutput,
            standardError: standardError,
        )
    }

    func requireSuccess(
        executable: String,
        arguments: [String],
        currentDirectory: URL? = nil,
        environment: [String: String] = [:],
    ) async throws -> CommandResult {
        let result = try await run(
            executable: executable,
            arguments: arguments,
            currentDirectory: currentDirectory,
            environment: environment,
        )
        guard result.succeeded else {
            let detail = result.standardError.isEmpty ? result.standardOutput : result.standardError
            throw CommandError(
                command: URL(fileURLWithPath: executable).lastPathComponent,
                exitCode: result.exitCode,
                detail: detail.trimmingCharacters(in: .whitespacesAndNewlines),
            )
        }
        return result
    }

    private func readTail(of url: URL) throws -> String {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let size = (attributes[.size] as? NSNumber)?.uint64Value ?? 0
        let start = size > outputLimit ? size - UInt64(outputLimit) : 0
        let handle = try FileHandle(forReadingFrom: url)
        defer {
            try? handle.close()
        }
        try handle.seek(toOffset: start)
        let data = try handle.readToEnd() ?? Data()
        return String(bytes: data, encoding: .utf8) ?? ""
    }

    private static func makeProcess(
        executable: String,
        arguments: [String],
        currentDirectory: URL?,
        environment: [String: String],
        outputHandles: (standardOutput: FileHandle, standardError: FileHandle),
    ) -> Process {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.currentDirectoryURL = currentDirectory
        process.standardOutput = outputHandles.standardOutput
        process.standardError = outputHandles.standardError
        process.environment = ProcessInfo.processInfo.environment.merging(environment) { _, newValue in
            newValue
        }
        return process
    }

    private static func execute(_ process: Process, state: RunningProcess) async throws -> Int32 {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                process.terminationHandler = { completedProcess in
                    state.finish()
                    continuation.resume(returning: completedProcess.terminationStatus)
                }
                do {
                    try state.start(process)
                } catch {
                    state.finish()
                    continuation.resume(throwing: error)
                }
            }
        } onCancel: {
            state.cancel()
        }
    }
}

private final class RunningProcess: @unchecked Sendable {
    private let lock = NSLock()
    private var process: Process?
    private var isCancelled = false

    func start(_ process: Process) throws {
        lock.lock()
        defer {
            lock.unlock()
        }
        guard !isCancelled else {
            throw CancellationError()
        }
        self.process = process
        try process.run()
    }

    func cancel() {
        lock.lock()
        isCancelled = true
        let activeProcess = process
        lock.unlock()
        if let activeProcess {
            Self.terminate(activeProcess)
        }
    }

    func finish() {
        lock.lock()
        defer {
            lock.unlock()
        }
        process = nil
    }

    private static func terminate(_ process: Process) {
        #if canImport(Darwin)
            _ = Darwin.kill(process.processIdentifier, SIGTERM)
        #elseif canImport(Glibc)
            _ = Glibc.kill(process.processIdentifier, SIGKILL)
        #endif
    }
}
