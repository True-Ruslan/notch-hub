import Foundation
import Testing

struct M66SourceAppIconSizeBudgetPolicyTests {
    @Test
    func sourceAppIconOwnsTightProvenancedBudgetAndCIUsesIt() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let budgetURL = repositoryRoot.appendingPathComponent(
            "performance/m6-6-source-app-icon-size-budget.json"
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
        #expect(budget.featureId == "m6.6-source-app-icon")
        #expect(budget.baselineId == "v0.1.0")
        #expect(budget.evidence.sourceCommit == "066b8264f53c1dc1afe01fe8a120bb8ab9509102")
        #expect(budget.evidence.workflowRunId == 31_601_331_136)
        #expect(budget.evidence.artifactId == 9_143_349_824)
        #expect(
            budget.evidence.summary
                == SizeSummary(
                    appSizeBytes: 782_414,
                    dmgSizeBytes: 506_515,
                    executableSizeBytes: 480_208
                )
        )
        #expect(
            budget.allowanceBytes
                == SizeSummary(
                    appSizeBytes: 518_144,
                    dmgSizeBytes: 421_888,
                    executableSizeBytes: 219_136
                )
        )

        let workflow = try String(contentsOf: workflowURL, encoding: .utf8)
        #expect(
            workflow.contains(
                "--feature-budget performance/m6-6-source-app-icon-size-budget.json"
            )
        )
        #expect(
            !workflow.contains(
                "--feature-budget performance/m6-6-app-gesture-session-size-budget.json"
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
