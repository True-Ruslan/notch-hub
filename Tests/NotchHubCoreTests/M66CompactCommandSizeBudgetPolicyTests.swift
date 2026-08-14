import Foundation
import Testing

struct M66CompactCommandSizeBudgetPolicyTests {
    @Test
    func compactCommandDispatcherHistoricalBudgetRemainsProvenanced() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let budgetURL = repositoryRoot.appendingPathComponent(
            "performance/m6-6-compact-command-size-budget.json"
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
        #expect(budget.featureId == "m6.6-compact-command")
        #expect(budget.baselineId == "v0.1.0")
        #expect(budget.evidence.sourceCommit == "55f2ee429932b68ed7a02c3750cd28a28c9bd3d9")
        #expect(budget.evidence.workflowRunId == 31_588_206_985)
        #expect(budget.evidence.artifactId == 9_138_085_911)
        #expect(
            budget.evidence.summary
                == SizeSummary(
                    appSizeBytes: 745_582,
                    dmgSizeBytes: 475_100,
                    executableSizeBytes: 443_376
                )
        )
        #expect(
            budget.allowanceBytes
                == SizeSummary(
                    appSizeBytes: 479_232,
                    dmgSizeBytes: 389_120,
                    executableSizeBytes: 180_224
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
