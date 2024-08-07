//
//  ConfigModel.swift
//  
//
//  Created by Saafo on 2023/6/5.
//

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

            enum Configuration: String, Codable {
                case debug, release
                var commandValue: String {
                    rawValue.capitalized
                }
            }
            var configuration: Configuration = .debug

            enum SDK: String {
                case iphoneos
                case iphonesimulator
            }
            var sdk: SDK = .iphonesimulator

            var noBeautify: Bool = false

            enum LogLevel: String, Codable {
                case error, warning, message
            }
            var logLevel: LogLevel = .error
            var generateBuildServerFile: Bool = false
            var continueBuildingAfterErrors: Bool = false
        }
        var xcodebuild = Xcodebuild()
    }

    struct Run: Codable {} // TODO
    struct Exec: Codable {} // TODO

    var config = Config()
    var install = Install()
    var build = Build()
}

extension ConfigModel.Build.Xcodebuild.Configuration: ExpressibleByArgument {}
extension ConfigModel.Build.Xcodebuild.LogLevel: ExpressibleByArgument {}
extension ConfigModel.Build.Xcodebuild.SDK: ExpressibleByArgument, Codable {
    init?(argument: String) {
        switch argument {
        case "ios": self = .iphoneos
        case "isim": self = .iphonesimulator
        default:
            if let instance = Self(rawValue: argument) {
                self = instance
            } else {
                return nil
            }
        }
    }
    init(from decoder: Decoder) throws {
        let stringValue = try decoder.singleValueContainer().decode(String.self)
        if let instance = Self(argument: stringValue) {
            self = instance
        } else {
            throw Error.decodingValueInvalid
        }
    }
    enum Error: Swift.Error {
        case decodingValueInvalid
    }
}
