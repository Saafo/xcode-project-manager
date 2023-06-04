# Xcode Project Manager

## Overview

`Xcode Project Manager` aims at making Xcode project easier to setup, build and even run in a single command line tool. It providing convenience for both manually usage and interacting with other programs.

Specifically, `xpm` makes the most commonly used commands easier to execute. Examples:

- You can simply run `xpm build` now to avoid typing the very very long `xcodebuild -workspace XPM.xcworkspace -scheme xpm -configuration Debug -sdk iphoneos build` command each time you build. `xpm` will remember the default option you choose by writing to a config file locally or globally, it will even guess the options first time you run it.
- You can simply run `xpm install` instead of `bundle install && bundle exec pod install`.

## Usage

`Xcode Project Manager` provides the following features as subcommands:

- config
- install
- build
- docbuild
- run
- exec
- print

### xpm config

`xpm` will **automatically generate** a `.xpm.yml` file to pwd when first time you use `xpm` in your project. The configs with default values available are listed as follows:

```yaml
config:
  autoChange: true # whether change this file when executing commands with different configs
install:
  mode: cocoapods # maybe carthage, spm will be supported in the future
build:
  mode: xcodebuild # maybe bazel will be supported in the future
  xcodebuild:
    workspace: XPM.xcworkspace # will ask you to pick one at first time
    project: XPM.xcodeproj # will ask you to pick one at first time
    scheme: xpm # will ask you to pick one at first time
    configuration: Debug # or Release
    sdk: iphoneos # or iphonesimulator, etc.
    beautify: true # use xcbeautify or xcpretty to beautify output logs
    logLevel: error # only print logs which level are equal to or more serious than the given value
    generateBuildServerFile: false # use xcode-build-server to generate buildServer.json file
    continueBuildingAfterErrors: false
run:
  type: device # or simulator
  target:
    device: Saafo's iPhone 14 Pro # will ask you to pick one at first time.
    simulator: iPhone 14 Pro # will ask you to pick one at first time.
exec:
  scripts:
    hello: echo 'hello world' # just an example.
```

You can also run `xpm config --local config.autoChange false` to change the config.

And you can also configure some basic configs(like autoChange and mode) at `~/.xpm.yml`. The global config file is used when generating new `.xpm.yml` in your project.

### xpm install

`xpm install` helps to setup your project (like resolving and downloading all dependencies) in a single command.

#### In cocoapods mode

| Commands           | Equals to                                 |
| ------------------ | ----------------------------------------- |
| xpm install        | bundle install && bundle exec pod install |
| xpm install bundle | bundle install                            |
| xpm install pod    | bundle exec pod install                   |

TODO: xpm install bundle is even longer than bundle install.

### xpm build

`xpm build` helps to build your project and shows building logs of specific levels.

#### In xcodebuild mode

When running `xpm build` for the first time, `xpm` will ask you to select default configs and will write to `.xpm.yml` file to pwd. When already having `.xpm.yml`, `xpm` will use the configs in the file.

We know manually input workspace or project or scheme name is kind of pain, so we add completion as you type <tab> when need input them.

Besides, the most different thing is that, you can update configs in the config file through command line instead of manually edit it. A simple process is like:

1. Run `xpm build -sdk ` and press tab, `xpm` will give a list of all available sdks, you can choose one to finish the completion.
2. Currently the command is like `xpm build -sdk iphonesimulator`, and if `config.autoChange` is true and you execute the command, `build.xcodebuild.sdk` will update it's value to `iphonesimulator`(You'll never manually input the long `iphonesimulator` anymore!). You can also add `--no-save` flag to avoid updating the config.
3. Vice versa, when `config.autoChange` is false and you can add `--save` flag to force updating the config.

### xpm docbuild

For DocC documentation generating, similar as xcodebuild docbuild.

### xpm run

`xpm run` mainly aggregating `simctl` and `ios-deploy` for simulator and device running into a single command.

### xpm exec

Used as executing shell scripts configured in `exec.scripts`.

### xpm print

Print basic infomation about the project, used as interacting with other command line tools.
