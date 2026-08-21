import Foundation
import Testing

struct RegressionUIFoundationSizeBudgetPolicyTests {
    @Test
    func foundationBudgetRemainsProvenancedHistoricalEvidenceWhileM1BudgetIsActive() throws {
        let repositoryRoot = repositoryRoot()
        let budgetURL =
            repositoryRoot
            .appendingPathComponent("performance")
            .appendingPathComponent("regression-ui-automation-foundation-size-budget.json")
        let ciURL =
            repositoryRoot
            .appendingPathComponent(".github")
            .appendingPathComponent("workflows")
            .appendingPathComponent("ci.yml")

        #expect(FileManager.default.fileExists(atPath: budgetURL.path))

        let ci = try String(contentsOf: ciURL, encoding: .utf8)
        #expect(
            ci.contains(
                "--feature-budget performance/m1-active-display-migration-size-budget.json"
            )
        )
        #expect(
            !ci.contains(
                "--feature-budget performance/m6-6-hardware-notch-screen-selection-size-budget.json"
            )
        )
        #expect(
            !ci.contains(
                "--feature-budget performance/m6-6-physical-acceptance-20260816-first-click-size-budget.json"
            )
        )
        #expect(
            !ci.contains(
                "--feature-budget performance/m6-6-physical-acceptance-20260815-repair-size-budget.json"
            )
        )
        #expect(
            !ci.contains(
                "--feature-budget performance/m6-6-regression-foundation-integration-size-budget.json"
            )
        )
        #expect(
            !ci.contains(
                "--feature-budget performance/regression-ui-automation-foundation-size-budget.json"
            )
        )

        guard FileManager.default.fileExists(atPath: budgetURL.path) else {
            return
        }

        let data = try Data(contentsOf: budgetURL)
        let json = try #require(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        let evidence = try #require(json["evidence"] as? [String: Any])
        let summary = try #require(evidence["summary"] as? [String: Int])
        let allowance = try #require(json["allowanceBytes"] as? [String: Int])

        #expect(json["schemaVersion"] as? Int == 1)
        #expect(json["featureId"] as? String == "regression-ui-automation-foundation")
        #expect(json["baselineId"] as? String == "v0.1.0")
        #expect(
            evidence["sourceCommit"] as? String
                == "e9d414e094ee2ea5f72815078210e4dda9163aec"
        )
        #expect(evidence["workflowRunId"] as? Int == 31_842_940_616)
        #expect(evidence["artifactId"] as? Int == 9_235_015_770)
        #expect(
            summary
                == [
                    "appSizeBytes": 748_863,
                    "dmgSizeBytes": 483_851,
                    "executableSizeBytes": 446_656
                ]
        )
        #expect(
            allowance
                == [
                    "appSizeBytes": 479_232,
                    "dmgSizeBytes": 397_312,
                    "executableSizeBytes": 184_320
                ]
        )
    }

    private func repositoryRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
