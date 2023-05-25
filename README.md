# Xcode Project Manager

## Overview

This tool aims at making Xcode project easier to setup, build and even run in terminal, providing convenience for both manually usage and interacting with other programs.

Specifically, xpm makes the most commonly used commands easier to execute. Examples:

* You can simply run `xpm build` now to avoid typing the very very long `xcodebuild -workspace XPM.xcworkspace -scheme xpm -configuration Debug -sdk iphoneos build` command each time you build, instead xpm will remember the default option you choose by writing to a config file locally or globally, it will even guess the options first time you run it.

## Usage

`Xcode Project Manager` provides the following features as subcommands:

* install
* build
* deploy
* config
* run

### xpm install

equals to `bundle install && bundle exec pod install` in cocoapods mode.

### xpm build
