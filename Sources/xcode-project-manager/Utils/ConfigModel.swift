//
//  ConfigModel.swift
//  
//
//  Created by Saafo on 2023/6/5.
//

import Foundation
import ArgumentParser

struct ConfigModel: Codable {
    struct Config: Codable {
        var autoChange: Bool = true
    }
    struct Install: Codable {
        enum Mode: String, Codable {
            case cocoapods
        }
        var mode: Mode = .cocoapods
    }
    struct Build: Codable {
        enum Mode: String, Codable {
            case xcodebuild
        }
        var mode: Mode = .xcodebuild
        struct Xcodebuild: Codable {
            var workspace: String?
            var project: String?
            var scheme: String?
            enum Configuration: String, Codable, ExpressibleByArgument {
                case debug, release
            }
            var configuration: Configuration = .debug
            enum SDK: String, Codable, ExpressibleByArgument {
                case iphoneos
                case iphonesimulator
            }
            var sdk: SDK = .iphonesimulator
            var beautify: Bool = true
            enum LogLevel: String, Codable {
                case error, warning, message
            }
            var logLevel: LogLevel = .error
            var generateBuildServerFile: Bool = false
            var continueBuildingAfterErrors: Bool = false
        }
    }
    struct Run: Codable {} // TODO
    struct Exec: Codable {} // TODO

    var config = Config()
    var install = Install()
    var build = Build()
}
