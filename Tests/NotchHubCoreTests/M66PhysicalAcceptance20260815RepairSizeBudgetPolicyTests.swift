import Foundation
import Testing

struct M66PhysicalAcceptance20260815RepairSizeBudgetPolicyTests {
    @Test
    func repairBudgetRemainsTightProvenancedHistoricalEvidence() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let budgetURL = repositoryRoot.appendingPathComponent(
            "performance/m6-6-physical-acceptance-20260815-repair-size-budget.json"
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
        #expect(budget.featureId == "m6.6-physical-acceptance-20260815-repair")
        #expect(budget.baselineId == "v0.1.0")
        #expect(budget.evidence.sourceCommit == "63b0f2f96f879123f3883db7311c90a20d3a4328")
        #expect(budget.evidence.workflowRunId == 31_889_213_155)
        #expect(budget.evidence.artifactId == 9_248_133_083)
        #expect(
            budget.evidence.summary
                == SizeSummary(
                    appSizeBytes: 883_039,
                    dmgSizeBytes: 555_132,
                    executableSizeBytes: 580_832
                )
        )
        #expect(
            budget.allowanceBytes
                == SizeSummary(
                    appSizeBytes: 614_400,
                    dmgSizeBytes: 466_944,
                    executableSizeBytes: 315_392
                )
        )
        #expect(budget.allowanceBytes.appSizeBytes.isMultiple(of: 4_096))
        #expect(budget.allowanceBytes.dmgSizeBytes.isMultiple(of: 4_096))
        #expect(budget.allowanceBytes.executableSizeBytes.isMultiple(of: 4_096))

        let workflow = try String(contentsOf: workflowURL, encoding: .utf8)
        #expect(
            workflow.contains(
                "--feature-budget performance/m6-7-live-media-timeline-and-compact-size-budget.json"
            )
        )
        #expect(
            !workflow.contains(
                "--feature-budget performance/m6-6-hardware-notch-screen-selection-size-budget.json"
            )
        )
        #expect(
            !workflow.contains(
                "--feature-budget performance/m6-6-physical-acceptance-20260816-first-click-size-budget.json"
            )
        )
        #expect(
            !workflow.contains(
                "--feature-budget performance/m6-6-physical-acceptance-20260815-repair-size-budget.json"
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
