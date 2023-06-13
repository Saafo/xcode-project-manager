//
//  Build.swift
//  
//
//  Created by Saafo on 2023/6/4.
//

import ArgumentParser
import Foundation // ProcessInfo

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

    func validate() throws {
        if workspace != nil, project != nil {
            throw ValidationError("Cannot specify workspace and project simultaneously")
        }
        try saveOptions.checkOptionsValid()
    }

    mutating func run() async throws {
        try await updateConfig()
        try await build()
    }

    private func updateConfig() async throws {
        var config = try await ConfigCenter.loadConfig()
        let shouldSave = saveOptions.shouldSave(autoSave: config.config.autoChange)

        if let workspace {
            config.build.xcodebuild.workspace = workspace
        }
        if let project {
            config.build.xcodebuild.project = project
        }
        if let scheme {
            config.build.xcodebuild.scheme = scheme
        }
        if let configuration {
            config.build.xcodebuild.configuration = configuration
        }
        if let sdk {
            config.build.xcodebuild.sdk = sdk
        }
        if let logLevel {
            config.build.xcodebuild.logLevel = logLevel
        }
        if noBeautify {
            config.build.xcodebuild.noBeautify = noBeautify
        }
        if generateBuildServerFile {
            config.build.xcodebuild.generateBuildServerFile = generateBuildServerFile
        }
        if continueBuildingAfterErrors {
            config.build.xcodebuild.continueBuildingAfterErrors = continueBuildingAfterErrors
        }

        ConfigCenter.config = config

        if shouldSave {
            Task { [config] in
                try await ConfigCenter.updateLocalConfig(config)
            }
        }
    }

    private func build() async throws {
        let shell = ProcessInfo.processInfo.environment["SHELL"]
    }
}

