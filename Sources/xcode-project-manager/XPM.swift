//
//  Config.swift
//
//
//  Created by Saafo on 2023/5/25.
//

import ArgumentParser

@main
struct XPM: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Making Xcode project easier to setup, build and even run in a single command line tool",
        subcommands: [Config.self, Build.self]
    )

    mutating func run() async throws {
        print(try? await ConfigCenter.loadConfig())
    }
}
