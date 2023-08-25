//
//  Print.swift
//
//
//  Created by Saafo on 2023/8/21.
//

import Foundation
import ArgumentParser

struct Print: AsyncParsableCommand {
    enum Content: String, CaseIterable, ExpressibleByArgument {
        case derivedDataPath, d
        case productPath, p
        case commonBuildParameters, b
    }

    @Argument(help: """
        Current valid content includes(Long - Short form):
        \(Content.allValueStrings)
        """)
    var content: Content

    func run() async throws {
        switch content {
        case .derivedDataPath, .d:
            print(try await XcodebuildService.derivedDataPath)
        case .productPath, .p:
            print(try await XcodebuildService.productPath)
        case .commonBuildParameters, .b:
            print(try await XcodebuildService.commonBuildParameters)
        }
    }
}
