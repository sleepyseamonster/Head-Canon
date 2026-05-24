import Foundation
import Testing
@testable import HeadCanon

struct BrowserCompanionSupportTests {
    @Test("Browser host detection recognizes common browser bundles")
    func browserHostDetectionRecognizesCommonBundles() {
        #expect(
            BrowserHostApplication.detect(
                bundleIdentifier: "com.google.Chrome",
                applicationName: "Google Chrome"
            ) == .chrome
        )
        #expect(
            BrowserHostApplication.detect(
                bundleIdentifier: "com.apple.Safari",
                applicationName: "Safari"
            ) == .safari
        )
        #expect(
            BrowserHostApplication.detect(
                bundleIdentifier: "company.thebrowser.Browser",
                applicationName: "Arc"
            ) == .arc
        )
        #expect(
            BrowserHostApplication.detect(
                bundleIdentifier: "com.apple.TextEdit",
                applicationName: "TextEdit"
            ) == nil
        )
    }

    @Test("Browser target classifier distinguishes plain controls from rich editors")
    func browserTargetClassifierDistinguishesEditorFamilies() {
        let searchFamily = BrowserTargetClassifier.editorFamily(
            role: "AXTextField",
            subrole: nil,
            roleDescription: "search field",
            title: "Search",
            identifier: "search-box",
            placeholderValue: "Search",
            domIdentifier: "search",
            secure: false
        )
        let richFamily = BrowserTargetClassifier.editorFamily(
            role: "AXTextArea",
            subrole: nil,
            roleDescription: "editor",
            title: "Composer",
            identifier: "prompt-editor",
            placeholderValue: "Message ChatGPT",
            domIdentifier: "prompt-textarea",
            secure: false
        )

        #expect(searchFamily == .searchField)
        #expect(richFamily == .frameworkManagedEditor)
        #expect(
            BrowserTargetClassifier.targetClass(
                editorFamily: searchFamily,
                contextKind: .axFocusedElement,
                secure: false
            ) == .plainTextControl
        )
        #expect(
            BrowserTargetClassifier.targetClass(
                editorFamily: richFamily,
                contextKind: .axFocusedElement,
                secure: false
            ) == .richEditable
        )
    }

    @Test("Browser companion protocol envelopes round-trip cleanly")
    func browserCompanionProtocolEnvelopesRoundTrip() throws {
        let target = BrowserCompanionTargetSnapshot(
            browser: .chrome,
            pageOrigin: "https://chatgpt.com",
            pageTitle: "ChatGPT",
            framePath: "0",
            frameIdentifier: "main",
            targetClass: .richEditable,
            editorFamily: .frameworkManagedEditor,
            targetFingerprint: "AXTextArea | Composer | prompt-textarea",
            editable: true,
            secure: false
        )
        let command = BrowserCompanionCommandEnvelope(
            protocolVersion: BrowserCompanionProtocolVersion.current,
            command: .insertTranscript,
            operationID: UUID(),
            issuedAt: Date(timeIntervalSince1970: 1_234),
            expiresAt: Date(timeIntervalSince1970: 1_264),
            target: target,
            transcript: "Run a speed check."
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let commandData = try encoder.encode(command)
        let decodedCommand = try decoder.decode(BrowserCompanionCommandEnvelope.self, from: commandData)

        #expect(decodedCommand == command)

        let result = BrowserCompanionResultEnvelope(
            protocolVersion: BrowserCompanionProtocolVersion.current,
            result: .inserted,
            operationID: command.operationID,
            observedAt: Date(timeIntervalSince1970: 1_240),
            target: target,
            message: nil
        )
        let resultData = try encoder.encode(result)
        let decodedResult = try decoder.decode(BrowserCompanionResultEnvelope.self, from: resultData)

        #expect(decodedResult == result)
    }

    @Test("Diagnostics records preserve browser context when encoded")
    func diagnosticsRecordsPreserveBrowserContextWhenEncoded() throws {
        let browserContext = BrowserTargetMetadata(
            browser: .safari,
            targetClass: .plainTextControl,
            editorFamily: .textAreaControl,
            verificationMode: .exactValueReadback,
            pageOrigin: "https://example.com",
            pageTitle: "Example",
            framePath: "0",
            frameIdentifier: "root",
            targetFingerprint: "AXTextArea | Notes",
            operationID: UUID(),
            focusCapturedAt: Date(timeIntervalSince1970: 100),
            focusValidatedAt: Date(timeIntervalSince1970: 101),
            protocolVersion: BrowserCompanionProtocolVersion.current,
            extensionVersion: "0.1.0"
        )
        let record = DictationAttemptRecord(
            schemaVersion: DictationAttemptRecord.schemaVersion,
            attemptID: UUID(),
            sessionID: UUID(),
            completedAt: Date(timeIntervalSince1970: 200),
            terminalState: .inserted,
            truthState: .verifiedInsert,
            hotkeyDisplayString: "Right Option",
            bundle: DictationAttemptBundleRecord(
                path: "/Applications/HeadCanon.app",
                identifier: "HeadCanon",
                isInstalledBundle: true
            ),
            timing: DictationAttemptTimingRecord(
                hotkeyPressedAt: nil,
                recordingStartedAt: nil,
                hotkeyReleasedAt: nil,
                finalizingStateShownAt: nil,
                recordingFinalizedAt: nil,
                transcriptionRequestStartedAt: nil,
                transcriptionResponseCompletedAt: nil,
                insertionCompletedAt: nil,
                stopTrigger: nil,
                pressToRecordingStartDurationMS: nil,
                releaseToFinalizingStateDurationMS: nil,
                releaseToFinalizedDurationMS: nil,
                finalizedToRequestStartDurationMS: nil,
                requestToResponseDurationMS: nil,
                responseToInsertionDurationMS: nil,
                releaseToInsertionDurationMS: nil
            ),
            audio: DictationAttemptAudioRecord(
                clipDurationMS: nil,
                recordedFileSizeBytes: nil
            ),
            transcript: DictationAttemptTranscriptRecord(
                characterCount: 18,
                wordCount: 4
            ),
            backend: DictationAttemptBackendRecord(
                identifier: "gpt-4o-mini-transcribe",
                requestMode: "Standard Completed Recording",
                fellBackFromStreaming: false,
                httpStatusCode: 200,
                requestID: "req_browser",
                openAIProcessingMS: 500,
                responseContentType: "application/json",
                responseHeadersReceivedMS: 120,
                transportFailureStage: nil,
                networkErrorDomain: nil,
                networkErrorCode: nil,
                networkErrorCodeName: nil
            ),
            releaseTimeInsertion: nil,
            insertion: DictationAttemptInsertionRecord(
                observationLabel: "Insert-Time Context",
                applicationName: "Safari",
                bundleIdentifier: "com.apple.Safari",
                browserContext: browserContext,
                target: "Notes",
                contextKind: InsertionContextKind.axFocusedElement.rawValue,
                capabilityProfile: ApplicationCapabilityProfile.nativeAXStrong.rawValue,
                chosenStrategy: InsertionStrategy.axValueReplacement.rawValue,
                appliedStrategy: InsertionStrategy.axValueReplacement.rawValue,
                strategyReason: "Writable browser textarea.",
                predictedFailureClass: nil,
                verificationOutcome: InsertionVerificationOutcome.verified.rawValue,
                placeholderPresent: false,
                placeholderLikelyActive: false,
                placeholderAmbiguousValueDetected: false,
                placeholderHandlingOutcome: PlaceholderHandlingOutcome.noneNeeded.rawValue,
                valueReadable: true,
                valueSettable: true,
                selectedTextRangeReadable: true,
                selectedTextReadable: true,
                editable: true,
                secure: false,
                pasteCompatible: true,
                directInsertCompatible: true
            ),
            failure: nil,
            clipboardRecovery: nil
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(record)
        let decodedRecord = try decoder.decode(DictationAttemptRecord.self, from: data)

        #expect(decodedRecord.insertion?.browserContext == browserContext)
    }
}
