//
//  XcodebuildService.swift
//
//
//  Created by Saafo on 2023/8/22.
//

import Foundation
import ArgumentParser // ValidationError

enum XcodebuildService {

    static func updateConfig(
        workspace: String?,
        project: String?,
        scheme: String?,
        configuration: ConfigModel.Build.Xcodebuild.Configuration?,
        sdk: ConfigModel.Build.Xcodebuild.SDK?,
        logLevel: ConfigModel.Build.Xcodebuild.LogLevel?,
        noBeautify: Bool,
        generateBuildServerFile: Bool,
        continueBuildingAfterErrors: Bool,
        saveOptions: SaveOptions
    ) async throws {
        var config = try await ConfigService.config
        let shouldSave = saveOptions.shouldSave(autoSave: config.config.autoChange)

        if let workspace {
            config.build.xcodebuild.workspace = workspace
        }
        if let project {
            config.build.xcodebuild.project = project
        }
        if config.build.xcodebuild.workspace == nil, config.build.xcodebuild.project == nil {
            async let defaultWorkspace = XcodeprojService.findDefaultWorkspace()
            async let defaultProject = XcodeprojService.findDefaultProject()
            if let defaultWorkspace = try await defaultWorkspace {
                config.build.xcodebuild.workspace = defaultWorkspace
                Log.info("Use \(defaultWorkspace) as default workspace")
            }
            if let defaultProject = try await defaultProject {
                config.build.xcodebuild.project = defaultProject
                Log.info("Use \(defaultProject) as default project")
            }
            if config.build.xcodebuild.workspace == nil, config.build.xcodebuild.project == nil {
                throw ValidationError(tint: "Neither configured, nor found any available workspace or project in current folder")
            }
        }
        if let scheme {
            config.build.xcodebuild.scheme = scheme
        }
        if config.build.xcodebuild.scheme == nil {
            config.build.xcodebuild.scheme = try await XcodeprojService.findDefaultScheme(of: config.build.xcodebuild.project)
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

        ConfigService.updateRuntimeConfig(config)

        if shouldSave {
            Task { [config] in
                try await ConfigService.updateLocalConfig(config)
            }
        }
    }

    static var commonBuildParameters: String {
        get async throws {
            let config = try await ConfigService.config.build.xcodebuild
            var parameters = ""
            if let workspace = config.workspace {
                parameters += "-workspace \(workspace)"
            } else if let project = config.project {
                parameters += " -project \(project)"
            }
            if let scheme = config.scheme {
                parameters += " -scheme \(scheme)"
            }
            parameters += " -configuration \(config.configuration.commandValue)"
            parameters += " -sdk \(config.sdk.parameterName)"
            if config.continueBuildingAfterErrors {
                parameters += " -IDEBuildingContinueBuildingAfterErrors=YES"
            }
            return parameters
        }
    }

    static var derivedDataPath: String {
        get async throws {
            let config = try await ConfigService.config.build.xcodebuild
            let projectCommand: String
            if let workspace = config.workspace {
                projectCommand = "-workspace \(workspace)"
            } else if let project = config.project {
                projectCommand = "-project \(project)"
            } else {
                throw ValidationError(tint: "No workspace or project configured, please specify one.")
            }
            guard let scheme = config.scheme else {
                throw ValidationError(tint: "No scheme configured, please specify one.")
            }

            let filterCommand = #"grep -m 1 "BUILD_DIR" | grep -oEi "\/.*" | sed 's#/Build/Products##'"#
            let command = "xcodebuild \(projectCommand) -scheme \(scheme) -showBuildSettings 2<&1 | \(filterCommand)"
            let derivedDataPath = try await Shell.result(of: command, options: [])
            return derivedDataPath
        }
    }
}
