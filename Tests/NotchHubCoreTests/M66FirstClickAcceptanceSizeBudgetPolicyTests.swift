import Foundation
import Testing

struct M66FirstClickAcceptanceSizeBudgetPolicyTests {
    @Test
    func firstClickBudgetIsTightProvenancedAndActiveInCI() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let budgetURL = repositoryRoot.appendingPathComponent(
            "performance/m6-6-physical-acceptance-20260816-first-click-size-budget.json"
        )
        let previousBudgetURL = repositoryRoot.appendingPathComponent(
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
        let previousBudget = try JSONDecoder().decode(
            FeatureBudget.self,
            from: Data(contentsOf: previousBudgetURL)
        )

        #expect(budget.schemaVersion == 1)
        #expect(budget.featureId == "m6.6-physical-acceptance-20260816-first-click")
        #expect(budget.baselineId == "v0.1.0")
        #expect(budget.evidence.sourceCommit == "327f5b4180d71a1001fb93285fa25b98abcc088c")
        #expect(budget.evidence.workflowRunId == 31_914_056_522)
        #expect(budget.evidence.artifactId == 9_254_479_722)
        #expect(
            budget.evidence.summary
                == SizeSummary(
                    appSizeBytes: 883_087,
                    dmgSizeBytes: 557_704,
                    executableSizeBytes: 580_880
                )
        )

        #expect(budget.allowanceBytes.appSizeBytes == previousBudget.allowanceBytes.appSizeBytes)
        #expect(
            budget.allowanceBytes.executableSizeBytes
                == previousBudget.allowanceBytes.executableSizeBytes
        )
        #expect(
            budget.allowanceBytes.dmgSizeBytes
                == previousBudget.allowanceBytes.dmgSizeBytes + 4_096
        )
        #expect(budget.allowanceBytes.appSizeBytes == 614_400)
        #expect(budget.allowanceBytes.dmgSizeBytes == 471_040)
        #expect(budget.allowanceBytes.executableSizeBytes == 315_392)
        #expect(budget.allowanceBytes.appSizeBytes.isMultiple(of: 4_096))
        #expect(budget.allowanceBytes.dmgSizeBytes.isMultiple(of: 4_096))
        #expect(budget.allowanceBytes.executableSizeBytes.isMultiple(of: 4_096))

        let workflow = try String(contentsOf: workflowURL, encoding: .utf8)
        #expect(
            workflow.contains(
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
