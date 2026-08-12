import Foundation
import Testing

struct M66MediaSeekSizeBudgetPolicyTests {
    @Test
    func mediaSeekOwnsTightProvenancedBudgetAndCIUsesIt() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let budgetURL = repositoryRoot.appendingPathComponent(
            "performance/m6-6-media-seek-size-budget.json"
        )
        let workflowURL = repositoryRoot.appendingPathComponent(
            ".github/workflows/ci.yml"
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
        #expect(budget.featureId == "m6.6-media-seek")
        #expect(budget.baselineId == "v0.1.0")
        #expect(budget.evidence.sourceCommit == "01bb282f7cbc5eab57b11b1695ccf9768fc6cb2e")
        #expect(budget.evidence.workflowRunId == 31_606_258_918)
        #expect(budget.evidence.artifactId == 9_145_423_733)
        #expect(
            budget.evidence.summary
                == SizeSummary(
                    appSizeBytes: 802_190,
                    dmgSizeBytes: 520_488,
                    executableSizeBytes: 499_984
                )
        )
        #expect(
            budget.allowanceBytes
                == SizeSummary(
                    appSizeBytes: 536_576,
                    dmgSizeBytes: 434_176,
                    executableSizeBytes: 237_568
                )
        )

        let workflow = try String(contentsOf: workflowURL, encoding: .utf8)
        #expect(
            workflow.contains(
                "--feature-budget performance/m6-6-media-seek-size-budget.json"
            )
        )
        #expect(
            !workflow.contains(
                "--feature-budget performance/m6-6-source-app-icon-size-budget.json"
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
