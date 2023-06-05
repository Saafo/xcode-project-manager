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

    // MARK: - Flags

    @Flag
    var continueBuildingAfterErrors: Bool = false

    @Flag
    var noBeautify: Bool = false

    // MARK: - Errors
    enum Errors: Error {
        case cannotSpecifyWorkspaceAndProjectSimultaneously
    }

    func validate() throws {
        if workspace != nil, project != nil {
            throw Errors.cannotSpecifyWorkspaceAndProjectSimultaneously
        }
    }

    mutating func run() throws {
        print("run")
    }
}

