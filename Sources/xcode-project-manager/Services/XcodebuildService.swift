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
        try await updateDefaultWorkspaceOrProjectIfNeeded(config: &config)
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

    static func updateDefaultWorkspaceOrProjectIfNeeded(config: inout ConfigModel) async throws {
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
            parameters += " -sdk \(config.sdk.rawValue)"
            parameters += " -arch \(try await getArchArg(sdk: config.sdk))"
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
            let command = """
                \(Shell.ExecName.xcrun) \(Shell.ExecName.xcodebuild) \(projectCommand) \
                -scheme \(scheme) -showBuildSettings 2<&1 | \(filterCommand)
                """
            let derivedDataPath = try await Shell.result(of: command, options: [])
            return derivedDataPath
        }
    }

    static var productPath: String {
        get async throws {
            let commonParameters = try await commonBuildParameters
            let filterCommand = #"grep -m 1 "CODESIGNING_FOLDER_PATH" | grep -oEi "\/.*""#
            let command = """
                \(Shell.ExecName.xcrun) \(Shell.ExecName.xcodebuild) \
                \(commonParameters) -showBuildSettings 2<&1 | \(filterCommand)
                """
            let productPath = try await Shell.result(of: command, options: [])
            return productPath
        }
    }

    private static func getArchArg(sdk: ConfigModel.Build.Xcodebuild.SDK) async throws -> String {
        switch sdk {
        case .iphoneos:
            return "arm64"
        case .iphonesimulator:
            let archCommand = "machine"
            let currentArch = try await Shell.result(of: archCommand, options: [])
            switch currentArch {
            case "arm64", "arm64e":
                return "arm64"
            default:
                return "x86_64"
            }
        }
    }
}
