import Foundation
import Testing

struct M66RegressionFoundationIntegrationSizeBudgetPolicyTests {
    @Test
    func integrationBudgetRemainsTightProvenancedHistoricalEvidence() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let budgetURL = repositoryRoot.appendingPathComponent(
            "performance/m6-6-regression-foundation-integration-size-budget.json"
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
        #expect(budget.featureId == "m6.6-regression-foundation-integration")
        #expect(budget.baselineId == "v0.1.0")
        #expect(budget.evidence.sourceCommit == "452f78b0e42c5302702393e9c45c563849661ca4")
        #expect(budget.evidence.workflowRunId == 31_869_841_148)
        #expect(budget.evidence.artifactId == 9_243_156_724)
        #expect(
            budget.evidence.summary
                == SizeSummary(
                    appSizeBytes: 882_687,
                    dmgSizeBytes: 552_272,
                    executableSizeBytes: 580_480
                )
        )
        #expect(
            budget.allowanceBytes
                == SizeSummary(
                    appSizeBytes: 614_400,
                    dmgSizeBytes: 462_848,
                    executableSizeBytes: 315_392
                )
        )
        #expect(budget.allowanceBytes.appSizeBytes.isMultiple(of: 4_096))
        #expect(budget.allowanceBytes.dmgSizeBytes.isMultiple(of: 4_096))
        #expect(budget.allowanceBytes.executableSizeBytes.isMultiple(of: 4_096))
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
