//
//  Extensions.swift
//  
//
//  Created by Saafo on 2023/8/22.
//

import Foundation
import ArgumentParser

extension ValidationError {
    init(tint message: String) {
        self.init(message.tint(with: .red))
    }
}
