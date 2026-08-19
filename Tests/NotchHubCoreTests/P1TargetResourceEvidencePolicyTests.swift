import Foundation
import Testing

@Suite("P1 target resource evidence policy")
struct P1TargetResourceEvidencePolicyTests {
    @Test("Python evidence contract runs inside the canonical Swift gate")
    func pythonEvidenceContractRunsInsideCanonicalSwiftGate() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let scriptsDirectory = repositoryRoot.appendingPathComponent("scripts", isDirectory: true)

        let stdout = Pipe()
        let stderr = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [
            "python3",
            "-m",
            "unittest",
            "-v",
            "test_p1_target_resource_evidence.py",
            "test_p1_target_platform_family.py",
            "test_perf_baseline_locale.py"
        ]
        process.currentDirectoryURL = scriptsDirectory
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        let output = String(
            decoding: stdout.fileHandleForReading.readDataToEndOfFile(),
            as: UTF8.self
        )
        let errors = String(
            decoding: stderr.fileHandleForReading.readDataToEndOfFile(),
            as: UTF8.self
        )

        #expect(
            process.terminationStatus == 0,
            "P1 Python evidence tests failed. stdout:\n\(output)\nstderr:\n\(errors)"
        )
    }
}
