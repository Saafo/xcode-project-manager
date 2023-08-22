//
//  XcodeprojService.swift
//
//
//  Created by Saafo on 2023/8/22.
//

import XcodeProj // Xcodeproj
import Foundation
import ArgumentParser // ValidationError

enum XcodeprojService {
    static func findDefaultWorkspace() async throws -> String? {
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
            throw ValidationError(tint: "Found multiple workspaces in current folder, can't decide default workspace.\n"
                                  + "workspaces: \(workspaces)")
        }
    }

    static func findDefaultProject() async throws -> String? {
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
            throw ValidationError(tint: "Found multiple projects in current folder, can't decide default project.\n"
                                  + "projects: \(workspaces)")
        }
    }

    static func findDefaultScheme(of project: String?) async throws -> String {
        guard let project else {
            throw ValidationError(tint: "Cannot find default scheme because no project found")
        }
        // FIXME: This approach is not accurate enough.
        let proj = try XcodeProj(pathString: project)
        if let sharedScheme = proj.sharedData?.schemes.first(where: { $0.wasCreatedForAppExtension != true }) {
            return sharedScheme.name
        } else {
            Log.error("Cannot decide default scheme from project \(project)")
            throw ExitCode.failure
        }
    }
}
