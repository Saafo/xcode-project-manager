//
//  OptionGroup.swift
//  
//
//  Created by Saafo on 2023/6/7.
//

import ArgumentParser

struct SaveOptions: ParsableArguments {
    @Flag
    var save: Bool = false

    @Flag
    var noSave: Bool = false

    enum Errors: Error {
        case cannotSpecifySaveAndNoSaveSimultaneously
    }

    func checkOptionsValid() throws {
        if save, noSave {
            throw Errors.cannotSpecifySaveAndNoSaveSimultaneously
        }
    }

    func shouldSave(autoSave: Bool) -> Bool {
        autoSave ? !noSave : save
    }
}
