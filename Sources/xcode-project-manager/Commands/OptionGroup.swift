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

    func checkOptionsValid() throws {
        if save, noSave {
            throw ValidationError("Cannot specify `--save` and `--no-save` simultaneously")
        }
    }

    func shouldSave(autoSave: Bool) -> Bool {
        autoSave ? !noSave : save
    }
}
