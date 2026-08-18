import Foundation
import Testing

struct M66AppGestureSessionSizeBudgetPolicyTests {
    @Test
    func appGestureSessionBudgetRemainsProvenanced() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let budgetURL = repositoryRoot.appendingPathComponent(
            "performance/m6-6-app-gesture-session-size-budget.json"
        )

        let budgetExists = FileManager.default.fileExists(atPath: budgetURL.path)
        #expect(budgetExists)
        guard budgetExists else {
            return
        }

        let budget = try JSONDecoder().decode(
            FeatureBudget.self,
            from: Data(contentsOf: budgetURL)
        )
        #expect(budget.schemaVersion == 1)
        #expect(budget.featureId == "m6.6-app-gesture-session")
        #expect(budget.baselineId == "v0.1.0")
        #expect(budget.evidence.sourceCommit == "3ebbf68a373e32189196b18a11610ec4d2babca9")
        #expect(budget.evidence.workflowRunId == 31_598_200_510)
        #expect(budget.evidence.artifactId == 9_142_119_577)
        #expect(
            budget.evidence.summary
                == SizeSummary(
                    appSizeBytes: 763_662,
                    dmgSizeBytes: 490_395,
                    executableSizeBytes: 461_456
                )
        )
        #expect(
            budget.allowanceBytes
                == SizeSummary(
                    appSizeBytes: 499_712,
                    dmgSizeBytes: 405_504,
                    executableSizeBytes: 200_704
                )
        )
    }

    private struct FeatureBudget: Decodable {
        let schemaVersion: Int
        let featureId: String
        let baselineId: String
        let evidence: Evidence
        let allowanceBytes: SizeSummary
    }

    private struct Evidence: Decodable {
        let sourceCommit: String
        let workflowRunId: Int
        let artifactId: Int
        let summary: SizeSummary
    }

    private struct SizeSummary: Decodable, Equatable {
        let appSizeBytes: Int
        let dmgSizeBytes: Int
        let executableSizeBytes: Int
    }
}
