//
//  ShellExecutor.swift
//  
//
//  Created by Saafo on 2023/6/11.
//

import Foundation

enum ShellExecutor {

    enum Output {
        case line(String)
        case errorLine(String)
    }

    /// Run a shell command
    /// - Parameter command: the command to be run in current shell
    /// - Returns: output async sequence divided by line break
    static func run(_ command: String, input: AsyncStream<String>? = nil) throws -> AsyncStream<Output> {
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        let task = Process()
        let pipe = Pipe()
        let errorPipe = Pipe()

        task.standardOutput = pipe
        task.standardError = errorPipe
        task.arguments = ["-c", command]
        task.launchPath = shell
        if let input {
            let inputPipe = Pipe()
            task.standardInput = inputPipe
            Task {
                do {
                    for await line in input {
                        let data = line.data(using: .utf8) ?? Data()
                        try inputPipe.fileHandleForWriting.write(contentsOf: data)
                    }
                    try inputPipe.fileHandleForWriting.close()
                } catch {
                    Log.error("Run command \(command) with input error: \(error)")
                }
            }
        } else {
            task.standardInput = nil
        }
        try task.run()

        let stream = AsyncStream<Output> { continuation in
            Task {
                do {
                    try await withThrowingTaskGroup(of: Void.self) { group in
                        group.addTask {
                            for try await line in pipe.fileHandleForReading.bytes.lines {
                                continuation.yield(.line(line))
                            }
                        }
                        group.addTask {
                            for try await line in errorPipe.fileHandleForReading.bytes.lines {
                                continuation.yield(.errorLine(line))
                            }
                        }
                        try await group.waitForAll()
                    }
                    continuation.finish()
                } catch {
                    Log.error("Run command \(command) with error: \(error)")
                }
            }
        }

        return stream
    }
}
