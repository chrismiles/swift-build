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

import Testing
import SWBCore
import SWBProtocol
import SWBTestSupport
import SWBUtil
import Foundation

@Suite(.requireXcode16())
fileprivate struct PlaygroundEntryPointTaskConstructionTests: CoreBasedTests {

    // MARK: Playground runner target

    @Test(.requireSDKs(.host))
    func playgroundRunnerTarget() async throws {
        let swiftCompilerPath = try await self.swiftCompilerPath
        let swiftVersion = try await self.swiftVersion
        let testProject = TestProject(
            "aProject",
            groupTree: TestGroup(
                "SomeFiles",
                children: [
                    TestFile("Playground.swift"),
                ]),
            buildConfigurations: [
                TestBuildConfiguration(
                    "Debug",
                    buildSettings: [
                        "CODE_SIGN_IDENTITY": "",
                        "CODE_SIGNING_ALLOWED": "NO",
                        "PRODUCT_NAME": "$(TARGET_NAME)",
                        "SDKROOT": "auto",
                        "SWIFT_VERSION": swiftVersion,
                        "INDEX_DATA_STORE_DIR": "/index",
                        "LINKER_DRIVER": "swiftc",
                    ])
            ],
            targets: [
                TestStandardTarget(
                    "PlaygroundRunner",
                    type: .swiftpmPlaygroundRunner,
                    buildConfigurations: [
                        TestBuildConfiguration("Debug")
                    ],
                    buildPhases: [
                        TestSourcesBuildPhase([
                            "Playground.swift"
                        ]),
                        TestFrameworksBuildPhase([]),
                    ],
                    dependencies: [],
                ),
            ])
        let core = try await getCore()
        let tester = try TaskConstructionTester(core, testProject)
        let SRCROOT = tester.workspace.projects[0].sourceRoot.str

        let fs = PseudoFS()

        try await fs.writeFileContents(swiftCompilerPath) { $0 <<< "binary" }

        await tester.checkBuild(runDestination: .host, fs: fs) { results in
            results.checkTarget("PlaygroundRunner") { target in
                // There should be a playground entry point generation task
                results.checkTask(.matchTarget(target), .matchRuleType("GeneratePlaygroundEntryPoint")) { task in
                    task.checkCommandLineMatches([
                        .suffix("builtin-generatePlaygroundEntryPoint"),
                        "--output",
                        .suffix("playground_entry_point.swift"),
                    ])
                    task.checkOutputs([.pathPattern(.suffix("playground_entry_point.swift"))])
                }

                // The generated playground entry point file should be included in Swift compilation
                results.checkTask(.matchTarget(target), .matchRuleType("SwiftDriver Compilation")) { task in
                    task.checkInputs(contain: [
                        .path("\(SRCROOT)/Playground.swift"),
                        .pathPattern(.suffix("playground_entry_point.swift")),
                    ])
                }

                // There should be a link task
                results.checkTaskExists(.matchTarget(target), .matchRuleType("Ld"))
            }

            results.checkNoDiagnostics()
        }
    }

}
