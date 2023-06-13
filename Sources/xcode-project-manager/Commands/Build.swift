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
        if config.build.xcodebuild.workspace == nil, config.build.xcodebuild.project == nil {
            async let defaultWorkspace = findDefaultWorkspace()
            async let defaultProject = findDefaultProject()
            if let defaultWorkspace = try await defaultWorkspace {
                config.build.xcodebuild.workspace = defaultWorkspace
                Log.info("Use \(defaultWorkspace) as default workspace")
            }
            if let defaultProject = try await defaultProject {
                config.build.xcodebuild.project = defaultProject
                Log.info("Use \(defaultProject) as default project")
            }
            if config.build.xcodebuild.workspace == nil, config.build.xcodebuild.project == nil {
                throw ValidationError("Neither configured, nor found any available workspace or project in current folder")
            }
        }
        if let scheme {
            config.build.xcodebuild.scheme = scheme
        }
        if config.build.xcodebuild.scheme == nil {
            config.build.xcodebuild.scheme = try await findDefaultScheme(of: config.build.xcodebuild.project)
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
        guard let config = ConfigCenter.config else {
            Log.error("Config not init")
            return
        }
        switch config.build.mode {
        case .xcodebuild:
            try await xcodeBuild(with: config.build.xcodebuild)
        }
    }

    private func xcodeBuild(with config: ConfigModel.Build.Xcodebuild) async throws {
        var command = "xcrun xcodebuild"
        // TODO: move to ConfigModel
        if let workspace = config.workspace {
            command += " -workspace \(workspace)"
        } else if let project = config.project {
            command += " -project \(project)"
        }
        if let scheme = config.scheme {
            command += " -scheme \(scheme)"
        }
        command += " -configuration \(config.configuration.commandValue)"
        command += " -sdk \(config.sdk.rawValue)"
        if config.continueBuildingAfterErrors {
            command += " -IDEBuildingContinueBuildingAfterErrors=YES"
        }
        command += " build"
        Log.debug("Executing: \(command)")
        let output = try ShellExecutor.run(command)
    }

    private func findDefaultWorkspace() async throws -> String? {
        let fileManager = FileManager.default
        let workspaces = try fileManager
            .contentsOfDirectory(atPath: fileManager.currentDirectoryPath)
            .filter({ $0.hasSuffix(".xcworkspace")})
        switch workspaces.count {
        case 0:
            return nil
        case 1:
            return workspaces.first
        default:
            throw ValidationError("Found multiple workspaces in current folder, can't decide default workspace.\n"
                                  + "workspaces: \(workspaces)")
        }
    }

    private func findDefaultProject() async throws -> String? {
        let fileManager = FileManager.default
        let workspaces = try fileManager
            .contentsOfDirectory(atPath: fileManager.currentDirectoryPath)
            .filter({ $0.hasSuffix(".xcodeproj")})
        switch workspaces.count {
        case 0:
            return nil
        case 1:
            return workspaces.first
        default:
            throw ValidationError("Found multiple projects in current folder, can't decide default project.\n"
                                  + "projects: \(workspaces)")
        }
    }

    private func findDefaultScheme(of project: String?) async throws -> String {
        guard let project else {
            throw ValidationError("Cannot find default scheme because no project found")
        }
        // TODO: can we not depend on `Xcodeproj`?
        guard let output = try await ShellExecutor
            .run(#"bundle exec ruby -e "require 'xcodeproj'; print(Xcodeproj::Project.open('\#(project)').root_object.targets.first)""#)
            .first(where: { _ in true }) else {
            Log.error("Cannot decide default scheme from project \(project)")
            throw ExitCode.failure
        }
        switch output {
        case .line(let firstTarget):
            return firstTarget
        case .errorLine(let errorMsg):
            Log.error("Finding default scheme, but encountered an error: \(errorMsg)")
            throw ExitCode.failure
        }
    }
}
