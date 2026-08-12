import Foundation
import Testing

struct M66HoverPeekSizeBudgetPolicyTests {
    @Test
    func hoverPeekRequiresTightProvenancedBudgetAndMakesItActive() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let budgetURL = repositoryRoot.appendingPathComponent(
            "performance/m6-6-hover-peek-size-budget.json"
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
        #expect(budget.featureId == "m6.6-hover-peek")
        #expect(budget.baselineId == "v0.1.0")
        #expect(budget.evidence.sourceCommit == "7daffde9b7c2a734e2ddfa234b1ee744b0d96d9e")
        #expect(budget.evidence.workflowRunId == 31_636_748_859)
        #expect(budget.evidence.artifactId == 9_157_392_052)
        #expect(
            budget.evidence.summary
                == SizeSummary(
                    appSizeBytes: 864_574,
                    dmgSizeBytes: 555_272,
                    executableSizeBytes: 562_368
                )
        )
        #expect(
            budget.allowanceBytes
                == SizeSummary(
                    appSizeBytes: 594_944,
                    dmgSizeBytes: 465_920,
                    executableSizeBytes: 296_960
                )
        )

        let workflow = try String(contentsOf: workflowURL, encoding: .utf8)
        #expect(
            workflow.contains(
                "--feature-budget performance/m6-6-hover-peek-size-budget.json"
            )
        )
        #expect(
            !workflow.contains(
                "--feature-budget performance/m6-6-physical-acceptance-repair-size-budget.json"
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
