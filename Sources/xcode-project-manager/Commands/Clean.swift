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
        let config = try await ConfigService.config
        switch config.build.mode {
        case .xcodebuild:
            try await cleanXcodeDerivedData(config: config.build.xcodebuild)
        }
    }

    private func cleanXcodeDerivedData(config: ConfigModel.Build.Xcodebuild) async throws {
        let projectName: String
        if let workspace = config.workspace {
            projectName = workspace
        } else if let project = config.project {
            projectName = project
        } else {
            projectName = "nil"
        }
        let derivedDataPath = try await XcodebuildService.derivedDataPath

        Log.warning("""
will move DerivedData folder of current project(\(projectName)) to trash:
\(try await Shell.result(of: "du -sh \(derivedDataPath)", options: []))
""")
        try FileManager.default.trashItem(at: URL(fileURLWithPath: derivedDataPath), resultingItemURL: nil)
    }
}
