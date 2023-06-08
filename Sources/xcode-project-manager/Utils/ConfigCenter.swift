//
//  ConfigCenter.swift
//  
//
//  Created by Saafo on 2023/6/4.
//

import Foundation
import Yams

enum ConfigCenter {

    internal static var config: ConfigModel?

    internal static func loadConfig() async throws -> ConfigModel {
        if let localConfig = try await loadLocalConfig() {
            return localConfig
        } else {
            Log.info("Local config not found, create default local config from global config")
            let globalConfig = try await loadGlobalConfig()
            try await updateLocalConfig(globalConfig)
            return globalConfig
        }
    }

    internal static func updateLocalConfig(_ model: ConfigModel) async throws {
        let encoder = YAMLEncoder()
        let encodedYAML = try encoder.encode(model)
        let data = encodedYAML.data(using: .utf8)
        try data?.write(to: localConfigFilePath)
    }

    private static func loadGlobalConfig() async throws -> ConfigModel {
        let globalConfigFile = globalConfigFilePath
        let globalConfig: ConfigModel
        if FileManager.default.fileExists(atPath: globalConfigFile.path) {
            let data = try Data(contentsOf: globalConfigFile)
            let decoder = YAMLDecoder()
            globalConfig = try decoder.decode(ConfigModel.self, from: data)
        } else {
            globalConfig = try await createDefaultGlobalConfig()
        }
        return globalConfig
    }

    private static func createDefaultGlobalConfig() async throws -> ConfigModel {
        let globalConfigFile = globalConfigFilePath
        Log.info("Global config not found, create default config at \(globalConfigFile)")
        let defaultConfig = ConfigModel()
        let encoder = YAMLEncoder()
        let encodedYAML = try encoder.encode(defaultConfig)
        let data = encodedYAML.data(using: .utf8)
        try data?.write(to: globalConfigFile)
        return defaultConfig
    }

    private static func loadLocalConfig() async throws -> ConfigModel? {
        let localConfigFile = localConfigFilePath
        guard FileManager.default.fileExists(atPath: localConfigFile.path) else {
            return nil
        }
        let data = try Data(contentsOf: localConfigFile)
        let decoder = YAMLDecoder()
        return try decoder.decode(ConfigModel.self, from: data)
    }

    // MARK: - File itself

    private static let configFileName = ".xpm.yml"

    private static var localConfigFilePath: URL {
        let localConfigFile: URL
        let currentDirectoryPath = FileManager.default.currentDirectoryPath
        if #available(macOS 13, *) {
            let currentPath = URL(filePath: currentDirectoryPath)
            localConfigFile = currentPath.appending(component: configFileName)
        } else {
            let currentPath = URL(fileURLWithPath: currentDirectoryPath)
            localConfigFile = currentPath.appendingPathComponent(configFileName)
        }
        return localConfigFile
    }

    private static var globalConfigFilePath: URL {
        let globalConfigFile: URL
        let homeDirectoryForCurrentUser = FileManager.default.homeDirectoryForCurrentUser
        if #available(macOS 13, *) {
            let homePath = URL(filePath: homeDirectoryForCurrentUser.path())
            globalConfigFile = homePath.appending(component: configFileName)
        } else {
            let homePath = URL(fileURLWithPath: homeDirectoryForCurrentUser.path)
            globalConfigFile = homePath.appendingPathComponent(configFileName)
        }
        return globalConfigFile
    }
}
