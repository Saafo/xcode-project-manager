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

            enum SDK: String, Codable {
                case iphoneos, ios
                case iphonesimulator, isim
                var parameterName: String {
                    switch self {
                    case .iphoneos, .ios: return "iphoneos"
                    case .iphonesimulator, .isim: return "iphonesimulator"
                    }
                }
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
extension ConfigModel.Build.Xcodebuild.SDK: ExpressibleByArgument {}
extension ConfigModel.Build.Xcodebuild.LogLevel: ExpressibleByArgument {}
