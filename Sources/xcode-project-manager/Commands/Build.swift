//
//  Build.swift
//  
//
//  Created by Saafo on 2023/6/4.
//

import Foundation
import ArgumentParser

struct Build: AsyncParsableCommand {
    // MARK: - Project
    @Option(name: [.long, .short])
    var workspace: String?

    @Option(name: [.long, .short])
    var project: String?

    @Option(name: [.long, .short])
    var scheme: String?

    @Option(name: [.long, .short])
    var configuration: ConfigModel.Build.Xcodebuild.Configuration?

    @Option
    var sdk: ConfigModel.Build.Xcodebuild.SDK?

    @Option
    var logLevel: ConfigModel.Build.Xcodebuild.LogLevel?

    // MARK: - Flags

    @Flag
    var noBeautify: Bool = false

    @Flag
    var generateBuildServerFile: Bool = false

    @Flag
    var continueBuildingAfterErrors: Bool = false

    // MARK: - OptionGroup

    @OptionGroup
    var saveOptions: SaveOptions

    // MARK: - Command

    func validate() throws {
        if workspace != nil, project != nil {
            throw ValidationError(tint: "Cannot specify workspace and project simultaneously")
        }
        try saveOptions.checkOptionsValid()
    }

    mutating func run() async throws {
        try await updateConfig()
        try await build()
    }

    private func updateConfig() async throws {
        try await XcodebuildService.updateConfig(
            workspace: workspace,
            project: project,
            scheme: scheme,
            configuration: configuration,
            sdk: sdk,
            logLevel: logLevel,
            noBeautify: noBeautify,
            generateBuildServerFile: generateBuildServerFile,
            continueBuildingAfterErrors: continueBuildingAfterErrors,
            saveOptions: saveOptions
        )
    }

    private func build() async throws {
        let buildConfig = try await ConfigService.config.build
        switch buildConfig.mode {
        case .xcodebuild:
            try await checkNecessaryExecs(with: buildConfig.xcodebuild)
            try await xcodeBuild(with: buildConfig.xcodebuild)
        }
    }

    private func checkNecessaryExecs(with config: ConfigModel.Build.Xcodebuild) async throws {
        var execList = [Shell.ExecName.xcrun]
        if !config.noBeautify {
            execList.append(Shell.ExecName.xcbeautify)
        }
        if config.generateBuildServerFile {
            execList.append(Shell.ExecName.buildServer)
        }
        try execList.forEach { exec in
            if Shell.findExecInPath(with: exec) == nil {
                throw ValidationError(tint: "Cannot find \(exec) in PATH")
            }
        }
    }

    private func xcodeBuild(with config: ConfigModel.Build.Xcodebuild) async throws {
        var command = "set -o pipefail && \(Shell.ExecName.xcrun) xcodebuild"
        command += " \(try await XcodebuildService.generalBuildParameters)"
        command += " build"

        let time = Date().formatted(Date
            .ISO8601FormatStyle(timeZone: .current)
            .year().month().day()
            .dateSeparator(.dash)
            .timeSeparator(.colon)
            .time(includingFractionalSeconds: true)
            .timeZone(separator: .omitted)
        )
        let buildLogDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("xpm", isDirectory: true)
            .appendingPathComponent("log", isDirectory: true)
            .appendingPathComponent("build", isDirectory: true)
            .appendingPathComponent(time.description, isDirectory: true)
        try FileManager.default.createDirectory(at: buildLogDir, withIntermediateDirectories: true)
        let rawFilePath = buildLogDir.appendingPathComponent("xcodebuild-raw.log").path
        command += " 2>&1 | tee \(rawFilePath)"

        if config.generateBuildServerFile {
            command += " >(\(Shell.ExecName.buildServer) parse > /dev/null)"
        }

        let beautifyPath = buildLogDir.appendingPathComponent("xcodebuild-beautify.log").path
        if !config.noBeautify {
            command += " | \(Shell.ExecName.xcbeautify) | tee \(beautifyPath)"
        }

        let outputStream = Shell.run(command, options: [.logOn([.start, .end])])
        let printFinishingInfo = {
            Log.info("The original build log is saved at \(rawFilePath), and the beautified log is saved at \(beautifyPath)")
        }
        do {
            for try await output in outputStream {
                // TODO: remove old outputs to only show building tasks
                // TODO: add xcbeautify's quiet and quieter options
                print(output)
            }
        } catch {
            printFinishingInfo()
            throw error
        }
        printFinishingInfo()

    }

}
