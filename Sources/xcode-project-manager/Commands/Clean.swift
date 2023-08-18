//
//  Clean.swift
//
//
//  Created by Saafo on 2023/8/17.
//

import Foundation
import ArgumentParser

struct Clean: AsyncParsableCommand {

    mutating func run() async throws {
        let config = try await ConfigCenter.loadConfig()
        switch config.build.mode {
        case .xcodebuild:
            try await cleanXcodeDerivedData(config: config.build.xcodebuild)
        }
    }

    private func cleanXcodeDerivedData(config: ConfigModel.Build.Xcodebuild) async throws {
        let projectCommand: String
        let projectName: String
        if let workspace = config.workspace {
            projectName = workspace
            projectCommand = "-workspace \(workspace)"
        } else if let project = config.project {
            projectName = project
            projectCommand = "-project \(project)"
        } else {
            throw ValidationError("No workspace or project configured, please specify one.")
        }
        guard let scheme = config.scheme else {
            throw ValidationError("No scheme configured, please specify one.")
        }

        let filterCommand = #"grep -m 1 "BUILD_DIR" | grep -oEi "\/.*" | sed 's#/Build/Products##'"#
        let command = "xcodebuild \(projectCommand) -scheme \(scheme) -showBuildSettings 2<&1 | \(filterCommand)"
        let derivedDataPath = try await Shell.result(of: command, options: [])

        Log.warning("""
will move DerivedData folder of current project(\(projectName)) to trash:
\(try await Shell.result(of: "du -sh \(derivedDataPath)", options: []))
""")
        try FileManager.default.trashItem(at: URL(fileURLWithPath: derivedDataPath), resultingItemURL: nil)
    }
}
