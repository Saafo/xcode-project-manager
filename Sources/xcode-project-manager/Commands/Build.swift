//
//  Build.swift
//  
//
//  Created by Saafo on 2023/6/4.
//

import ArgumentParser

struct Build: AsyncParsableCommand {
    // MARK: - Project
    @Option
    var workspace: String?

    @Option
    var project: String?

    @Option
    var scheme: String?

    @Option
    var configuration: ConfigModel.Build.Xcodebuild.Configuration?

    @Option
    var sdk: ConfigModel.Build.Xcodebuild.SDK?

    @Option
    var logLevel: ConfigModel.Build.Xcodebuild.LogLevel = .error

    // MARK: - Flags

    @Flag
    var noBeautify: Bool = false

    @Flag
    var generateBuildServerFile: Bool = false

    @Flag
    var continueBuildingAfterErrors: Bool = false

    @OptionGroup
    var saveOptions: SaveOptions

    // MARK: - Errors
    enum Errors: Error {
        case cannotSpecifyWorkspaceAndProjectSimultaneously
    }

    func validate() throws {
        if workspace != nil, project != nil {
            throw Errors.cannotSpecifyWorkspaceAndProjectSimultaneously
        }
        try saveOptions.checkOptionsValid()
    }

    mutating func run() async throws {
        try await updateConfig()
    }

    func updateConfig() async throws {
        var config = try await ConfigCenter.loadConfig()
        let shouldSave = saveOptions.shouldSave(autoSave: config.config.autoChange)
    }
}

