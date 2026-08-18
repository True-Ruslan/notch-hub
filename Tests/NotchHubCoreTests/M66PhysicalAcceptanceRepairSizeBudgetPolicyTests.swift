import Foundation
import Testing

struct M66PhysicalAcceptanceRepairSizeBudgetPolicyTests {
    @Test
    func repairBudgetRemainsTightAndProvenanced() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let budgetURL = repositoryRoot.appendingPathComponent(
            "performance/m6-6-physical-acceptance-repair-size-budget.json"
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
        #expect(budget.featureId == "m6.6-physical-acceptance-repair")
        #expect(budget.baselineId == "v0.1.0")
        #expect(budget.evidence.sourceCommit == "d8fb784eb9eb47c7af34dbd689b6fcfa5aadef12")
        #expect(budget.evidence.workflowRunId == 31_617_785_894)
        #expect(budget.evidence.artifactId == 9_150_099_248)
        #expect(
            budget.evidence.summary
                == SizeSummary(
                    appSizeBytes: 825_406,
                    dmgSizeBytes: 527_113,
                    executableSizeBytes: 523_200
                )
        )
        #expect(
            budget.allowanceBytes
                == SizeSummary(
                    appSizeBytes: 556_032,
                    dmgSizeBytes: 437_248,
                    executableSizeBytes: 257_024
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
