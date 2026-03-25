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

import SWBCore
import SWBTaskConstruction
import SWBMacro
import SWBUtil

class PlaygroundEntryPointTaskProducer: PhasedTaskProducer, TaskProducer {
    func generateTasks() async -> [any PlannedTask] {
        var tasks: [any PlannedTask] = []
        if context.settings.globalScope.evaluate(BuiltinMacros.GENERATE_PLAYGROUND_ENTRY_POINT) {
            await self.appendGeneratedTasks(&tasks) { delegate in
                let scope = context.settings.globalScope
                let outputPath = scope.evaluate(BuiltinMacros.GENERATED_PLAYGROUND_ENTRY_POINT_PATH)

                guard let configuredTarget = context.configuredTarget else {
                    context.error("Cannot generate a playground entry point without a target")
                    return
                }
                var linkerFileLists: OrderedSet<Path> = []
                var binaryPaths: OrderedSet<Path> = []
                for directDependency in context.globalProductPlan.dependencies(of: configuredTarget) {
                    let settings = context.globalProductPlan.getTargetSettings(directDependency)

                    for arch in settings.globalScope.evaluate(BuiltinMacros.ARCHS) {
                        for variant in settings.globalScope.evaluate(BuiltinMacros.BUILD_VARIANTS) {
                            let innerScope = settings.globalScope
                                .subscopeBindingArchAndTriple(arch: arch)
                                .subscope(binding: BuiltinMacros.variantCondition, to: variant)
                            let linkerFileListPath = innerScope.evaluate(BuiltinMacros.__INPUT_FILE_LIST_PATH__)
                            if !linkerFileListPath.isEmpty {
                                linkerFileLists.append(linkerFileListPath)
                            }

                            let binaryPath = innerScope.evaluate(BuiltinMacros.TARGET_BUILD_DIR).join(innerScope.evaluate(BuiltinMacros.EXECUTABLE_PATH)).normalize()
                            binaryPaths.append(binaryPath)
                        }
                    }
                }

                let inputs: [FileToBuild] = linkerFileLists.map { FileToBuild(absolutePath: $0, fileType: self.context.workspaceContext.core.specRegistry.getSpec("text") as! FileTypeSpec) } + binaryPaths.map { FileToBuild(absolutePath: $0, fileType: self.context.workspaceContext.core.specRegistry.getSpec("compiled.mach-o") as! FileTypeSpec) }

                let cbc = CommandBuildContext(producer: context, scope: scope, inputs: inputs, outputs: [outputPath])
                await context.playgroundEntryPointGenerationToolSpec.constructTasks(cbc, delegate)
            }
        }
        return tasks
    }
}

extension TaskProducerContext {
    var playgroundEntryPointGenerationToolSpec: PlaygroundEntryPointGenerationToolSpec {
        return workspaceContext.core.specRegistry.getSpec(PlaygroundEntryPointGenerationToolSpec.identifier, domain: domain) as! PlaygroundEntryPointGenerationToolSpec
    }
}
