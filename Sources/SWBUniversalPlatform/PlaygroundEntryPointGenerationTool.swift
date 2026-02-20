//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SWBUtil
import SWBMacro
import SWBCore

final class PlaygroundEntryPointGenerationToolSpec: GenericCommandLineToolSpec, SpecIdentifierType, @unchecked Sendable {
    static let identifier = "org.swift.playground-entry-point-generator"

    override func commandLineFromTemplate(_ cbc: CommandBuildContext, _ delegate: any TaskGenerationDelegate, optionContext: (any DiscoveredCommandLineToolSpecInfo)?, specialArgs: [String] = [], lookup: ((MacroDeclaration) -> MacroExpression?)? = nil) async -> [CommandLineArgument] {
        var args = await super.commandLineFromTemplate(cbc, delegate, optionContext: optionContext, specialArgs: specialArgs, lookup: lookup)
        return args
    }

    override func createTaskAction(_ cbc: CommandBuildContext, _ delegate: any TaskGenerationDelegate) -> (any PlannedTaskAction)? {
        PlaygroundEntryPointGenerationTaskAction()
    }

    public func constructTasks(_ cbc: CommandBuildContext, _ delegate: any TaskGenerationDelegate, indexStorePaths: [Path], indexUnitBasePaths: [Path]) async {
        var commandLine = await commandLineFromTemplate(cbc, delegate, optionContext: nil)

        delegate.createTask(
            type: self,
            dependencyData: nil,
            payload: nil,
            ruleInfo: defaultRuleInfo(cbc, delegate),
            additionalSignatureData: "",
            commandLine: commandLine,
            additionalOutput: [],
            environment: environmentFromSpec(cbc, delegate),
            workingDirectory: cbc.producer.defaultWorkingDirectory,
            inputs: cbc.inputs.map { delegate.createNode($0.absolutePath) },
            outputs: cbc.outputs.map { delegate.createNode($0) },
            mustPrecede: [],
            action: createTaskAction(cbc, delegate),
            execDescription: resolveExecutionDescription(cbc, delegate),
            preparesForIndexing: true,
            enableSandboxing: enableSandboxing,
            llbuildControlDisabled: true,
            additionalTaskOrderingOptions: []
        )
    }
}
