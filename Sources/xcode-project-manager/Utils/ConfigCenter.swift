//
//  ConfigCenter.swift
//  
//
//  Created by Saafo on 2023/6/4.
//

import Foundation
import Yams

enum ConfigCenter {

    private static let configFileName = ".xpm.yml"

    static func loadConfig() async throws -> ConfigModel {
        let localConfigFile: URL
        if #available(macOS 13, *) {
            let currentPath = URL(filePath: FileManager.default.currentDirectoryPath)
            localConfigFile = currentPath.appending(component: configFileName)
        } else {
            let currentPath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            localConfigFile = currentPath.appendingPathComponent(configFileName)
        }
        let data = try Data(contentsOf: localConfigFile)
        let decoder = YAMLDecoder()
        return try decoder.decode(ConfigModel.self, from: data)
    }
    static func updateConfig(_ model: ConfigModel) async {}
}
