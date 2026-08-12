import Foundation
import Testing

struct M66GestureSizeBudgetPolicyTests {
    @Test
    func gestureEngineOwnsAProvenancedFeatureBudgetAndCIUsesIt() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let budgetURL = repositoryRoot
            .appendingPathComponent("performance/m6-6-gesture-engine-size-budget.json")
        let workflowURL = repositoryRoot
            .appendingPathComponent(".github/workflows/ci.yml")

        #expect(FileManager.default.fileExists(atPath: budgetURL.path))

        let workflow = try String(contentsOf: workflowURL, encoding: .utf8)
        #expect(
            workflow.contains(
                "--feature-budget performance/m6-6-gesture-engine-size-budget.json"
            )
        )
        #expect(
            !workflow.contains(
                "--feature-budget performance/m6-6-one-shot-lifecycle-size-budget.json"
            )
        )
    }
}
