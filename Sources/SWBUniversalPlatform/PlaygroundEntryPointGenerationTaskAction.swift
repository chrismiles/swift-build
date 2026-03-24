//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SWBUtil
import SWBCore
import SWBTaskExecution
import ArgumentParser

class PlaygroundEntryPointGenerationTaskAction: TaskAction {
    override class var toolIdentifier: String {
        "PlaygroundEntryPointGenerationTaskAction"
    }

    override func performTaskAction(_ task: any ExecutableTask, dynamicExecutionDelegate: any DynamicTaskExecutionDelegate, executionDelegate: any TaskExecutionDelegate, clientDelegate: any TaskExecutionClientDelegate, outputDelegate: any TaskOutputDelegate) async -> CommandResult {
        do {
            let options = try Options.parse(Array(task.commandLineAsStrings.dropFirst()))

            try executionDelegate.fs.write(options.output, contents: ByteString(encodingAsUTF8: """
            import Foundation
            import Playgrounds

            @main
            struct Runner {
                static func main() async {
                    await Playgrounds.__swiftPlayEntryPoint(CommandLine.arguments)
                }
            }
            """))

            return .succeeded
        } catch {
            outputDelegate.emitError("\(error)")
            return .failed
        }
    }

    private struct Options: ParsableArguments {
        @Option var output: Path
    }
}
