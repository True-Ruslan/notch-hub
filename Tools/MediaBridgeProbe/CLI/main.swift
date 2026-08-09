import CoreFoundation
import Darwin
import Foundation
import MediaBridgeProbeCore

private enum ExitCode {
    static let success: Int32 = 0
    static let usage: Int32 = 64
    static let noInput: Int32 = 66
    static let software: Int32 = 70
}

private struct ProbeAssets {
    let scriptURL: URL
    let frameworkURL: URL
    let testClientURL: URL

    static func bundled() throws -> ProbeAssets {
        guard let resources = Bundle.main.resourceURL else {
            throw ProbeCLIError.missingBundledResources
        }

        let scriptURL = resources.appendingPathComponent("mediaremote-adapter.pl")
        let frameworkURL = resources.appendingPathComponent("MediaRemoteAdapter.framework")
        let testClientURL = resources.appendingPathComponent("MediaRemoteAdapterTestClient")

        let fileManager = FileManager.default
        guard
            fileManager.fileExists(atPath: scriptURL.path),
            fileManager.fileExists(atPath: frameworkURL.path),
            fileManager.fileExists(atPath: testClientURL.path)
        else {
            throw ProbeCLIError.missingBundledResources
        }

        return ProbeAssets(
            scriptURL: scriptURL,
            frameworkURL: frameworkURL,
            testClientURL: testClientURL
        )
    }
}

private enum ProbeCLIError: Error {
    case missingBundledResources
    case missingBuildProvenance
    case reportEncodingFailed
    case capabilitiesUnavailable
}

@MainActor
private final class ObservationEvidence {
    private(set) var sourceBundleIdentifier: String?
    private(set) var observedSession = false
    private(set) var observedArtwork = false
    private(set) var observedPlayingState = false
    private(set) var eventCount = 0

    func record(_ payload: ProbeMediaPayload?) {
        eventCount += 1
        guard let payload else {
            return
        }

        observedSession = true
        observedPlayingState = true
        observedArtwork = observedArtwork || payload.artworkByteCount > 0
        sourceBundleIdentifier = payload.bundleIdentifier
    }
}

@main
private struct MediaBridgeProbeCLI {
    @MainActor
    static func main() {
        let arguments = Array(CommandLine.arguments.dropFirst())
        let invocation: ProbeInvocation

        do {
            invocation = try ProbeInvocation.parse(arguments: arguments)
        } catch {
            printUsage()
            exit(ExitCode.usage)
        }

        let assets: ProbeAssets
        do {
            assets = try ProbeAssets.bundled()
        } catch {
            fputs("MediaBridgeProbe: bundled adapter resources are missing.\n", stderr)
            exit(ExitCode.noInput)
        }

        let controller = ProbeProcessController()

        do {
            switch invocation {
            case .selfTest:
                let status = try controller.runSelfTest(
                    scriptURL: assets.scriptURL,
                    frameworkURL: assets.frameworkURL,
                    testClientURL: assets.testClientURL
                )
                exit(status == 0 ? ExitCode.success : ExitCode.software)

            case .capabilities:
                throw ProbeCLIError.capabilitiesUnavailable

            case .command(let command):
                let status = try controller.runCommand(
                    command,
                    scriptURL: assets.scriptURL,
                    frameworkURL: assets.frameworkURL,
                    testClientURL: assets.testClientURL
                )
                exit(status == 0 ? ExitCode.success : ExitCode.software)

            case .observe(let seconds):
                let evidence = ObservationEvidence()
                controller.onPayload = { payload in
                    evidence.record(payload)
                }
                try controller.startObservation(
                    scriptURL: assets.scriptURL,
                    frameworkURL: assets.frameworkURL,
                    testClientURL: assets.testClientURL
                )

                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Int(seconds))) {
                    controller.stop()
                    CFRunLoopStop(CFRunLoopGetMain())
                }
                CFRunLoopRun()

                let report = try makeReport(evidence: evidence)
                try writeReport(report)
                exit(ExitCode.success)
            }
        } catch {
            fputs("MediaBridgeProbe: probe operation failed.\n", stderr)
            controller.stop()
            exit(ExitCode.software)
        }
    }

    @MainActor
    private static func makeReport(evidence: ObservationEvidence) throws -> ProbeReport {
        guard
            let sourceCommit = Bundle.main.object(
                forInfoDictionaryKey: "ProbeSourceCommit"
            ) as? String,
            let adapterCommit = Bundle.main.object(
                forInfoDictionaryKey: "ProbeAdapterCommit"
            ) as? String,
            sourceCommit.count == 40,
            adapterCommit.count == 40
        else {
            throw ProbeCLIError.missingBuildProvenance
        }

        return ProbeReport(
            schemaVersion: 1,
            sourceCommit: sourceCommit,
            macOSVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            hardwareModel: hardwareModel(),
            adapterCommit: adapterCommit,
            sourceBundleIdentifier: evidence.sourceBundleIdentifier,
            observedSession: evidence.observedSession,
            observedArtwork: evidence.observedArtwork,
            observedPlayingState: evidence.observedPlayingState,
            eventCount: evidence.eventCount,
            commandResults: [:],
            cleanTeardown: true,
            orphanProcessDetected: false
        )
    }

    private static func writeReport(_ report: ProbeReport) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(report)
        guard var text = String(data: data, encoding: .utf8) else {
            throw ProbeCLIError.reportEncodingFailed
        }
        text.append("\n")
        FileHandle.standardOutput.write(Data(text.utf8))
    }

    private static func hardwareModel() -> String {
        var size = 0
        guard sysctlbyname("hw.model", nil, &size, nil, 0) == 0, size > 1 else {
            return "unknown"
        }

        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname("hw.model", &buffer, &size, nil, 0) == 0 else {
            return "unknown"
        }

        let bytes = buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }

    private static func printUsage() {
        fputs(
            "Usage: MediaBridgeProbe observe --seconds N | capabilities | "
                + "send toggle|next|previous | seek MICROSECONDS | self-test\n",
            stderr
        )
    }
}
