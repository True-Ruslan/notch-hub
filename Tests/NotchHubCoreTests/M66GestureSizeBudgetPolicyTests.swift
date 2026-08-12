import Foundation
import Testing

struct M66GestureSizeBudgetPolicyTests {
    @Test
    func gestureEngineBudgetRemainsProvenanced() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let budgetURL = repositoryRoot.appendingPathComponent(
            "performance/m6-6-gesture-engine-size-budget.json"
        )

        let budget = try JSONDecoder().decode(
            FeatureBudget.self,
            from: Data(contentsOf: budgetURL)
        )
        #expect(budget.schemaVersion == 1)
        #expect(budget.featureId == "m6.6-gesture-engine")
        #expect(budget.baselineId == "v0.1.0")
        #expect(budget.evidence.sourceCommit == "ddad4a3efa579caf818693dece9845059fbcd810")
        #expect(budget.evidence.workflowRunId == 31_582_412_364)
        #expect(budget.evidence.artifactId == 9_135_807_459)
        #expect(
            budget.evidence.summary
                == SizeSummary(
                    appSizeBytes: 724_814,
                    dmgSizeBytes: 474_960,
                    executableSizeBytes: 422_608
                )
        )
        #expect(
            budget.allowanceBytes
                == SizeSummary(
                    appSizeBytes: 458_752,
                    dmgSizeBytes: 389_120,
                    executableSizeBytes: 159_744
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
