import ArgumentParser

@main
struct XCBuild: ParsableCommand {

    // MARK: - Project
    @Option
    var workspace: String?

    @Option
    var project: String?

    @Option
    var scheme: String?

    // MARK: - Flags

    @Flag
    var simulator: Bool = false

    @Flag
    var releaseMode: Bool = false

    @Flag
    var continueBuildingAfterErrors: Bool = false

    @Flag
    var noBeautify: Bool = false

    @Flag
    var pipeToFile: Bool = false

    // MARK: - Errors
    enum Errors: Error {
        case cannotSpecifyWorkspaceAndProjectSimultaneously
    }

    func validate() throws {
        if workspace != nil, project != nil {
            throw Errors.cannotSpecifyWorkspaceAndProjectSimultaneously
        }
    }

    mutating func run() throws {
        print("run")
    }
}
