//
//  Log.swift
//  
//
//  Created by Saafo on 2023/6/8.
//

import Foundation

enum Log {

    static func error(_ message: String) {
        print("❌", message.tint(with: .red))
    }

    static func warning(_ message: String) {
        print("⚠️", message.tint(with: .yellow))
    }

    static func info(_ message: String) {
        print("ℹ", message)
    }

    static func debug(_ message: String) {
        print(message.tint(with: .magenta))
    }

}

extension String {
    func tint(with color: CLColor) -> String {
        "\(color.rawValue)\(self)\(CLColor.reset.rawValue)"
    }
}

enum CLColor: String {
    case reset = "\u{001B}[0;0m"
    case black = "\u{001B}[0;30m"
    case red = "\u{001B}[0;31m"
    case green = "\u{001B}[0;32m"
    case yellow = "\u{001B}[0;33m"
    case blue = "\u{001B}[0;34m"
    case magenta = "\u{001B}[0;35m"
    case cyan = "\u{001B}[0;36m"
    case white = "\u{001B}[0;37m"
}
