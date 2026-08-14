import Foundation
import Testing

struct RegressionUIFoundationSizeBudgetPolicyTests {
    @Test
    func foundationBudgetIsProvenancedTightAndUsedByCI() throws {
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
                == "fabbecb4d97a0bf9fc059d010fdf7401ddf97bba"
        )
        #expect(evidence["workflowRunId"] as? Int == 31_804_886_824)
        #expect(evidence["artifactId"] as? Int == 9_220_849_442)
        #expect(
            summary
                == [
                    "appSizeBytes": 747_934,
                    "dmgSizeBytes": 483_314,
                    "executableSizeBytes": 445_728
                ]
        )
        #expect(
            allowance
                == [
                    "appSizeBytes": 479_232,
                    "dmgSizeBytes": 397_312,
                    "executableSizeBytes": 180_224
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
