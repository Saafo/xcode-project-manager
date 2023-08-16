//
//  Shell.swift
//  
//
//  Created by Saafo on 2023/6/11.
//

import Foundation

enum Shell {

    private struct Error: Swift.Error {
        var code: Int32
        var message: String
    }

    /// Run a shell command
    /// - Parameter command: the command to be run in current shell
    /// - Returns: output async sequence divided by line break
    static func run(_ command: String) -> AsyncThrowingStream<String, Swift.Error> {
        AsyncThrowingStream<String, Swift.Error> { continuation in
            Task {
                let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
                let task = Process()
                let pipe = Pipe()
                let errorPipe = Pipe()

                task.standardOutput = pipe
                task.standardError = errorPipe
                task.arguments = ["-c", command]
                task.launchPath = shell
                task.terminationHandler = { task in
                    if task.terminationStatus == 0 {
                        continuation.finish()
                    } else {
                        let stdErr = String(data: errorPipe.fileHandleForReading.availableData, encoding: .utf8)
                        let error = Error(code: task.terminationStatus,
                                          message: "Run command '\(command)' failed, stdErr: \(stdErr ?? "nil")")
                        continuation.finish(throwing: error)
                    }
                }

                do {
                    try task.run()

                    for try await line in pipe.fileHandleForReading.bytes.lines {
                        continuation.yield(line)
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    static func result(of command: String) async throws -> String {
        let stream = run(command)
        var result = ""
        for try await line in stream {
            result.append(line + "\n")
        }
        if result.hasSuffix("\n") {
            result.removeLast()
        }
        return result
    }

    static func findExecInPath(with name: String) -> Path? {
        guard let environmentPath = ProcessInfo.processInfo.environment["PATH"] else {
            return nil
        }

        guard let executablePath =
                environmentPath.split(separator: ":").lazy
            .compactMap({ String($0).appending("/").appending(name) })
            .first(where: {
                FileManager.default.isExecutableFile(atPath: $0)
            }) else {
            return nil
        }

        return executablePath
    }
}
