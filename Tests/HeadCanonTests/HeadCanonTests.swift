import ApplicationServices
import AppKit
import Foundation
import Testing
@testable import HeadCanon

@Suite("Head Canon Defaults")
struct HeadCanonTests {
    @Test("Preferences default to v1 retention and fallback values")
    @MainActor
    func preferencesDefaultToSpecValues() {
        let suiteName = "HeadCanonTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let preferences = AppPreferences(defaults: defaults)

        #expect(preferences.historyRetentionMode == .thirtyDays)
        #expect(preferences.pasteFallbackEnabled)
        #expect(preferences.hotkey == .defaultPushToTalk)
        #expect(preferences.hotkey.displayString == "Hold Control + Option")
        #expect(preferences.selectedMicrophoneID == nil)
        #expect(preferences.openAITranscriptionModel == .gpt4oMiniTranscribe)
    }

    @Test("Preferences persist hotkey and validation cache")
    @MainActor
    func preferencesPersistHotkeyAndValidationCache() {
        let suiteName = "HeadCanonTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let preferences = AppPreferences(defaults: defaults)
        let validationDate = Date(timeIntervalSince1970: 1_715_000_000)

        preferences.hotkey = .spacePushToTalk
        preferences.openAITranscriptionModel = .gpt4oTranscribe
        preferences.persistValidatedAPIKey("test-key", validatedAt: validationDate)

        let reloaded = AppPreferences(defaults: defaults)

        #expect(reloaded.hotkey == .spacePushToTalk)
        #expect(reloaded.openAITranscriptionModel == .gpt4oTranscribe)
        #expect(reloaded.lastValidationDate == validationDate)
        #expect(reloaded.hasCachedValidation(for: "test-key"))
        #expect(!reloaded.hasCachedValidation(for: "other-key"))
    }

    @Test("Legacy modifier-hold installs keep hold-to-record behavior")
    @MainActor
    func legacyModifierHoldIdentifierStaysOnModifierHold() {
        let suiteName = "HeadCanonTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(
            HotkeyShortcut.Identifier.modifierHoldControlOptionExperimental.rawValue,
            forKey: "hotkeyIdentifier"
        )

        let preferences = AppPreferences(defaults: defaults)

        #expect(preferences.hotkey == .defaultPushToTalk)
        #expect(preferences.hotkey.displayString == "Hold Control + Option")
    }

    @Test("Setup blockers reflect missing permissions and key state")
    @MainActor
    func setupBlockersDescribeUnreadyState() {
        let model = HeadCanonModel(
            permissionsManager: StubPermissionsManager(
                snapshot: PermissionSnapshot(
                    microphone: .denied,
                    accessibility: .denied
                )
            ),
            audioCaptureService: StubAudioCaptureService(),
            transcriptionBackend: StubTranscriptionBackend(),
            textInsertionService: StubTextInsertionService(),
            apiKeyStore: StubAPIKeyStore(apiKey: nil),
            diagnosticsStore: NoOpDiagnosticsStore(),
            hotkeyManager: StubHotkeyManager()
        )

        model.refreshPermissions()

        #expect(
            model.setupBlockers == [
                .microphone,
                .accessibility,
                .apiKeyMissing,
            ]
        )
        #expect(model.statusSummary == SetupBlocker.microphone.detail)
    }

    @Test("Low-disk warning does not hide a real setup blocker in the summary")
    @MainActor
    func diskWarningDoesNotHideSetupBlocker() async {
        let model = HeadCanonModel(
            permissionsManager: StubPermissionsManager(
                snapshot: PermissionSnapshot(
                    microphone: .denied,
                    accessibility: .granted
                )
            ),
            audioCaptureService: StubAudioCaptureService(),
            transcriptionBackend: StubTranscriptionBackend(),
            textInsertionService: StubTextInsertionService(),
            apiKeyStore: StubAPIKeyStore(apiKey: "test-key"),
            diagnosticsStore: NoOpDiagnosticsStore(),
            hotkeyManager: StubHotkeyManager(),
            diskSpaceChecker: StubDiskSpaceChecker(
                freeBytes: DiskSpacePolicy.gibibytes(5)
            )
        )

        await model.refreshRuntimeStatus(validateAPIKeyRemotely: false, presentSetupWindow: false)
        model.apiKeyState = .valid

        #expect(model.diskSpaceReadiness?.status == .warning)
        #expect(model.statusSummary == SetupBlocker.microphone.detail)
    }

    @Test("Pending Accessibility approval still blocks readiness without showing granted")
    @MainActor
    func pendingAccessibilityStillBlocksReadiness() async {
        let model = HeadCanonModel(
            permissionsManager: StubPermissionsManager(
                snapshot: PermissionSnapshot(
                    microphone: .granted,
                    accessibility: .pending
                )
            ),
            audioCaptureService: StubAudioCaptureService(),
            transcriptionBackend: StubTranscriptionBackend(),
            textInsertionService: StubTextInsertionService(),
            apiKeyStore: StubAPIKeyStore(apiKey: "test-key"),
            diagnosticsStore: NoOpDiagnosticsStore(),
            hotkeyManager: StubHotkeyManager()
        )

        await model.refreshRuntimeStatus(validateAPIKeyRemotely: false, presentSetupWindow: false)

        #expect(model.permissionSnapshot.accessibility == .pending)
        #expect(model.setupBlockers == [.accessibility, .apiKeyValidationRequired])
        #expect(!model.isReady)
        #expect(model.accessibilitySetupAction == .relaunchForAccessibility)
    }

    @Test("Ready state clears setup blockers")
    @MainActor
    func readyStateClearsSetupBlockers() async {
        let model = HeadCanonModel(
            permissionsManager: StubPermissionsManager(
                snapshot: PermissionSnapshot(
                    microphone: .granted,
                    accessibility: .granted
                )
            ),
            audioCaptureService: StubAudioCaptureService(),
            transcriptionBackend: StubTranscriptionBackend(),
            textInsertionService: StubTextInsertionService(),
            apiKeyStore: StubAPIKeyStore(apiKey: "test-key"),
            diagnosticsStore: NoOpDiagnosticsStore(),
            hotkeyManager: StubHotkeyManager()
        )

        await model.refreshRuntimeStatus(validateAPIKeyRemotely: false, presentSetupWindow: false)
        model.apiKeyState = .valid

        #expect(model.setupBlockers.isEmpty)
        #expect(model.statusSummary == "Head Canon is ready.")
        #expect(model.isReady)
        #expect(model.checkpointSummary == "Ready for the TextEdit dictation smoke test.")
    }

    @Test("Denied microphone retries a direct permission request first")
    @MainActor
    func deniedMicrophoneUsesRequestAction() {
        let model = HeadCanonModel(
            permissionsManager: StubPermissionsManager(
                snapshot: PermissionSnapshot(
                    microphone: .denied,
                    accessibility: .granted
                )
            ),
            audioCaptureService: StubAudioCaptureService(),
            transcriptionBackend: StubTranscriptionBackend(),
            textInsertionService: StubTextInsertionService(),
            apiKeyStore: StubAPIKeyStore(apiKey: "test-key"),
            diagnosticsStore: NoOpDiagnosticsStore(),
            hotkeyManager: StubHotkeyManager()
        )

        model.refreshPermissions()

        #expect(model.microphoneSetupAction == .requestMicrophoneAccess)
    }

}

@Suite("Head Canon Transcription Backend")
struct HeadCanonTranscriptionBackendTests {
    @Test("Multipart transcription body includes model, language, and stream flag")
    @MainActor
    func multipartBodyIncludesSelectedModelAndLanguage() throws {
        let input = BoundedAudioInput(
            fileURL: URL(fileURLWithPath: "/tmp/test.m4a"),
            mimeType: "audio/m4a",
            duration: 1.0
        )
        let body = OpenAIBoundedTranscriptionBackend.multipartBody(
            audioData: Data("audio".utf8),
            input: input,
            boundary: "TestBoundary",
            model: OpenAITranscriptionModel.gpt4oTranscribe.rawValue,
            responseFormat: "json",
            language: "en",
            stream: true
        )
        let bodyString = String(decoding: body, as: UTF8.self)

        #expect(bodyString.contains("name=\"model\""))
        #expect(bodyString.contains(OpenAITranscriptionModel.gpt4oTranscribe.rawValue))
        #expect(bodyString.contains("name=\"response_format\""))
        #expect(bodyString.contains("json"))
        #expect(bodyString.contains("name=\"language\""))
        #expect(bodyString.contains("en"))
        #expect(bodyString.contains("name=\"stream\""))
        #expect(bodyString.contains("true"))
    }

    @Test("Standard multipart transcription body omits stream flag")
    @MainActor
    func standardMultipartBodyOmitsStreamFlag() throws {
        let input = BoundedAudioInput(
            fileURL: URL(fileURLWithPath: "/tmp/test.m4a"),
            mimeType: "audio/m4a",
            duration: 1.0
        )
        let body = OpenAIBoundedTranscriptionBackend.multipartBody(
            audioData: Data("audio".utf8),
            input: input,
            boundary: "TestBoundary",
            model: OpenAITranscriptionModel.gpt4oMiniTranscribe.rawValue,
            responseFormat: "text",
            language: "en",
            stream: false
        )
        let bodyString = String(decoding: body, as: UTF8.self)

        #expect(bodyString.contains("name=\"model\""))
        #expect(bodyString.contains(OpenAITranscriptionModel.gpt4oMiniTranscribe.rawValue))
        #expect(bodyString.contains("name=\"response_format\""))
        #expect(bodyString.contains("text"))
        #expect(bodyString.contains("name=\"language\""))
        #expect(bodyString.contains("en"))
        #expect(!bodyString.contains("name=\"stream\""))
    }

    @Test("Bounded transcription uses standard completed-recording by default")
    @MainActor
    func boundedTranscriptionUsesStandardRequestModeByDefault() async throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("headcanon-transcription-default-\(UUID().uuidString)")
            .appendingPathExtension("m4a")
        try Data("fake audio".utf8).write(to: fileURL)
        defer {
            try? FileManager.default.removeItem(at: fileURL)
        }

        StandardTranscriptionURLProtocol.reset()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StandardTranscriptionURLProtocol.self]
        let backend = OpenAIBoundedTranscriptionBackend(
            modelProvider: { .gpt4oMiniTranscribe },
            session: URLSession(configuration: configuration)
        )

        let result = try await backend.transcribe(
            BoundedAudioInput(fileURL: fileURL, mimeType: "audio/m4a", duration: 1.0),
            apiKey: "test-key"
        )
        let capturedRequest = StandardTranscriptionURLProtocol.capturedRequests().first

        #expect(result.text == "hello from standard mode")
        #expect(result.responseMetadata?.requestMode == .standardCompletedRecording)
        #expect(result.responseMetadata?.fellBackFromStreaming == false)
        #expect(capturedRequest?.acceptHeader == "text/plain")
        #expect(capturedRequest?.bodyString.contains("name=\"response_format\"") == true)
        #expect(capturedRequest?.bodyString.contains("text") == true)
        #expect(capturedRequest?.bodyString.contains("name=\"stream\"") == false)
        #expect(StandardTranscriptionURLProtocol.capturedRequests().count == 1)
    }

    @Test("Empty bounded transcription body records body diagnostics")
    @MainActor
    func emptyBoundedTranscriptionBodyRecordsBodyDiagnostics() async throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("headcanon-transcription-empty-body-\(UUID().uuidString)")
            .appendingPathExtension("m4a")
        try Data("fake audio".utf8).write(to: fileURL)
        defer {
            try? FileManager.default.removeItem(at: fileURL)
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [EmptyBodyTranscriptionURLProtocol.self]
        let backend = OpenAIBoundedTranscriptionBackend(
            modelProvider: { .gpt4oMiniTranscribe },
            session: URLSession(configuration: configuration)
        )

        do {
            _ = try await backend.transcribe(
                BoundedAudioInput(fileURL: fileURL, mimeType: "audio/m4a", duration: 1.0),
                apiKey: "test-key"
            )
            Issue.record("Expected the backend to reject the empty response body.")
        } catch let TranscriptionBackendError.invalidResponse(context) {
            #expect(context?.httpStatusCode == 200)
            #expect(context?.transportFailureStage == .readingResponseBody)
            #expect(context?.responseBodyByteCount == 0)
            #expect(context?.responseBodyUTF8Decodable == true)
            #expect(context?.responseBodyTrimmedCharacterCount == 0)
            #expect(context?.responseContentLengthBytes == 0)
        } catch {
            Issue.record("Expected invalidResponse, received \(String(describing: error)).")
        }
    }

    @Test("Canceling bounded transcription cancels the in-flight URLSession task")
    @MainActor
    func cancelingBoundedTranscriptionCancelsInFlightRequest() async throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("headcanon-transcription-cancel-\(UUID().uuidString)")
            .appendingPathExtension("m4a")
        try Data("fake audio".utf8).write(to: fileURL)
        defer {
            try? FileManager.default.removeItem(at: fileURL)
        }

        HangingTranscriptionURLProtocol.reset()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [HangingTranscriptionURLProtocol.self]
        let backend = OpenAIBoundedTranscriptionBackend(
            modelProvider: { .gpt4oMiniTranscribe },
            session: URLSession(configuration: configuration)
        )

        let transcriptionTask = Task {
            try await backend.transcribe(
                BoundedAudioInput(fileURL: fileURL, mimeType: "audio/m4a", duration: 1.0),
                apiKey: "test-key"
            )
        }

        await HangingTranscriptionURLProtocol.waitUntilStarted()
        transcriptionTask.cancel()

        do {
            _ = try await transcriptionTask.value
            Issue.record("Expected cancellation to terminate the transcription task.")
        } catch is CancellationError {
            // Expected path.
        } catch {
            Issue.record("Expected CancellationError, received \(String(describing: error)).")
        }

        await HangingTranscriptionURLProtocol.waitUntilStopped()
        #expect(HangingTranscriptionURLProtocol.stopCount() == 1)
    }

}

@Suite("Head Canon Status Overlay")
struct HeadCanonStatusOverlayTests {
    @Test("Overlay geometry anchors to the bottom-right of the visible frame")
    func overlayGeometryAnchorsToVisibleFrame() {
        let visibleFrame = NSRect(x: 0, y: 0, width: 1728, height: 1084)

        let frame = StatusOverlayGeometry.targetFrame(in: visibleFrame)

        #expect(frame.origin.x == 1666)
        #expect(frame.origin.y == 18)
        #expect(frame.size.width == StatusOverlayGeometry.hudSize.width)
        #expect(frame.size.height == StatusOverlayGeometry.hudSize.height)
    }

    @Test("Overlay geometry respects non-zero screen origins")
    func overlayGeometrySupportsOffsetDisplays() {
        let visibleFrame = NSRect(x: -1512, y: 0, width: 1512, height: 982)

        let frame = StatusOverlayGeometry.targetFrame(in: visibleFrame)

        #expect(frame.origin.x == -62)
        #expect(frame.origin.y == 18)
        #expect(frame.maxX == visibleFrame.maxX - StatusOverlayGeometry.inset)
    }
}

@Suite("Head Canon Permission Debugger")
struct HeadCanonPermissionDebuggerTests {
    @Test("Permission debugger marks relaunch-pending trust as still untrusted after relaunch")
    @MainActor
    func permissionDebuggerDiagnosesStillUntrustedAfterRelaunch() {
        let suiteName = "HeadCanonPermissionDebugTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(true, forKey: PermissionDebugDefaultsKeys.accessibilityPrompted)
        defaults.set(true, forKey: PermissionDebugDefaultsKeys.accessibilityRelaunchRequested)

        let service = PermissionDebugService(
            defaults: defaults,
            accessibilityTrustEvaluator: { false }
        )

        let snapshot = service.snapshot(
            for: PermissionDebugContext(
                bundlePath: "/Applications/HeadCanon.app",
                bundleIdentifier: "local.headcanon.app",
                isInstalledBundle: true,
                microphoneState: .granted,
                accessibilityState: .pending,
                lastPermissionRefreshDate: nil,
                lastSelfTestDate: nil
            )
        )

        #expect(snapshot.diagnosis == .stillUntrustedAfterRelaunch)
    }

    @Test("Permission self-tests stop early when trust is unavailable")
    @MainActor
    func permissionSelfTestsFailCleanlyWithoutTrust() {
        let defaults = UserDefaults(suiteName: "HeadCanonPermissionDebugTests-\(UUID().uuidString)")!
        let service = PermissionDebugService(
            defaults: defaults,
            accessibilityTrustEvaluator: { false }
        )

        let snapshot = PermissionDebugSnapshot(
            bundlePath: "/Applications/HeadCanon.app",
            bundleIdentifier: "local.headcanon.app",
            isInstalledBundle: true,
            microphoneState: .granted,
            accessibilityState: .pending,
            accessibilityTrusted: false,
            accessibilityPrompted: true,
            accessibilityRelaunchRequested: false,
            lastPermissionRefreshDate: Date(),
            lastSelfTestDate: nil,
            diagnosis: .promptedAwaitingApproval
        )

        let results = service.runSelfTests(using: snapshot)

        #expect(results.count == 6)
        #expect(results[0].kind == .trustCheck)
        #expect(results[0].status == .failed)
        #expect(results[1].kind == .targetAppPrecondition)
        #expect(results[1].status == .failed)
    }

    @Test("Model surfaces permission debugger snapshot and full diagnostics report")
    @MainActor
    func modelSurfacesPermissionDebuggerState() {
        let snapshot = PermissionDebugSnapshot(
            bundlePath: "/Applications/HeadCanon.app",
            bundleIdentifier: "local.headcanon.app",
            isInstalledBundle: true,
            microphoneState: .granted,
            accessibilityState: .pending,
            accessibilityTrusted: false,
            accessibilityPrompted: true,
            accessibilityRelaunchRequested: true,
            lastPermissionRefreshDate: Date(timeIntervalSince1970: 1_715_000_000),
            lastSelfTestDate: nil,
            diagnosis: .stillUntrustedAfterRelaunch
        )

        let selfTests = [
            PermissionSelfTestResult(
                kind: .trustCheck,
                status: .failed,
                summary: "macOS does not currently report this app as trusted for Accessibility.",
                detail: "AXIsProcessTrusted() == false",
                observedAt: Date(timeIntervalSince1970: 1_715_000_010)
            )
        ]

        let model = HeadCanonModel(
            permissionsManager: StubPermissionsManager(
                snapshot: PermissionSnapshot(
                    microphone: .granted,
                    accessibility: .pending
                )
            ),
            permissionDebugService: StubPermissionDebugService(snapshot: snapshot, selfTests: selfTests),
            audioCaptureService: StubAudioCaptureService(),
            transcriptionBackend: StubTranscriptionBackend(),
            textInsertionService: StubTextInsertionService(),
            apiKeyStore: StubAPIKeyStore(apiKey: "test-key"),
            diagnosticsStore: NoOpDiagnosticsStore(),
            hotkeyManager: StubHotkeyManager()
        )

        model.refreshPermissions()
        model.runPermissionSelfTests()

        #expect(model.permissionDebugSnapshot.diagnosis == .stillUntrustedAfterRelaunch)
        #expect(model.permissionSelfTestResults == selfTests)
        #expect(model.diagnosticsReport.contains("Head Canon Diagnostics Report"))
        #expect(model.diagnosticsReport.contains("Accessibility diagnosis: Still Untrusted After Relaunch"))
        #expect(!model.diagnosticsReport.contains("- Title:"))
        #expect(!model.diagnosticsReport.contains("- Identifier:"))
    }

    @Test("Permission debugger does not collapse granted accessibility state when raw trust is false")
    @MainActor
    func permissionDebuggerSurfacesTrustMismatch() {
        let suiteName = "HeadCanonPermissionDebugTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let service = PermissionDebugService(
            defaults: defaults,
            accessibilityTrustEvaluator: { false }
        )

        let snapshot = service.snapshot(
            for: PermissionDebugContext(
                bundlePath: "/Applications/HeadCanon.app",
                bundleIdentifier: "local.headcanon.app",
                isInstalledBundle: true,
                microphoneState: .granted,
                accessibilityState: .granted,
                lastPermissionRefreshDate: nil,
                lastSelfTestDate: nil
            )
        )

        #expect(snapshot.diagnosis == .trustStateMismatch)
    }
}

@Suite("Head Canon API Key Storage")
struct HeadCanonAPIKeyStorageTests {
    @Test("Secure API key storage migrates legacy plaintext storage into the primary store")
    func secureAPIKeyStoreMigratesLegacyPlaintextKey() throws {
        let primaryStore = InMemoryAPIKeyStore()
        let legacyStore = InMemoryAPIKeyStore(initialValue: "sk-test-123")
        let store = SecureAPIKeyStore(primaryStore: primaryStore, legacyPlaintextStore: legacyStore)

        #expect(try store.loadAPIKey() == "sk-test-123")
        #expect(primaryStore.storedAPIKey == "sk-test-123")
        #expect(legacyStore.storedAPIKey == nil)
    }

    @Test("Secure API key storage removes legacy plaintext data on save")
    func secureAPIKeyStoreClearsLegacyPlaintextCopyOnSave() throws {
        let primaryStore = InMemoryAPIKeyStore()
        let legacyStore = InMemoryAPIKeyStore(initialValue: "stale-key")
        let store = SecureAPIKeyStore(primaryStore: primaryStore, legacyPlaintextStore: legacyStore)

        try store.saveAPIKey("sk-updated")

        #expect(primaryStore.storedAPIKey == "sk-updated")
        #expect(legacyStore.storedAPIKey == nil)
    }
}

@Suite("Head Canon Security")
struct HeadCanonSecurityTests {
    @Test("Never store clears retained transcript immediately")
    @MainActor
    func neverStoreClearsRetainedTranscript() {
        let preferences = testPreferences()
        let model = makeReadyModel(preferences: preferences)

        model.lastTranscript = "secret"
        model.preferences.historyRetentionMode = .neverStore
        model.applyPrivacyPreferences()

        #expect(model.lastTranscript == nil)
        #expect(!model.shouldRetainTranscript)
    }

    @Test("Dictation does not retain transcript when history is disabled")
    @MainActor
    func dictationSkipsTranscriptRetentionWhenNeverStoreIsSelected() async {
        let preferences = testPreferences()
        preferences.historyRetentionMode = .neverStore

        let hotkeyManager = StubHotkeyManager()
        let textInsertionService = RecordingTextInsertionService()
        let model = makeReadyModel(
            preferences: preferences,
            transcriptionBackend: StubTranscriptionBackend(transcript: "secret"),
            textInsertionService: textInsertionService,
            hotkeyManager: hotkeyManager
        )

        await model.bootstrap()
        hotkeyManager.press()
        hotkeyManager.release()
        await waitForWorkflowCompletion(model)

        #expect(model.workflowStatus == .inserted)
        #expect(model.lastTranscript == nil)
        #expect(textInsertionService.insertedTexts == ["secret"])
    }

    @Test("Dictation inserts into the target captured at hotkey release")
    @MainActor
    func dictationUsesCapturedInsertionTarget() async {
        let hotkeyManager = StubHotkeyManager()
        let textInsertionService = RecordingTextInsertionService()
        textInsertionService.focusedTarget = StubTextInsertionTargetHandle(id: "initial-target")

        let transcriptionBackend = DelayedTranscriptionBackend(transcript: "secret")
        let model = makeReadyModel(
            transcriptionBackend: transcriptionBackend,
            textInsertionService: textInsertionService,
            hotkeyManager: hotkeyManager
        )

        await model.bootstrap()
        hotkeyManager.press()
        hotkeyManager.release()

        await textInsertionService.waitUntilTargetCaptured()
        textInsertionService.focusedTarget = StubTextInsertionTargetHandle(id: "different-target")
        await transcriptionBackend.waitUntilStarted()
        transcriptionBackend.finishTranscription()

        await waitForWorkflowCompletion(model)

        #expect(model.workflowStatus == .inserted)
        #expect(textInsertionService.insertedTargets == ["initial-target"])
        #expect(textInsertionService.insertedTexts == ["secret"])
    }

    @Test("Low disk below the hard threshold blocks recording before it starts")
    @MainActor
    func lowDiskBlocksRecordingBeforeStart() async {
        let hotkeyManager = StubHotkeyManager()
        let audioCaptureService = StubAudioCaptureService()
        let diagnosticsStore = RecordingDiagnosticsStore()
        let model = makeReadyModel(
            audioCaptureService: audioCaptureService,
            diagnosticsStore: diagnosticsStore,
            hotkeyManager: hotkeyManager,
            diskSpaceChecker: StubDiskSpaceChecker(
                freeBytes: DiskSpacePolicy.gibibytes(1)
            )
        )

        await model.bootstrap()
        #expect(model.workflowStatus == .setupRequired)
        #expect(!model.isReady)
        hotkeyManager.press()

        for _ in 0..<20 {
            if model.lastAttemptTruthState == .systemReadinessBlocked {
                break
            }
            try? await Task.sleep(for: .milliseconds(10))
        }

        #expect(audioCaptureService.startCallCount == 0)
        #expect(model.workflowStatus == .setupRequired)
        #expect(model.lastFailureStage == .permissionReadiness)
        #expect(model.lastAttemptTruthState == .systemReadinessBlocked)
        #expect(model.lastErrorMessage == "Head Canon needs at least 2 GB free to record safely. Free up disk space and try again.")
        #expect(model.setupBlockers.contains { blocker in
            if case .diskSpaceLow = blocker {
                return true
            }
            return false
        })

        let persistedRecords = await diagnosticsStore.waitForRecordCount(1)
        #expect(persistedRecords.count == 1)
        #expect(persistedRecords.first?.truthState == .systemReadinessBlocked)
        #expect(persistedRecords.first?.failure?.stage == DiagnosticFailureStage.permissionReadiness.rawValue)

        let liveState = await diagnosticsStore.waitForLiveState { record in
            record.workflowStatus == WorkflowStatus.setupRequired.rawValue
                && record.lastFailureStage == DiagnosticFailureStage.permissionReadiness.rawValue
                && record.lastTruthState == DictationAttemptTruthState.systemReadinessBlocked.rawValue
        }
        #expect(liveState?.diskReadinessStatus == DiskSpaceStatus.blocked.title)
    }

    @Test("Low disk warning does not block recording")
    @MainActor
    func lowDiskWarningDoesNotBlockRecording() async {
        let hotkeyManager = StubHotkeyManager()
        let audioCaptureService = StubAudioCaptureService()
        let textInsertionService = RecordingTextInsertionService()
        let model = makeReadyModel(
            audioCaptureService: audioCaptureService,
            transcriptionBackend: StubTranscriptionBackend(transcript: "warning"),
            textInsertionService: textInsertionService,
            hotkeyManager: hotkeyManager,
            diskSpaceChecker: StubDiskSpaceChecker(
                freeBytes: DiskSpacePolicy.gibibytes(5)
            )
        )

        await model.bootstrap()
        hotkeyManager.press()
        hotkeyManager.release()
        await waitForWorkflowCompletion(model)

        #expect(audioCaptureService.startCallCount == 1)
        #expect(model.workflowStatus == .inserted)
        #expect(model.diskSpaceReadiness?.status == .warning)
        #expect(model.diskSpaceWarningMessage?.contains("Disk space is low") == true)
        #expect(textInsertionService.insertedTexts == ["warning"])
    }

    @Test("Head Canon reserve keeps readiness healthy when cache space is reclaimable")
    func diskReserveContributesToReadiness() throws {
        let checker = StubDiskSpaceChecker(
            freeBytes: DiskSpacePolicy.gibibytes(1)
        )
        let reserver = StubDiskSpaceReserver(
            reservedBytes: DiskSpacePolicy.gibibytes(2),
            targetBytes: DiskSpacePolicy.gibibytes(2),
            minimumRemainingFreeBytes: DiskSpacePolicy.gibibytes(10)
        )
        let service = DiskSpaceReadinessService(
            checker: checker,
            reserver: reserver,
            policy: .default,
            monitoredURL: FileManager.default.temporaryDirectory
        )

        let readiness = try service.currentReadiness()

        #expect(readiness.freeBytes == DiskSpacePolicy.gibibytes(1))
        #expect(readiness.reclaimableReserveBytes == DiskSpacePolicy.gibibytes(2))
        #expect(readiness.effectiveAvailableBytes == DiskSpacePolicy.gibibytes(3))
        #expect(readiness.status == .warning)
        #expect(readiness.warningMessage?.contains("reclaim") == true)
    }

    @Test("Low actual free space releases the Head Canon reserve before recording starts")
    @MainActor
    func lowActualFreeSpaceReleasesReserveBeforeRecording() async {
        let hotkeyManager = StubHotkeyManager()
        let audioCaptureService = StubAudioCaptureService()
        let checker = MutableDiskSpaceChecker(
            freeBytes: DiskSpacePolicy.gibibytes(1)
        )
        let reserver = StubDiskSpaceReserver(
            reservedBytes: DiskSpacePolicy.gibibytes(2),
            targetBytes: DiskSpacePolicy.gibibytes(2),
            minimumRemainingFreeBytes: DiskSpacePolicy.gibibytes(10),
            checker: checker
        )
        let model = makeReadyModel(
            audioCaptureService: audioCaptureService,
            hotkeyManager: hotkeyManager,
            diskSpaceChecker: checker,
            diskSpaceReserver: reserver
        )

        await model.bootstrap()
        #expect(model.workflowStatus == .ready)
        #expect(model.diskSpaceReadiness?.freeBytes == DiskSpacePolicy.gibibytes(1))
        #expect(model.diskSpaceReadiness?.reclaimableReserveBytes == DiskSpacePolicy.gibibytes(2))

        hotkeyManager.press()

        for _ in 0..<20 {
            if audioCaptureService.startCallCount > 0 {
                break
            }
            try? await Task.sleep(for: .milliseconds(10))
        }

        #expect(reserver.releaseCallCount == 1)
        #expect(checker.freeBytes == DiskSpacePolicy.gibibytes(3))
        #expect(audioCaptureService.startCallCount == 1)
        #expect(model.workflowStatus == .recording)
        #expect(model.diskSpaceReadiness?.reclaimableReserveBytes == 0)
    }

    @Test("Disk reserve manager allocates and releases a real cache reserve file")
    func diskReserveManagerAllocatesAndReleasesReserveFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("HeadCanonReserveTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDirectory)
        }

        let reserveFileURL = tempDirectory.appendingPathComponent("reserve.bin", isDirectory: false)
        let manager = DiskSpaceReserveManager(
            policy: DiskSpaceReservePolicy(
                targetReservationBytes: 1_024 * 1_024,
                minimumRemainingFreeBytes: 1_024 * 1_024
            ),
            reserveFileURL: reserveFileURL
        )

        let reserved = try manager.ensureReservation(freeBytes: 10 * 1_024 * 1_024)
        #expect(reserved.status == .reserved)
        #expect(reserved.reservedBytes >= 1_024 * 1_024)
        #expect(FileManager.default.fileExists(atPath: reserveFileURL.path))

        let released = try manager.releaseReservation(freeBytes: 10 * 1_024 * 1_024)
        #expect(released.status == .none)
        #expect(!FileManager.default.fileExists(atPath: reserveFileURL.path))
    }

    @Test("Recording safety limit finalizes when hotkey release is missed")
    @MainActor
    func recordingSafetyLimitFinalizesMissedRelease() async {
        let hotkeyManager = StubHotkeyManager()
        let audioCaptureService = StubAudioCaptureService()
        let textInsertionService = RecordingTextInsertionService()
        let model = makeReadyModel(
            audioCaptureService: audioCaptureService,
            transcriptionBackend: StubTranscriptionBackend(transcript: "rescued"),
            textInsertionService: textInsertionService,
            hotkeyManager: hotkeyManager,
            maximumRecordingDuration: .milliseconds(25)
        )

        await model.bootstrap()
        hotkeyManager.press()
        for _ in 0..<50 {
            if model.workflowStatus == .inserted || model.workflowStatus == .failed {
                break
            }
            try? await Task.sleep(for: .milliseconds(10))
        }

        #expect(model.workflowStatus == .inserted)
        #expect(!audioCaptureService.isRecording)
        #expect(textInsertionService.insertedTexts == ["rescued"])
        #expect(model.lastRecordingAttemptDiagnostics?.stopTrigger == .recordingDurationLimit)
    }

    @Test("Recording release watchdog finalizes when physical hotkey state is released")
    @MainActor
    func recordingReleaseWatchdogFinalizesMissedRelease() async {
        var hotkeyIsPressed = true
        let hotkeyManager = StubHotkeyManager()
        let audioCaptureService = StubAudioCaptureService()
        let textInsertionService = RecordingTextInsertionService()
        let model = makeReadyModel(
            audioCaptureService: audioCaptureService,
            transcriptionBackend: StubTranscriptionBackend(transcript: "watchdog"),
            textInsertionService: textInsertionService,
            hotkeyManager: hotkeyManager,
            hotkeyStateProvider: { _ in hotkeyIsPressed },
            maximumRecordingDuration: .seconds(30)
        )

        await model.bootstrap()
        hotkeyManager.press()
        hotkeyIsPressed = false

        for _ in 0..<50 {
            if model.workflowStatus == .inserted || model.workflowStatus == .failed {
                break
            }
            try? await Task.sleep(for: .milliseconds(10))
        }

        #expect(model.workflowStatus == .inserted)
        #expect(!audioCaptureService.isRecording)
        #expect(textInsertionService.insertedTexts == ["watchdog"])
        #expect(model.lastRecordingAttemptDiagnostics?.stopTrigger == .recordingReleaseWatchdog)
    }

    @Test("Late release after watchdog finalization does not add noisy diagnostics")
    @MainActor
    func lateReleaseAfterWatchdogFinalizationIsIgnored() async {
        var hotkeyIsPressed = true
        let hotkeyManager = StubHotkeyManager()
        let model = makeReadyModel(
            transcriptionBackend: StubTranscriptionBackend(transcript: "watchdog"),
            hotkeyManager: hotkeyManager,
            hotkeyStateProvider: { _ in hotkeyIsPressed },
            maximumRecordingDuration: .seconds(30)
        )

        await model.bootstrap()
        hotkeyManager.press()
        hotkeyIsPressed = false
        await waitForWorkflowCompletion(model)

        hotkeyManager.release(source: .globalModifierMonitor)
        try? await Task.sleep(for: .milliseconds(20))

        #expect(model.workflowStatus == .inserted)
        #expect(model.lastRecordingAttemptDiagnostics?.stopTrigger == .recordingReleaseWatchdog)
        #expect(!model.diagnosticEvents.contains { $0.summary.contains("without an active recording") })
    }

    @Test("Unexpected audio completion recovers and starts transcription")
    @MainActor
    func unexpectedAudioCompletionRecoversAndStartsTranscription() async {
        let hotkeyManager = StubHotkeyManager()
        let audioCaptureService = StubAudioCaptureService()
        let textInsertionService = RecordingTextInsertionService()
        let model = makeReadyModel(
            audioCaptureService: audioCaptureService,
            transcriptionBackend: StubTranscriptionBackend(transcript: "recovered"),
            textInsertionService: textInsertionService,
            hotkeyManager: hotkeyManager,
            hotkeyStateProvider: { _ in false }
        )

        await model.bootstrap()
        hotkeyManager.press()
        audioCaptureService.finishUnexpectedly(duration: 0.42)

        await waitForWorkflowCompletion(model)

        #expect(model.workflowStatus == .inserted)
        #expect(!audioCaptureService.isRecording)
        #expect(textInsertionService.insertedTexts == ["recovered"])
        #expect(model.lastRecordingAttemptDiagnostics?.stopTrigger == .unknown)
        #expect(model.lastRecordingAttemptDiagnostics?.recordingFinalizedAt != nil)
    }

    @Test("Recording watchdog clears stale recording state when audio already stopped")
    @MainActor
    func recordingWatchdogClearsStaleRecordingStateWhenAudioAlreadyStopped() async {
        let hotkeyManager = StubHotkeyManager()
        let audioCaptureService = StubAudioCaptureService()
        let model = makeReadyModel(
            audioCaptureService: audioCaptureService,
            hotkeyManager: hotkeyManager,
            hotkeyStateProvider: { _ in true }
        )

        await model.bootstrap()
        hotkeyManager.press()
        audioCaptureService.markStoppedWithoutCompletion()

        for _ in 0..<50 {
            if model.workflowStatus == .failed {
                break
            }
            try? await Task.sleep(for: .milliseconds(10))
        }

        #expect(model.workflowStatus == .failed)
        #expect(!audioCaptureService.isRecording)
        #expect(model.lastFailureStage == .recordingStop)
        #expect(model.lastRecordingAttemptDiagnostics?.recordingFinalizedAt == nil)
    }

    @Test("Disk-full recording finalization becomes actionable recording copy")
    @MainActor
    func diskFullRecordingFinalizationUsesActionableCopy() async {
        let hotkeyManager = StubHotkeyManager()
        let audioCaptureService = StubAudioCaptureService()
        audioCaptureService.stopError = AudioCaptureError.finalizationFailed("Disk Full")
        let diagnosticsStore = RecordingDiagnosticsStore()
        let model = makeReadyModel(
            audioCaptureService: audioCaptureService,
            diagnosticsStore: diagnosticsStore,
            hotkeyManager: hotkeyManager,
            diskSpaceChecker: StubDiskSpaceChecker(
                freeBytes: DiskSpacePolicy.gibibytes(3)
            )
        )

        await model.bootstrap()
        hotkeyManager.press()
        hotkeyManager.release()
        await waitForWorkflowCompletion(model)

        #expect(model.workflowStatus == .failed)
        #expect(model.lastFailureStage == .recordingStop)
        #expect(model.lastAttemptTruthState == .recordingFailed)
        #expect(model.lastErrorMessage == "Head Canon needs at least 2 GB free to record safely. Free up disk space and try again.")
        #expect(model.lastRecordingAttemptDiagnostics?.transcriptionRequestStartedAt == nil)

        let persistedRecords = await diagnosticsStore.waitForRecordCount(1)
        #expect(persistedRecords.first?.truthState == .recordingFailed)
        #expect(persistedRecords.first?.failure?.stage == DiagnosticFailureStage.recordingStop.rawValue)
        #expect(persistedRecords.first?.failure?.message.contains("Underlying recording error: Disk Full") == true)
    }

    @Test("Live diagnostics capture an in-progress recording state")
    @MainActor
    func liveDiagnosticsCaptureInProgressRecordingState() async {
        let hotkeyManager = StubHotkeyManager()
        let diagnosticsStore = RecordingDiagnosticsStore()
        let model = makeReadyModel(
            diagnosticsStore: diagnosticsStore,
            hotkeyManager: hotkeyManager,
            hotkeyStateProvider: { _ in true }
        )

        await model.bootstrap()
        hotkeyManager.press()

        let liveState = await diagnosticsStore.waitForLiveState { record in
            record.workflowStatus == WorkflowStatus.recording.rawValue
                && record.audioCaptureIsRecording
                && record.currentAttemptID != nil
        }

        #expect(liveState != nil)
        #expect(liveState?.hotkeyDisplayString == "Hold Control + Option")
        #expect(liveState?.hotkeyPhysicallyPressed == true)
        #expect(liveState?.recordingTiming?.recordingStartedAt != nil)
    }

    @Test("Manual finalize completes an active recording")
    @MainActor
    func manualFinalizeCompletesActiveRecording() async {
        let hotkeyManager = StubHotkeyManager()
        let audioCaptureService = StubAudioCaptureService()
        let textInsertionService = RecordingTextInsertionService()
        let model = makeReadyModel(
            audioCaptureService: audioCaptureService,
            transcriptionBackend: StubTranscriptionBackend(transcript: "manual"),
            textInsertionService: textInsertionService,
            hotkeyManager: hotkeyManager,
            hotkeyStateProvider: { _ in true }
        )

        await model.bootstrap()
        hotkeyManager.press()
        model.finalizeCurrentRecordingNow()

        await waitForWorkflowCompletion(model)

        #expect(model.workflowStatus == .inserted)
        #expect(textInsertionService.insertedTexts == ["manual"])
        #expect(model.lastRecordingAttemptDiagnostics?.stopTrigger == .unknown)
    }

    @Test("Manual cancel clears an active recording")
    @MainActor
    func manualCancelClearsActiveRecording() async {
        let hotkeyManager = StubHotkeyManager()
        let audioCaptureService = StubAudioCaptureService()
        let diagnosticsStore = RecordingDiagnosticsStore()
        let model = makeReadyModel(
            audioCaptureService: audioCaptureService,
            diagnosticsStore: diagnosticsStore,
            hotkeyManager: hotkeyManager
        )

        await model.bootstrap()
        hotkeyManager.press()
        model.cancelCurrentDictation()

        let records = await diagnosticsStore.waitForRecordCount(1)

        #expect(model.workflowStatus == .failed)
        #expect(!audioCaptureService.isRecording)
        #expect(model.lastAttemptTruthState == .transcriptionCanceled)
        #expect(records.first?.terminalState == .canceled)
    }

    @Test("Local status refresh does not revalidate the API key remotely")
    @MainActor
    func localStatusRefreshSkipsRemoteValidation() async {
        let transcriptionBackend = CountingTranscriptionBackend()
        let model = makeReadyModel(transcriptionBackend: transcriptionBackend)

        await model.bootstrap()
        #expect(transcriptionBackend.validateCallCount == 0)
        #expect(model.apiKeyState == .valid)

        await model.refreshRuntimeStatus(validateAPIKeyRemotely: false, presentSetupWindow: false)

        #expect(transcriptionBackend.validateCallCount == 0)
        #expect(model.apiKeyState == .valid)
    }

    @Test("Stored key remains usable when remote validation is offline")
    @MainActor
    func offlineValidationDoesNotBlockDictationWhenKeyExists() async {
        let model = makeReadyModel(transcriptionBackend: OfflineValidationTranscriptionBackend())

        await model.bootstrap()
        await model.refreshAPIKeyState(validateRemotely: true, presentSetupWindow: false)

        #expect(model.apiKeyState == .networkUnavailable("Head Canon could not reach OpenAI to validate the key."))
        #expect(model.setupBlockers.isEmpty)
        #expect(model.isReady)
    }

    @Test("Unvalidated stored key remains blocked until explicitly checked")
    @MainActor
    func unvalidatedStoredKeyBlocksDictation() async {
        let model = HeadCanonModel(
            permissionsManager: StubPermissionsManager(
                snapshot: PermissionSnapshot(
                    microphone: .granted,
                    accessibility: .granted
                )
            ),
            audioCaptureService: StubAudioCaptureService(),
            transcriptionBackend: StubTranscriptionBackend(),
            textInsertionService: StubTextInsertionService(),
            apiKeyStore: StubAPIKeyStore(apiKey: "test-key"),
            diagnosticsStore: NoOpDiagnosticsStore(),
            hotkeyManager: StubHotkeyManager()
        )

        await model.refreshRuntimeStatus(validateAPIKeyRemotely: false, presentSetupWindow: false)

        #expect(model.apiKeyState == .unvalidated)
        #expect(model.setupBlockers == [.apiKeyValidationRequired])
        #expect(!model.isReady)
    }

    @Test("Keychain load failure surfaces as a blocker instead of missing key")
    @MainActor
    func keychainLoadFailureSurfacesExplicitBlocker() async {
        let model = HeadCanonModel(
            permissionsManager: StubPermissionsManager(
                snapshot: PermissionSnapshot(
                    microphone: .granted,
                    accessibility: .granted
                )
            ),
            audioCaptureService: StubAudioCaptureService(),
            transcriptionBackend: StubTranscriptionBackend(),
            textInsertionService: StubTextInsertionService(),
            apiKeyStore: FailingAPIKeyStore(loadError: APIKeyStoreError.loadFailed(errSecInteractionNotAllowed)),
            diagnosticsStore: NoOpDiagnosticsStore(),
            hotkeyManager: StubHotkeyManager()
        )

        await model.refreshRuntimeStatus(validateAPIKeyRemotely: false, presentSetupWindow: false)

        #expect(model.apiKeyState == .keychainError(APIKeyStoreError.loadFailed(errSecInteractionNotAllowed).localizedDescription))
        #expect(model.setupBlockers == [.apiKeyStoreError(APIKeyStoreError.loadFailed(errSecInteractionNotAllowed).localizedDescription)])
        #expect(!model.isReady)
    }

    @Test("Cached validation restores valid API key state locally")
    @MainActor
    func cachedValidationRestoresAPIKeyStateLocally() async {
        let preferences = testPreferences()
        let cachedDate = Date(timeIntervalSince1970: 1_715_000_000)
        preferences.persistValidatedAPIKey("test-key", validatedAt: cachedDate)

        let transcriptionBackend = CountingTranscriptionBackend()
        let model = makeReadyModel(
            preferences: preferences,
            transcriptionBackend: transcriptionBackend
        )

        await model.refreshRuntimeStatus(validateAPIKeyRemotely: false, presentSetupWindow: false)

        #expect(model.apiKeyState == .valid)
        #expect(model.lastValidationDate == cachedDate)
        #expect(model.isReady)
        #expect(transcriptionBackend.validateCallCount == 0)
    }

    @Test("Status refresh does not repeatedly hit the keychain after bootstrap")
    @MainActor
    func statusRefreshUsesCachedAPIKeyAfterBootstrap() async {
        let apiKeyStore = CountingAPIKeyStore(apiKey: "test-key")
        let model = HeadCanonModel(
            permissionsManager: StubPermissionsManager(
                snapshot: PermissionSnapshot(
                    microphone: .granted,
                    accessibility: .granted
                )
            ),
            audioCaptureService: StubAudioCaptureService(),
            transcriptionBackend: StubTranscriptionBackend(),
            textInsertionService: StubTextInsertionService(),
            apiKeyStore: apiKeyStore,
            diagnosticsStore: NoOpDiagnosticsStore(),
            hotkeyManager: StubHotkeyManager()
        )

        await model.bootstrap()
        let loadCountAfterBootstrap = apiKeyStore.loadCallCount

        await model.refreshRuntimeStatus(validateAPIKeyRemotely: false, presentSetupWindow: false)
        _ = model.isReady
        _ = model.setupBlockers

        #expect(loadCountAfterBootstrap == 1)
        #expect(apiKeyStore.loadCallCount == loadCountAfterBootstrap)
    }

    @Test("Transcription auth failure invalidates the cached key state")
    @MainActor
    func transcriptionAuthFailureInvalidatesAPIKeyState() async {
        let hotkeyManager = StubHotkeyManager()
        let model = makeReadyModel(
            transcriptionBackend: InvalidAPIKeyTranscriptionBackend(),
            hotkeyManager: hotkeyManager
        )

        await model.bootstrap()
        hotkeyManager.press()
        hotkeyManager.release()
        await waitForWorkflowCompletion(model)

        #expect(model.workflowStatus == .failed)
        #expect(model.apiKeyState == .invalid("The stored OpenAI API key was rejected."))
        #expect(model.lastFailureStage == .transcription)
    }

    @Test("Disabling paste fallback is enforced during insertion")
    @MainActor
    func pasteFallbackPreferenceDisablesFallback() async {
        let preferences = testPreferences()
        preferences.pasteFallbackEnabled = false

        let hotkeyManager = StubHotkeyManager()
        let textInsertionService = RecordingTextInsertionService()
        let clipboardWriter = RecordingClipboardWriter()
        let model = makeReadyModel(
            preferences: preferences,
            textInsertionService: textInsertionService,
            hotkeyManager: hotkeyManager,
            clipboardWriter: clipboardWriter
        )

        await model.bootstrap()
        hotkeyManager.press()
        hotkeyManager.release()
        await waitForWorkflowCompletion(model)

        #expect(model.workflowStatus == .failed)
        #expect(model.lastErrorMessage == "\(TextInsertionError.pasteFallbackDisabled.localizedDescription) Transcript copied to clipboard for manual paste.")
        #expect(textInsertionService.lastAllowPasteFallback == false)
        #expect(clipboardWriter.writes == ["stub"])
        #expect(model.lastFailureStage == .insertion)
    }

    @Test("Insertion failure copies the transcript to the clipboard for recovery")
    @MainActor
    func insertionFailureCopiesTranscriptToClipboard() async {
        let hotkeyManager = StubHotkeyManager()
        let textInsertionService = RecordingTextInsertionService()
        textInsertionService.insertError = TextInsertionError.pasteFailed
        let diagnosticsStore = RecordingDiagnosticsStore()
        let clipboardWriter = RecordingClipboardWriter()
        let model = makeReadyModel(
            textInsertionService: textInsertionService,
            diagnosticsStore: diagnosticsStore,
            hotkeyManager: hotkeyManager,
            clipboardWriter: clipboardWriter
        )

        await model.bootstrap()
        hotkeyManager.press()
        hotkeyManager.release()
        await waitForWorkflowCompletion(model)

        #expect(model.workflowStatus == .failed)
        #expect(clipboardWriter.writes == ["stub"])
        #expect(model.lastClipboardRecovery == ClipboardRecoveryState(transcriptCopied: true, reason: .insertionFailure))

        let persistedRecords = await diagnosticsStore.waitForRecordCount(1)
        #expect(persistedRecords.first?.clipboardRecovery?.transcriptCopied == true)
        #expect(persistedRecords.first?.clipboardRecovery?.reason == ClipboardRecoveryReason.insertionFailure.rawValue)
    }

    @Test("Missing insertion target copies the transcript to the clipboard for recovery")
    @MainActor
    func missingInsertionTargetCopiesTranscriptToClipboard() async {
        let hotkeyManager = StubHotkeyManager()
        let textInsertionService = RecordingTextInsertionService()
        textInsertionService.captureError = TextInsertionError.focusUnavailable
        let diagnosticsStore = RecordingDiagnosticsStore()
        let clipboardWriter = RecordingClipboardWriter()
        let model = makeReadyModel(
            textInsertionService: textInsertionService,
            diagnosticsStore: diagnosticsStore,
            hotkeyManager: hotkeyManager,
            clipboardWriter: clipboardWriter
        )

        await model.bootstrap()
        hotkeyManager.press()
        hotkeyManager.release()
        await waitForWorkflowCompletion(model)

        #expect(model.workflowStatus == .failed)
        #expect(clipboardWriter.writes == ["stub"])
        #expect(model.lastClipboardRecovery == ClipboardRecoveryState(transcriptCopied: true, reason: .missingInsertionTarget))

        let persistedRecords = await diagnosticsStore.waitForRecordCount(1)
        #expect(persistedRecords.first?.clipboardRecovery?.reason == ClipboardRecoveryReason.missingInsertionTarget.rawValue)
    }

    @Test("Transcription failure does not copy transcript to the clipboard")
    @MainActor
    func transcriptionFailureDoesNotCopyTranscriptToClipboard() async {
        let hotkeyManager = StubHotkeyManager()
        let clipboardWriter = RecordingClipboardWriter()
        let model = makeReadyModel(
            transcriptionBackend: FailingTranscriptionBackend(error: .networkUnavailable()),
            hotkeyManager: hotkeyManager,
            clipboardWriter: clipboardWriter
        )

        await model.bootstrap()
        hotkeyManager.press()
        hotkeyManager.release()
        await waitForWorkflowCompletion(model)

        #expect(model.workflowStatus == .failed)
        #expect(clipboardWriter.writes.isEmpty)
        #expect(model.lastClipboardRecovery == nil)
    }

    @Test("Focused insertion analysis stores a routing report")
    @MainActor
    func focusedInsertionAnalysisStoresRoutingReport() async {
        let textInsertionService = RecordingTextInsertionService()
        let model = makeReadyModel(textInsertionService: textInsertionService)

        await model.bootstrap()
        model.analyzeFocusedInsertionTarget()
        await waitForInsertionAnalysis(model)

        #expect(model.lastInsertionAttemptReport?.capabilities.applicationName == "Stub App")
        #expect(model.lastInsertionAttemptReport?.chosenStrategy == .customEditorPaste)
        #expect(model.lastInsertionAttemptReport?.observationLabel == "Analysis-Time Context")
        #expect(model.lastDiagnosticEvent?.stage == .insertion)
    }

    @Test("Paste Last Transcript respects the paste fallback preference")
    @MainActor
    func pasteLastTranscriptHonorsFallbackPreference() async {
        let preferences = testPreferences()
        preferences.pasteFallbackEnabled = false

        let textInsertionService = RecordingTextInsertionService()
        textInsertionService.supportsDirectInsert = true
        let diagnosticsStore = RecordingDiagnosticsStore()
        let model = makeReadyModel(
            preferences: preferences,
            textInsertionService: textInsertionService,
            diagnosticsStore: diagnosticsStore
        )

        await model.refreshRuntimeStatus(validateAPIKeyRemotely: false, presentSetupWindow: false)
        model.lastTranscript = "secret"
        model.pasteLastTranscript()
        await waitForWorkflowCompletion(model)

        #expect(model.workflowStatus == .inserted)
        #expect(model.lastAttemptTruthState == .verifiedInsert)
        #expect(textInsertionService.insertedTexts == ["secret"])
        #expect(textInsertionService.lastAllowPasteFallback == false)
        let persistedRecords = await diagnosticsStore.waitForRecordCount(1)
        #expect(persistedRecords.first?.terminalState == .inserted)
        #expect(persistedRecords.first?.truthState == .verifiedInsert)
        #expect(persistedRecords.first?.insertion?.observationLabel == "Current Context")
    }

    @Test("Audio capture startup cleanup removes stale app recordings")
    @MainActor
    func audioCaptureStartupRemovesStaleRecordings() throws {
        let fileManager = FileManager.default
        let staleDirectory = AudioCaptureService.recordingsDirectoryURL

        try fileManager.createDirectory(at: staleDirectory, withIntermediateDirectories: true)

        let staleFileURL = staleDirectory.appendingPathComponent("head-canon-stale").appendingPathExtension("m4a")
        try Data("stale".utf8).write(to: staleFileURL)
        #expect(fileManager.fileExists(atPath: staleFileURL.path))

        _ = AudioCaptureService()

        #expect(!fileManager.fileExists(atPath: staleFileURL.path))
    }

    @Test("User can manually clear retained transcript")
    @MainActor
    func clearLastTranscriptRemovesSessionState() {
        let model = makeReadyModel()

        model.lastTranscript = "secret"
        model.clearLastTranscript()

        #expect(model.lastTranscript == nil)
    }

    @Test("User can copy retained transcript for manual recovery")
    @MainActor
    func copyLastTranscriptWritesToClipboard() {
        let clipboardWriter = RecordingClipboardWriter()
        let model = makeReadyModel(clipboardWriter: clipboardWriter)

        model.lastTranscript = "secret"
        model.copyLastTranscript()

        #expect(clipboardWriter.writes == ["secret"])
        #expect(model.lastClipboardRecovery?.transcriptCopied == true)
        #expect(model.lastDiagnosticEvent?.summary == "Copied the last transcript to the clipboard for manual recovery.")
    }

    @Test("Hotkey while blocked records permission readiness failure")
    @MainActor
    func blockedHotkeyRecordsPermissionFailureStage() async {
        let hotkeyManager = StubHotkeyManager()
        let model = HeadCanonModel(
            permissionsManager: StubPermissionsManager(
                snapshot: PermissionSnapshot(
                    microphone: .granted,
                    accessibility: .pending
                )
            ),
            audioCaptureService: StubAudioCaptureService(),
            transcriptionBackend: StubTranscriptionBackend(),
            textInsertionService: StubTextInsertionService(),
            apiKeyStore: StubAPIKeyStore(apiKey: "test-key"),
            diagnosticsStore: NoOpDiagnosticsStore(),
            hotkeyManager: hotkeyManager
        )

        await model.bootstrap()
        hotkeyManager.press()

        #expect(model.workflowStatus == .setupRequired)
        #expect(model.lastFailureStage == .permissionReadiness)
        #expect(model.lastDiagnosticEvent?.isFailure == true)
    }

    @Test("Successful dictation records insertion success in diagnostics")
    @MainActor
    func successfulDictationRecordsDiagnosticTrail() async {
        let hotkeyManager = StubHotkeyManager()
        let textInsertionService = RecordingTextInsertionService()
        let diagnosticsStore = RecordingDiagnosticsStore()
        let model = makeReadyModel(
            textInsertionService: textInsertionService,
            diagnosticsStore: diagnosticsStore,
            hotkeyManager: hotkeyManager
        )

        await model.bootstrap()
        hotkeyManager.press()
        hotkeyManager.release()
        await waitForWorkflowCompletion(model)

        #expect(model.workflowStatus == .inserted)
        #expect(model.lastCapturedInsertionReport?.observationLabel == "Release-Time Context")
        #expect(model.lastInsertionAttemptReport?.observationLabel == "Insert-Time Context")
        #expect(textInsertionService.executionPlanningCallCount == 1)
        #expect(model.lastInsertionAttemptReport?.capabilities.contextKind == .axFocusedElement)
        #expect(model.lastInsertionAttemptReport?.capabilities.capabilityProfile == .partialAXEditor)
        #expect(model.lastRecordingAttemptDiagnostics?.stopTrigger == .carbonKeyUp)
        #expect(model.lastRecordingAttemptDiagnostics?.clipDuration == 1.25)
        #expect(model.lastRecordingAttemptDiagnostics?.finalizingStateShownAt != nil)
        #expect(model.lastRecordingAttemptDiagnostics?.transcriptionRequestStartedAt != nil)
        #expect(model.lastRecordingAttemptDiagnostics?.transcriptionResponseCompletedAt != nil)
        #expect(model.lastRecordingAttemptDiagnostics?.insertionCompletedAt != nil)
        #expect(model.lastRecordingAttemptDiagnostics?.releaseToFinalizedDuration != nil)
        #expect(model.lastRecordingAttemptDiagnostics?.requestToResponseDuration != nil)
        #expect(model.lastRecordingAttemptDiagnostics?.releaseToInsertionDuration != nil)
        #expect(model.lastRecordingAttemptDiagnostics?.transcriptCharacterCount == 4)
        #expect(model.lastRecordingAttemptDiagnostics?.transcriptWordCount == 1)
        #expect(model.diagnosticsReport.contains("Latest recording attempt:"))
        #expect(model.diagnosticsReport.contains("Last truth state: Verified Insert"))
        #expect(model.diagnosticsReport.contains("Stop trigger: Carbon Key-Up"))
        #expect(model.diagnosticsReport.contains("Finalizing state shown at:"))
        #expect(model.diagnosticsReport.contains("Release to recording finalized:"))
        #expect(model.diagnosticsReport.contains("Request start to response complete:"))
        #expect(model.lastAttemptTruthState == .verifiedInsert)
        #expect(model.lastDiagnosticEvent?.summary == "Transcript inserted and verified in the intended target context.")
        #expect(model.lastDiagnosticEvent?.stage == .insertion)

        let persistedRecords = await diagnosticsStore.waitForRecordCount(1)
        #expect(persistedRecords.count == 1)
        #expect(persistedRecords.first?.terminalState == .inserted)
        #expect(persistedRecords.first?.truthState == .verifiedInsert)
        #expect(persistedRecords.first?.backend.identifier == "stub")
        #expect(persistedRecords.first?.releaseTimeInsertion?.observationLabel == "Release-Time Context")
        #expect(persistedRecords.first?.insertion?.appliedStrategy == InsertionStrategy.customEditorPaste.rawValue)
        #expect(persistedRecords.first?.insertion?.verificationOutcome == InsertionVerificationOutcome.verified.rawValue)
        #expect(persistedRecords.first?.failure == nil)

        let settledLiveState = await diagnosticsStore.waitForLiveState { record in
            record.workflowStatus == WorkflowStatus.inserted.rawValue
                && record.currentAttemptID == nil
                && record.activeTranscriptionAttemptID == nil
        }
        #expect(settledLiveState != nil)
    }

    @Test("Unverified insertion records an honest truth state")
    @MainActor
    func unverifiedInsertionRecordsHonestTruthState() async {
        let hotkeyManager = StubHotkeyManager()
        let textInsertionService = RecordingTextInsertionService()
        textInsertionService.insertVerificationOutcome = .unverified
        let diagnosticsStore = RecordingDiagnosticsStore()
        let model = makeReadyModel(
            textInsertionService: textInsertionService,
            diagnosticsStore: diagnosticsStore,
            hotkeyManager: hotkeyManager
        )

        await model.bootstrap()
        hotkeyManager.press()
        hotkeyManager.release()
        await waitForWorkflowCompletion(model)

        #expect(model.workflowStatus == .inserted)
        #expect(model.lastAttemptTruthState == .unverifiedInsert)
        #expect(model.checkpointSummary == DictationAttemptTruthState.unverifiedInsert.detail)
        #expect(model.lastDiagnosticEvent?.summary == "Head Canon pasted into the intended target context, but could not verify the resulting field contents.")

        let persistedRecords = await diagnosticsStore.waitForRecordCount(1)
        #expect(persistedRecords.first?.terminalState == .inserted)
        #expect(persistedRecords.first?.truthState == .unverifiedInsert)
        #expect(persistedRecords.first?.insertion?.verificationOutcome == InsertionVerificationOutcome.unverified.rawValue)
    }

    @Test("Missing execution verification metadata stays unverified")
    @MainActor
    func missingExecutionVerificationMetadataStaysUnverified() async {
        let hotkeyManager = StubHotkeyManager()
        let textInsertionService = RecordingTextInsertionService()
        textInsertionService.omitExecutionVerificationOutcome = true
        let diagnosticsStore = RecordingDiagnosticsStore()
        let model = makeReadyModel(
            textInsertionService: textInsertionService,
            diagnosticsStore: diagnosticsStore,
            hotkeyManager: hotkeyManager
        )

        await model.bootstrap()
        hotkeyManager.press()
        hotkeyManager.release()
        await waitForWorkflowCompletion(model)

        #expect(model.workflowStatus == .inserted)
        #expect(model.lastAttemptTruthState == .unverifiedInsert)
        #expect(model.lastDiagnosticEvent?.summary == "Head Canon pasted into the intended target context, but could not verify the resulting field contents.")

        let persistedRecords = await diagnosticsStore.waitForRecordCount(1)
        #expect(persistedRecords.first?.terminalState == .inserted)
        #expect(persistedRecords.first?.truthState == .unverifiedInsert)
        #expect(persistedRecords.first?.insertion?.verificationOutcome == nil)
    }

    @Test("Concrete diagnostics store writes latest record and clears persisted files")
    func diagnosticsStorePersistsAndClearsFiles() async throws {
        let tempRootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("HeadCanonDiagnosticsTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRootURL, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempRootURL)
        }

        let store = DiagnosticsStore(appSupportDirectoryURL: tempRootURL, maxLogFileBytes: 8_192, maxRotatedFiles: 2)
        let record = sampleAttemptRecord()

        try await store.persist(record)

        let directoryURL = try await store.diagnosticsDirectoryURL()
        let latestURL = directoryURL.appendingPathComponent("latest.json", isDirectory: false)
        let attemptsURL = directoryURL.appendingPathComponent("attempts.jsonl", isDirectory: false)

        #expect(FileManager.default.fileExists(atPath: latestURL.path))
        #expect(FileManager.default.fileExists(atPath: attemptsURL.path))
        #expect(try await store.latestRecord() == record)

        try await store.clear()

        let remainingItems = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
        #expect(remainingItems.isEmpty)
    }

    @Test("Diagnostics store decodes legacy records by inferring the truth state")
    func diagnosticsStoreDecodesLegacyRecords() async throws {
        let tempRootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("HeadCanonLegacyDiagnosticsTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRootURL, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempRootURL)
        }

        let store = DiagnosticsStore(appSupportDirectoryURL: tempRootURL, maxLogFileBytes: 8_192, maxRotatedFiles: 2)
        let directoryURL = try await store.diagnosticsDirectoryURL()
        let latestURL = directoryURL.appendingPathComponent("latest.json", isDirectory: false)

        try legacyAttemptRecordData(
            from: sampleAttemptRecord(),
            schemaVersion: 2,
            truthState: nil
        ).write(to: latestURL, options: [.atomic])

        let decodedRecord = try await store.latestRecord()
        #expect(decodedRecord?.truthState == .verifiedInsert)
    }

    @Test("Hung transcription times out and leaves transcribing state")
    @MainActor
    func hungTranscriptionTimesOut() async {
        let hotkeyManager = StubHotkeyManager()
        let transcriptionBackend = DelayedTranscriptionBackend(transcript: "late")
        let diagnosticsStore = RecordingDiagnosticsStore()
        let model = makeReadyModel(
            transcriptionBackend: transcriptionBackend,
            diagnosticsStore: diagnosticsStore,
            hotkeyManager: hotkeyManager,
            transcriptionTimeout: .milliseconds(50)
        )

        await model.bootstrap()
        hotkeyManager.press()
        hotkeyManager.release()
        await transcriptionBackend.waitUntilStarted()

        for _ in 0..<50 {
            if model.workflowStatus == WorkflowStatus.failed {
                break
            }
            try? await Task.sleep(for: .milliseconds(10))
        }

        #expect(model.workflowStatus == WorkflowStatus.failed)
        #expect(model.lastFailureStage == DiagnosticFailureStage.transcription)
        #expect(model.lastErrorMessage == "Head Canon stopped waiting for transcription after 0.05 seconds.")
        #expect(model.lastRecordingAttemptDiagnostics?.transcriptionRequestStartedAt != nil)
        #expect(model.lastRecordingAttemptDiagnostics?.transcriptionResponseCompletedAt != nil)
        await transcriptionBackend.waitUntilCancelled()
        #expect(transcriptionBackend.cancellationCount == 1)

        let failedLiveRecord = await diagnosticsStore.waitForLiveState {
            $0.workflowStatus == WorkflowStatus.failed.rawValue
        }
        #expect(failedLiveRecord?.activeTranscriptionAttemptID == nil)
    }

    @Test("Failed transcription records transport diagnostics")
    @MainActor
    func failedTranscriptionRecordsTransportDiagnostics() async {
        let hotkeyManager = StubHotkeyManager()
        let backend = FailingTranscriptionBackend(
            error: .networkUnavailable(
                TranscriptionFailureContext(
                    requestMode: .standardCompletedRecording,
                    fellBackFromStreaming: false,
                    httpStatusCode: nil,
                    requestID: nil,
                    openAIProcessingMS: nil,
                    contentType: nil,
                    responseHeadersReceivedMS: 420,
                    transportFailureStage: .awaitingResponseHeaders,
                    networkErrorDomain: NSURLErrorDomain,
                    networkErrorCode: URLError.Code.timedOut.rawValue,
                    networkErrorCodeName: String(describing: URLError.Code.timedOut)
                )
            )
        )
        let diagnosticsStore = RecordingDiagnosticsStore()
        let model = makeReadyModel(
            transcriptionBackend: backend,
            diagnosticsStore: diagnosticsStore,
            hotkeyManager: hotkeyManager
        )

        await model.bootstrap()
        hotkeyManager.press()
        hotkeyManager.release()
        await waitForWorkflowCompletion(model)

        #expect(model.workflowStatus == WorkflowStatus.failed)
        #expect(model.lastFailureStage == DiagnosticFailureStage.transcription)
        #expect(model.lastRecordingAttemptDiagnostics?.transcriptionRequestMode == "Standard Completed Recording")
        #expect(model.lastRecordingAttemptDiagnostics?.transcriptionResponseHeadersReceivedMS == 420)
        #expect(model.lastRecordingAttemptDiagnostics?.transcriptionTransportFailureStage == "awaitingResponseHeaders")
        #expect(model.lastRecordingAttemptDiagnostics?.transcriptionNetworkErrorDomain == NSURLErrorDomain)
        #expect(model.lastRecordingAttemptDiagnostics?.transcriptionNetworkErrorCode == URLError.Code.timedOut.rawValue)

        let persistedRecords = await diagnosticsStore.waitForRecordCount(1)
        #expect(persistedRecords.first?.backend.requestMode == "Standard Completed Recording")
        #expect(persistedRecords.first?.backend.responseHeadersReceivedMS == 420)
        #expect(persistedRecords.first?.backend.transportFailureStage == "awaitingResponseHeaders")
        #expect(persistedRecords.first?.backend.networkErrorCode == URLError.Code.timedOut.rawValue)
    }

    @Test("Invalid transcription response records response body diagnostics")
    @MainActor
    func invalidTranscriptionResponseRecordsBodyDiagnostics() async {
        let hotkeyManager = StubHotkeyManager()
        let backend = FailingTranscriptionBackend(
            error: .invalidResponse(
                TranscriptionFailureContext(
                    requestMode: .standardCompletedRecording,
                    fellBackFromStreaming: false,
                    httpStatusCode: 200,
                    requestID: "req_empty_body",
                    openAIProcessingMS: 77,
                    contentType: "text/plain; charset=utf-8",
                    responseHeadersReceivedMS: 901,
                    transportFailureStage: .readingResponseBody,
                    networkErrorDomain: nil,
                    networkErrorCode: nil,
                    networkErrorCodeName: nil,
                    responseBodyByteCount: 0,
                    responseBodyUTF8Decodable: true,
                    responseBodyTrimmedCharacterCount: 0,
                    responseContentLengthBytes: 0
                )
            )
        )
        let diagnosticsStore = RecordingDiagnosticsStore()
        let model = makeReadyModel(
            transcriptionBackend: backend,
            diagnosticsStore: diagnosticsStore,
            hotkeyManager: hotkeyManager
        )

        await model.bootstrap()
        hotkeyManager.press()
        hotkeyManager.release()
        await waitForWorkflowCompletion(model)

        #expect(model.workflowStatus == WorkflowStatus.failed)
        #expect(model.lastFailureStage == DiagnosticFailureStage.transcription)
        #expect(model.lastRecordingAttemptDiagnostics?.transcriptionResponseBodyByteCount == 0)
        #expect(model.lastRecordingAttemptDiagnostics?.transcriptionResponseBodyUTF8Decodable == true)
        #expect(model.lastRecordingAttemptDiagnostics?.transcriptionResponseBodyTrimmedCharacterCount == 0)
        #expect(model.lastRecordingAttemptDiagnostics?.transcriptionResponseContentLengthBytes == 0)

        let persistedRecords = await diagnosticsStore.waitForRecordCount(1)
        #expect(persistedRecords.first?.backend.responseBodyByteCount == 0)
        #expect(persistedRecords.first?.backend.responseBodyUTF8Decodable == true)
        #expect(persistedRecords.first?.backend.responseBodyTrimmedCharacterCount == 0)
        #expect(persistedRecords.first?.backend.responseContentLengthBytes == 0)
    }

    @Test("Transient transcription request failure retries once and inserts only once")
    @MainActor
    func transientTranscriptionFailureRetriesOnce() async {
        let hotkeyManager = StubHotkeyManager()
        let textInsertionService = RecordingTextInsertionService()
        let diagnosticsStore = RecordingDiagnosticsStore()
        let backend = SequencedTranscriptionBackend(results: [
            .failure(
                .networkUnavailable(
                    TranscriptionFailureContext(
                        requestMode: .standardCompletedRecording,
                        fellBackFromStreaming: false,
                        httpStatusCode: nil,
                        requestID: nil,
                        openAIProcessingMS: nil,
                        contentType: nil,
                        responseHeadersReceivedMS: nil,
                        transportFailureStage: .awaitingResponseHeaders,
                        networkErrorDomain: NSURLErrorDomain,
                        networkErrorCode: URLError.Code.timedOut.rawValue,
                        networkErrorCodeName: String(describing: URLError.Code.timedOut)
                    )
                )
            ),
            .success(
                TranscriptionResult(
                    text: "recovered",
                    backendID: "sequenced",
                    duration: nil,
                    responseMetadata: TranscriptionResponseMetadata(
                        requestMode: .standardCompletedRecording,
                        fellBackFromStreaming: false,
                        httpStatusCode: 200,
                        requestID: "req_retry_success",
                        openAIProcessingMS: 120,
                        contentType: "text/plain",
                        responseHeadersReceivedMS: 400
                    )
                )
            ),
        ])
        let model = makeReadyModel(
            transcriptionBackend: backend,
            textInsertionService: textInsertionService,
            diagnosticsStore: diagnosticsStore,
            hotkeyManager: hotkeyManager
        )

        await model.bootstrap()
        hotkeyManager.press()
        hotkeyManager.release()
        await waitForWorkflowCompletion(model)

        #expect(model.workflowStatus == .inserted)
        #expect(backend.transcribeCallCount == 2)
        #expect(textInsertionService.insertedTexts == ["recovered"])
        #expect(model.lastRecordingAttemptDiagnostics?.transcriptionRequestID == "req_retry_success")
        #expect(model.diagnosticEvents.contains(where: { $0.summary.contains("Retrying transcription after a transient transport failure.") }))

        let persistedRecords = await diagnosticsStore.waitForRecordCount(1)
        #expect(persistedRecords.first?.terminalState == .inserted)
        #expect(persistedRecords.first?.transcript.characterCount == 9)
    }

    @Test("Empty transcription response retries once before failing")
    @MainActor
    func emptyTranscriptionResponseRetriesOnce() async {
        let hotkeyManager = StubHotkeyManager()
        let textInsertionService = RecordingTextInsertionService()
        let diagnosticsStore = RecordingDiagnosticsStore()
        let backend = SequencedTranscriptionBackend(results: [
            .failure(
                .invalidResponse(
                    TranscriptionFailureContext(
                        requestMode: .standardCompletedRecording,
                        fellBackFromStreaming: false,
                        httpStatusCode: 200,
                        requestID: "req_empty",
                        openAIProcessingMS: 701,
                        contentType: "text/plain; charset=utf-8",
                        responseHeadersReceivedMS: 975,
                        transportFailureStage: .readingResponseBody,
                        networkErrorDomain: nil,
                        networkErrorCode: nil,
                        networkErrorCodeName: nil
                    )
                )
            ),
            .success(
                TranscriptionResult(
                    text: "second pass recovered",
                    backendID: "sequenced",
                    duration: nil,
                    responseMetadata: TranscriptionResponseMetadata(
                        requestMode: .standardCompletedRecording,
                        fellBackFromStreaming: false,
                        httpStatusCode: 200,
                        requestID: "req_empty_retry_success",
                        openAIProcessingMS: 130,
                        contentType: "text/plain",
                        responseHeadersReceivedMS: 410
                    )
                )
            ),
        ])
        let model = makeReadyModel(
            transcriptionBackend: backend,
            textInsertionService: textInsertionService,
            diagnosticsStore: diagnosticsStore,
            hotkeyManager: hotkeyManager
        )

        await model.bootstrap()
        hotkeyManager.press()
        hotkeyManager.release()
        await waitForWorkflowCompletion(model)

        #expect(model.workflowStatus == .inserted)
        #expect(backend.transcribeCallCount == 2)
        #expect(textInsertionService.insertedTexts == ["second pass recovered"])
        #expect(model.lastRecordingAttemptDiagnostics?.transcriptionRequestID == "req_empty_retry_success")
        #expect(model.diagnosticEvents.contains(where: { $0.summary.contains("Retrying transcription after an empty transcription response.") }))

        let persistedRecords = await diagnosticsStore.waitForRecordCount(1)
        #expect(persistedRecords.first?.terminalState == .inserted)
        #expect(persistedRecords.first?.transcript.characterCount == 21)
    }

    @Test("Invalid API key failure does not retry transcription")
    @MainActor
    func invalidAPIKeyFailureDoesNotRetryTranscription() async {
        let hotkeyManager = StubHotkeyManager()
        let backend = SequencedTranscriptionBackend(results: [
            .failure(.invalidAPIKey),
        ])
        let model = makeReadyModel(
            transcriptionBackend: backend,
            hotkeyManager: hotkeyManager
        )

        await model.bootstrap()
        hotkeyManager.press()
        hotkeyManager.release()
        await waitForWorkflowCompletion(model)

        #expect(model.workflowStatus == .failed)
        #expect(backend.transcribeCallCount == 1)
        #expect(model.apiKeyState == .invalid("The stored OpenAI API key was rejected."))
    }

    @Test("Offline transcription failure does not retry transcription")
    @MainActor
    func offlineTranscriptionFailureDoesNotRetry() async {
        let hotkeyManager = StubHotkeyManager()
        let backend = SequencedTranscriptionBackend(results: [
            .failure(
                .networkUnavailable(
                    TranscriptionFailureContext(
                        requestMode: .standardCompletedRecording,
                        fellBackFromStreaming: false,
                        httpStatusCode: nil,
                        requestID: nil,
                        openAIProcessingMS: nil,
                        contentType: nil,
                        responseHeadersReceivedMS: nil,
                        transportFailureStage: .awaitingResponseHeaders,
                        networkErrorDomain: NSURLErrorDomain,
                        networkErrorCode: URLError.Code.notConnectedToInternet.rawValue,
                        networkErrorCodeName: String(describing: URLError.Code.notConnectedToInternet)
                    )
                )
            ),
        ])
        let model = makeReadyModel(
            transcriptionBackend: backend,
            hotkeyManager: hotkeyManager
        )

        await model.bootstrap()
        hotkeyManager.press()
        hotkeyManager.release()
        await waitForWorkflowCompletion(model)

        #expect(model.workflowStatus == .failed)
        #expect(backend.transcribeCallCount == 1)
    }

    @Test("DNS transcription failure does not retry transcription")
    @MainActor
    func dnsTranscriptionFailureDoesNotRetry() async {
        let hotkeyManager = StubHotkeyManager()
        let backend = SequencedTranscriptionBackend(results: [
            .failure(
                .networkUnavailable(
                    TranscriptionFailureContext(
                        requestMode: .standardCompletedRecording,
                        fellBackFromStreaming: false,
                        httpStatusCode: nil,
                        requestID: nil,
                        openAIProcessingMS: nil,
                        contentType: nil,
                        responseHeadersReceivedMS: nil,
                        transportFailureStage: .awaitingResponseHeaders,
                        networkErrorDomain: NSURLErrorDomain,
                        networkErrorCode: URLError.Code.dnsLookupFailed.rawValue,
                        networkErrorCodeName: String(describing: URLError.Code.dnsLookupFailed)
                    )
                )
            ),
        ])
        let model = makeReadyModel(
            transcriptionBackend: backend,
            hotkeyManager: hotkeyManager
        )

        await model.bootstrap()
        hotkeyManager.press()
        hotkeyManager.release()
        await waitForWorkflowCompletion(model)

        #expect(model.workflowStatus == .failed)
        #expect(backend.transcribeCallCount == 1)
    }

    @Test("Hotkey presses are ignored while transcription is still in progress")
    @MainActor
    func hotkeyPressIgnoredWhileTranscribing() async {
        let hotkeyManager = StubHotkeyManager()
        let audioCaptureService = StubAudioCaptureService()
        let transcriptionBackend = DelayedTranscriptionBackend(transcript: "late")
        let model = makeReadyModel(
            audioCaptureService: audioCaptureService,
            transcriptionBackend: transcriptionBackend,
            hotkeyManager: hotkeyManager
        )

        await model.bootstrap()
        hotkeyManager.press()
        hotkeyManager.release()
        await transcriptionBackend.waitUntilStarted()

        #expect(model.workflowStatus == .transcribing)
        #expect(audioCaptureService.startCallCount == 1)

        hotkeyManager.press()

        #expect(model.workflowStatus == .transcribing)
        #expect(audioCaptureService.startCallCount == 1)
        #expect(model.lastDiagnosticEvent?.summary == "Ignored hotkey press because dictation processing is still in progress.")

        transcriptionBackend.finishTranscription()
        await waitForWorkflowCompletion(model)
    }
}

@Suite("Text Insertion Security")
struct TextInsertionSecurityTests {
    @Test("Secure-text-field subrole is blocked immediately")
    func explicitSecureSubroleIsClassifiedAsSecure() {
        let metadata = SecureTextFieldMetadata(
            role: "AXTextField",
            subrole: kAXSecureTextFieldSubrole as String,
            roleDescription: nil,
            title: nil,
            description: nil,
            identifier: nil,
            placeholderValue: nil,
            domIdentifier: nil
        )

        #expect(SecureTextFieldClassifier.isSecure(metadata))
    }

    @Test("Password-style web field metadata is treated as secure")
    func passwordLikeMetadataIsClassifiedAsSecure() {
        let metadata = SecureTextFieldMetadata(
            role: "AXTextField",
            subrole: nil,
            roleDescription: "text field",
            title: "Password",
            description: nil,
            identifier: "account-password",
            placeholderValue: "Enter password",
            domIdentifier: "login-password"
        )

        #expect(SecureTextFieldClassifier.isSecure(metadata))
    }

    @Test("Ordinary note field metadata stays editable")
    func ordinaryEditableMetadataIsNotClassifiedAsSecure() {
        let metadata = SecureTextFieldMetadata(
            role: "AXTextArea",
            subrole: nil,
            roleDescription: "text area",
            title: "Notes",
            description: "Project notes",
            identifier: "notes-body",
            placeholderValue: "Write something",
            domIdentifier: "notes-editor"
        )

        #expect(!SecureTextFieldClassifier.isSecure(metadata))
    }
}

struct TextInsertionRoutingTests {
    @Test("Planner routes native writable fields to AX value replacement")
    func plannerSelectsAXValueReplacementForNativeWritableFields() {
        let report = InsertionStrategyPlanner.plan(
            capabilities: TargetCapabilities(
                applicationName: "TextEdit",
                bundleIdentifier: "com.apple.TextEdit",
                processIdentifier: 100,
                role: "AXTextArea",
                subrole: nil,
                roleDescription: "text area",
                title: "Document",
                identifier: "body",
                placeholderValue: nil,
                placeholderLikelyActive: false,
                domIdentifier: nil,
                valueReadable: true,
                valueSettable: true,
                selectedTextRangeReadable: true,
                selectedTextReadable: true,
                editable: true,
                secure: false,
                pasteCompatible: true,
                directInsertCompatible: true
            ),
            allowPasteFallback: true
        )

        #expect(report.chosenStrategy == .axValueReplacement)
        #expect(report.predictedFailureClass == nil)
    }

    @Test("Planner routes partial AX custom editors to custom editor paste")
    func plannerSelectsCustomEditorPasteForPartialAXEditors() {
        let report = InsertionStrategyPlanner.plan(
            capabilities: TargetCapabilities(
                applicationName: "Codex",
                bundleIdentifier: "com.openai.codex",
                processIdentifier: 101,
                capabilityProfile: .opaquePasteCapable,
                role: "AXWebArea",
                subrole: nil,
                roleDescription: "web content",
                title: "Composer",
                identifier: "prompt-editor",
                placeholderValue: "Ask Codex",
                placeholderLikelyActive: false,
                domIdentifier: "prompt",
                valueReadable: false,
                valueSettable: false,
                selectedTextRangeReadable: false,
                selectedTextReadable: false,
                editable: true,
                secure: false,
                pasteCompatible: true,
                directInsertCompatible: false
            ),
            allowPasteFallback: true
        )

        #expect(report.chosenStrategy == .customEditorPaste)
        #expect(report.predictedFailureClass == nil)
    }

    @Test("Planner keeps known opaque writable editors on paste-oriented transport")
    func plannerKeepsKnownOpaqueWritableEditorsOffDirectAXReplacement() {
        let report = InsertionStrategyPlanner.plan(
            capabilities: TargetCapabilities(
                applicationName: "Codex",
                bundleIdentifier: "com.openai.codex",
                processIdentifier: 151,
                capabilityProfile: .opaquePasteCapable,
                role: "AXTextArea",
                subrole: nil,
                roleDescription: "text area",
                title: "Composer",
                identifier: "prompt-editor",
                placeholderValue: nil,
                placeholderLikelyActive: false,
                domIdentifier: "prompt",
                valueReadable: true,
                valueSettable: true,
                selectedTextRangeReadable: true,
                selectedTextReadable: false,
                editable: true,
                secure: false,
                pasteCompatible: true,
                directInsertCompatible: true
            ),
            allowPasteFallback: true
        )

        #expect(report.chosenStrategy == .customEditorPaste)
        #expect(report.rejectedStrategies.contains { rejection in
            rejection.strategy == .axValueReplacement
                && rejection.reason.contains("opaque editors")
        })
    }

    @Test("Planner keeps AX value replacement when placeholder-backed AX text can be sanitized")
    func plannerKeepsAXValueReplacementForPlaceholderBackedValues() {
        let report = InsertionStrategyPlanner.plan(
            capabilities: TargetCapabilities(
                applicationName: "Safari",
                bundleIdentifier: "com.apple.Safari",
                processIdentifier: 111,
                role: "AXTextField",
                subrole: nil,
                roleDescription: "text field",
                title: "Search",
                identifier: "search-input",
                placeholderValue: "Search",
                placeholderLikelyActive: true,
                domIdentifier: "search",
                valueReadable: true,
                valueSettable: true,
                selectedTextRangeReadable: true,
                selectedTextReadable: false,
                editable: true,
                secure: false,
                pasteCompatible: true,
                directInsertCompatible: true
            ),
            allowPasteFallback: true
        )

        #expect(report.chosenStrategy == .axValueReplacement)
        #expect(report.strategyReason.contains("placeholder"))
    }

    @Test("Planner blocks ambiguous inline placeholder values before insertion")
    func plannerBlocksAmbiguousInlinePlaceholderValues() {
        let report = InsertionStrategyPlanner.plan(
            capabilities: TargetCapabilities(
                applicationName: "Codex",
                bundleIdentifier: "com.openai.codex",
                processIdentifier: 112,
                capabilityProfile: .opaquePasteCapable,
                role: "AXTextArea",
                subrole: nil,
                roleDescription: "text area",
                title: "Composer",
                identifier: "prompt-editor",
                placeholderValue: "Ask for follow-up changes",
                placeholderLikelyActive: false,
                placeholderAmbiguousValueDetected: true,
                domIdentifier: "prompt",
                valueReadable: true,
                valueSettable: true,
                selectedTextRangeReadable: true,
                selectedTextReadable: false,
                editable: true,
                secure: false,
                pasteCompatible: true,
                directInsertCompatible: true
            ),
            allowPasteFallback: true
        )

        #expect(report.chosenStrategy == .unsupported)
        #expect(report.predictedFailureClass == .placeholderAmbiguous)
        #expect(report.strategyReason.contains("placeholder"))
    }

    @Test("Planner blocks secure targets before choosing an insertion path")
    func plannerBlocksSecureTargets() {
        let report = InsertionStrategyPlanner.plan(
            capabilities: TargetCapabilities(
                applicationName: "Safari",
                bundleIdentifier: "com.apple.Safari",
                processIdentifier: 102,
                role: "AXTextField",
                subrole: kAXSecureTextFieldSubrole as String,
                roleDescription: "secure text field",
                title: "Password",
                identifier: "password",
                placeholderValue: "Enter password",
                placeholderLikelyActive: false,
                domIdentifier: "password",
                valueReadable: false,
                valueSettable: false,
                selectedTextRangeReadable: false,
                selectedTextReadable: false,
                editable: true,
                secure: true,
                pasteCompatible: false,
                directInsertCompatible: false
            ),
            allowPasteFallback: true
        )

        #expect(report.chosenStrategy == .unsupported)
        #expect(report.predictedFailureClass == .secureTargetBlocked)
    }

    @Test("Planner routes known opaque app contexts to app clipboard paste")
    func plannerSelectsAppClipboardPasteForKnownOpaqueApps() {
        let report = InsertionStrategyPlanner.plan(
            capabilities: TargetCapabilities(
                applicationName: "Codex",
                bundleIdentifier: "com.openai.codex",
                processIdentifier: 103,
                capabilityProfile: .opaquePasteCapable,
                role: nil,
                subrole: nil,
                roleDescription: nil,
                title: nil,
                identifier: nil,
                placeholderValue: nil,
                placeholderLikelyActive: false,
                domIdentifier: nil,
                valueReadable: false,
                valueSettable: false,
                selectedTextRangeReadable: false,
                selectedTextReadable: false,
                editable: false,
                secure: false,
                pasteCompatible: true,
                directInsertCompatible: false,
                appLevelPasteOnly: true
            ),
            allowPasteFallback: true
        )

        #expect(report.chosenStrategy == .appClipboardPaste)
        #expect(report.predictedFailureClass == nil)
    }

    @Test("Planner keeps unknown opaque app contexts unsupported")
    func plannerRejectsUnknownOpaqueTargetsWithoutFocusedEditor() {
        let report = InsertionStrategyPlanner.plan(
            capabilities: TargetCapabilities(
                applicationName: "Unknown Editor",
                bundleIdentifier: "local.unknown.editor",
                processIdentifier: 104,
                role: nil,
                subrole: nil,
                roleDescription: nil,
                title: nil,
                identifier: nil,
                placeholderValue: nil,
                placeholderLikelyActive: false,
                domIdentifier: nil,
                valueReadable: false,
                valueSettable: false,
                selectedTextRangeReadable: false,
                selectedTextReadable: false,
                editable: false,
                secure: false,
                pasteCompatible: false,
                directInsertCompatible: false
            ),
            allowPasteFallback: true
        )

        #expect(report.chosenStrategy == .unsupported)
        #expect(report.predictedFailureClass == .targetNotEditable)
    }
}

@MainActor
private func testPreferences() -> AppPreferences {
    let suiteName = "HeadCanonTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return AppPreferences(defaults: defaults)
}

struct PlaceholderValueClassifierTests {
    @Test("Placeholder equality without selection context does not imply an active placeholder")
    func equalityAloneDoesNotActivatePlaceholder() {
        #expect(
            PlaceholderValueClassifier.placeholderLikelyActive(
                currentValue: "Search",
                placeholderValue: "Search",
                selectedRange: nil
            ) == false
        )
    }

    @Test("Placeholder is only considered active when the cursor is collapsed at the start")
    func placeholderRequiresCollapsedSelectionAtStart() {
        #expect(
            PlaceholderValueClassifier.placeholderLikelyActive(
                currentValue: "Search",
                placeholderValue: "Search",
                selectedRange: CFRange(location: 0, length: 0)
            ) == true
        )
        #expect(
            PlaceholderValueClassifier.placeholderLikelyActive(
                currentValue: "Search",
                placeholderValue: "Search",
                selectedRange: CFRange(location: 0, length: 3)
            ) == false
        )
        #expect(
            PlaceholderValueClassifier.placeholderLikelyActive(
                currentValue: "Search",
                placeholderValue: "Search",
                selectedRange: CFRange(location: 6, length: 0)
            ) == false
        )
    }

    @Test("Placeholder can still act as a weak editable hint when paired with structural metadata")
    func placeholderCanSuggestEditabilityWhenPaired() {
        #expect(
            PlaceholderValueClassifier.placeholderSuggestsEditableTarget(
                placeholderValue: "Ask Codex",
                supplementalMetadata: ["AXWebArea", nil, "web content", "Composer", "prompt-editor", "prompt"]
            ) == true
        )
        #expect(
            PlaceholderValueClassifier.placeholderSuggestsEditableTarget(
                placeholderValue: "Ask Codex",
                supplementalMetadata: [nil, nil, nil, nil, nil, nil]
            ) == false
        )
    }

    @Test("Inline placeholder suffix is marked ambiguous instead of removable")
    func inlinePlaceholderSuffixIsMarkedAmbiguous() {
        let userText = "What's the phone number? "
        let placeholderValue = "Ask for follow-up changes"
        let currentValue = userText + placeholderValue

        #expect(
            PlaceholderValueClassifier.placeholderRangeToRemove(
                currentValue: currentValue,
                placeholderValue: placeholderValue,
                selectedRange: CFRange(location: (userText as NSString).length, length: 0)
            ) == nil
        )
        #expect(
            PlaceholderValueClassifier.ambiguousPlaceholderValueDetected(
                currentValue: currentValue,
                placeholderValue: placeholderValue,
                selectedRange: CFRange(location: (currentValue as NSString).length, length: 0)
            )
        )
    }

    @Test("Inline placeholder suffix is not removed when the cursor is still inside real text")
    func inlinePlaceholderSuffixDoesNotClobberRealText() {
        let userText = "What's the phone number? "
        let placeholderValue = "Ask for follow-up changes"
        let currentValue = userText + placeholderValue

        #expect(
            PlaceholderValueClassifier.placeholderRangeToRemove(
                currentValue: currentValue,
                placeholderValue: placeholderValue,
                selectedRange: CFRange(location: 10, length: 0)
            ) == nil
        )
    }

    @Test("Sanitization only removes exact placeholder-backed values")
    func sanitizationRemovesExactPlaceholderValue() {
        let sanitized = PlaceholderValueClassifier.sanitizedValueAndSelection(
            currentValue: "Search",
            placeholderValue: "Search",
            selectedRange: CFRange(location: 0, length: 0)
        )

        #expect(sanitized.value.isEmpty)
        #expect(sanitized.selectedRange.location == 0)
        #expect(sanitized.selectedRange.length == 0)
    }

    @Test("Placeholder text is detected even when selected range is unavailable")
    func placeholderTextDetectionDoesNotDependOnSelection() {
        #expect(
            PlaceholderValueClassifier.valueContainsPlaceholderText(
                currentValue: "Go ahead with suggested next steps. Ask for follow-up changes",
                placeholderValue: "Ask for follow-up changes"
            )
        )
    }
}

@Suite("Placeholder Cleanup Planner")
struct PlaceholderCleanupPlannerTests {
    @Test("App clipboard paste uses focused cleanup when same-process focus is available")
    func appClipboardPasteUsesFocusedCleanupWhenFocusMatches() {
        #expect(
            PlaceholderCleanupPlanner.plan(
                strategy: .appClipboardPaste,
                plannedContextKind: .appOnly,
                currentFocusProcessMatches: true,
                currentFocusAvailable: true
            )
                == .useFocusedTarget
        )
    }

    @Test("App clipboard paste blocks blind paste when process does not match")
    func appClipboardPasteBlocksBlindPasteWhenFocusDoesNotMatch() {
        #expect(
            PlaceholderCleanupPlanner.plan(
                strategy: .appClipboardPaste,
                plannedContextKind: .appOnly,
                currentFocusProcessMatches: false,
                currentFocusAvailable: true
            )
                == .blockUnsafeBlindPaste
        )
    }

    @Test("AX-focused paste keeps focused cleanup enabled")
    func axFocusedPasteKeepsFocusedCleanupEnabled() {
        #expect(
            PlaceholderCleanupPlanner.plan(
                strategy: .customEditorPaste,
                plannedContextKind: .axFocusedElement,
                currentFocusProcessMatches: true,
                currentFocusAvailable: true
            )
                == .useFocusedTarget
        )
    }

    @Test("App clipboard paste skips focused cleanup when no focused AX target is available")
    func appClipboardPasteSkipsFocusedCleanupWhenFocusIsUnavailable() {
        #expect(
            PlaceholderCleanupPlanner.plan(
                strategy: .appClipboardPaste,
                plannedContextKind: .appOnly,
                currentFocusProcessMatches: false,
                currentFocusAvailable: false
            )
                == .skipCleanup
        )
    }
}

@Suite("Focus Target Equivalence")
struct FocusTargetEquivalenceTests {
    @Test("Matching DOM identifiers preserve target equivalence")
    func matchingDOMIdentifierPreservesEquivalence() {
        #expect(
            FocusTargetEquivalenceDecider.appearEquivalent(
                lhs: focusMetadata(domIdentifier: "prompt-editor"),
                rhs: focusMetadata(domIdentifier: "prompt-editor"),
                allowsWeakTextTargetFallback: false
            )
        )
    }

    @Test("Conflicting stable identifiers block weak target equivalence")
    func conflictingIdentifiersBlockWeakEquivalence() {
        #expect(
            !FocusTargetEquivalenceDecider.appearEquivalent(
                lhs: focusMetadata(identifier: "composer-a"),
                rhs: focusMetadata(identifier: "composer-b"),
                allowsWeakTextTargetFallback: true
            )
        )
    }

    @Test("Opaque text targets can survive AX identity churn without stable identifiers")
    func weakTextTargetFallbackSupportsOpaqueEditors() {
        #expect(
            FocusTargetEquivalenceDecider.appearEquivalent(
                lhs: focusMetadata(),
                rhs: focusMetadata(),
                allowsWeakTextTargetFallback: true
            )
        )
    }

    @Test("Weak text target fallback stays disabled for ordinary targets")
    func weakTextTargetFallbackCanBeDisabled() {
        #expect(
            !FocusTargetEquivalenceDecider.appearEquivalent(
                lhs: focusMetadata(),
                rhs: focusMetadata(),
                allowsWeakTextTargetFallback: false
            )
        )
    }

    @Test("Weak target fallback does not equate non-text controls")
    func weakFallbackRejectsNonTextControls() {
        #expect(
            !FocusTargetEquivalenceDecider.appearEquivalent(
                lhs: focusMetadata(role: kAXButtonRole as String, roleDescription: "button"),
                rhs: focusMetadata(role: kAXButtonRole as String, roleDescription: "button"),
                allowsWeakTextTargetFallback: true
            )
        )
    }

    private func focusMetadata(
        role: String? = kAXTextAreaRole as String,
        subrole: String? = nil,
        roleDescription: String? = "text area",
        title: String? = "Composer",
        identifier: String? = nil,
        placeholderValue: String? = nil,
        domIdentifier: String? = nil
    ) -> SecureTextFieldMetadata {
        SecureTextFieldMetadata(
            role: role,
            subrole: subrole,
            roleDescription: roleDescription,
            title: title,
            description: nil,
            identifier: identifier,
            placeholderValue: placeholderValue,
            domIdentifier: domIdentifier
        )
    }
}

@Suite("Placeholder Cleanup Decision")
struct PlaceholderCleanupDecisionTests {
    @Test("Cleanup removes exact placeholder-backed values when selection supports it")
    func removesExactPlaceholderBackedValues() {
        #expect(
            PlaceholderCleanupDecider.decide(
                currentValue: "Search",
                placeholderValue: "Search",
                selectedRange: CFRange(location: 0, length: 0)
            ) == .remove(NSRange(location: 0, length: 6))
        )
    }

    @Test("Cleanup blocks when placeholder text is present but no selected range is available")
    func blocksWhenSelectionIsUnavailable() {
        #expect(
            PlaceholderCleanupDecider.decide(
                currentValue: "Go ahead with suggested next steps. Ask for follow-up changes",
                placeholderValue: "Ask for follow-up changes",
                selectedRange: nil
            ) == .ambiguous
        )
    }

    @Test("Cleanup blocks when placeholder text is present but cannot be safely removed")
    func blocksWhenPlaceholderCannotBeSafelyRemoved() {
        #expect(
            PlaceholderCleanupDecider.decide(
                currentValue: "Go ahead with suggested next steps. Ask for follow-up changes",
                placeholderValue: "Ask for follow-up changes",
                selectedRange: CFRange(location: 10, length: 0)
            ) == .ambiguous
        )
    }

    @Test("Cleanup does nothing when placeholder text is absent")
    func noActionWhenPlaceholderTextIsAbsent() {
        #expect(
            PlaceholderCleanupDecider.decide(
                currentValue: "Go ahead with suggested next steps.",
                placeholderValue: "Ask for follow-up changes",
                selectedRange: nil
            ) == .notNeeded
        )
    }
}

@Suite("Paste Verification Decision")
struct PasteVerificationDecisionTests {
    @Test("Verification passes when the field changes and contains the dictated text")
    func verifiesChangedFieldContainingInsertedText() {
        let decision = PasteVerificationDecider.decide(
            beforeValue: "Draft ",
            beforeSelectedRange: CFRange(location: 6, length: 0),
            afterValue: "Draft hello world",
            insertedText: "hello world",
            mode: .exactReplacementPreferred
        )

        #expect(decision == .verified)
    }

    @Test("Verification fails when the field does not change")
    func rejectsUnchangedFieldAfterPaste() {
        let decision = PasteVerificationDecider.decide(
            beforeValue: "Draft",
            beforeSelectedRange: CFRange(location: 5, length: 0),
            afterValue: "Draft",
            insertedText: "hello world",
            mode: .exactReplacementPreferred
        )

        guard case .failed(let message) = decision else {
            Issue.record("Expected paste verification to fail for unchanged field state.")
            return
        }

        #expect(message.contains("did not change"))
    }

    @Test("Verification fails when the dictated text never appears")
    func rejectsFieldMissingInsertedText() {
        let decision = PasteVerificationDecider.decide(
            beforeValue: "Draft ",
            beforeSelectedRange: CFRange(location: 6, length: 0),
            afterValue: "Draft other text",
            insertedText: "hello world",
            mode: .exactReplacementPreferred
        )

        guard case .failed(let message) = decision else {
            Issue.record("Expected paste verification to fail when dictated text is absent.")
            return
        }

        #expect(message.contains("did not match"))
    }

    @Test("Verification stays non-blocking when readback is unavailable")
    func allowsUnavailableReadback() {
        let decision = PasteVerificationDecider.decide(
            beforeValue: nil,
            beforeSelectedRange: nil,
            afterValue: nil,
            insertedText: "hello world",
            mode: .exactReplacementPreferred
        )

        #expect(decision == .unavailable)
    }

    @Test("Verification fails when the resulting field differs from the expected replacement")
    func rejectsUnexpectedPostPasteFieldValue() {
        let decision = PasteVerificationDecider.decide(
            beforeValue: "Draft ",
            beforeSelectedRange: CFRange(location: 6, length: 0),
            afterValue: "Draft stale clipboard text",
            insertedText: "hello world",
            mode: .exactReplacementPreferred
        )

        guard case .failed(let message) = decision else {
            Issue.record("Expected paste verification to fail when the resulting field differs from the expected replacement.")
            return
        }

        #expect(message.contains("did not match"))
    }

    @Test("Opaque editors allow non-exact AX values when the transcript is present and the field changed")
    func opaqueEditorsUseTranscriptPresenceVerification() {
        let decision = PasteVerificationDecider.decide(
            beforeValue: "Draft ",
            beforeSelectedRange: CFRange(location: 6, length: 0),
            afterValue: "Draft stale prefix hello world",
            insertedText: "hello world",
            mode: .transcriptPresenceOnly
        )

        #expect(decision == .verified)
    }
}

@MainActor
private func makeReadyModel(
    preferences: AppPreferences = testPreferences(),
    audioCaptureService: any AudioCapturing = StubAudioCaptureService(),
    transcriptionBackend: any TranscriptionBackend = StubTranscriptionBackend(),
    textInsertionService: any TextInsertionServicing = StubTextInsertionService(),
    diagnosticsStore: any DiagnosticsStoring = NoOpDiagnosticsStore(),
    hotkeyManager: StubHotkeyManager = StubHotkeyManager(),
    clipboardWriter: any ClipboardWriting = RecordingClipboardWriter(),
    diskSpaceChecker: (any DiskSpaceChecking)? = nil,
    diskSpaceReserver: (any DiskSpaceReserving)? = StubDiskSpaceReserver(),
    diskSpacePolicy: DiskSpacePolicy = .default,
    hotkeyStateProvider: @escaping (HotkeyShortcut) -> Bool = { _ in true },
    transcriptionTimeout: Duration = .seconds(30),
    maximumRecordingDuration: Duration = .seconds(90)
) -> HeadCanonModel {
    if !preferences.hasCachedValidation(for: "test-key") {
        preferences.persistValidatedAPIKey("test-key", validatedAt: Date(timeIntervalSince1970: 1_715_000_000))
    }

    return HeadCanonModel(
        preferences: preferences,
        permissionsManager: StubPermissionsManager(
            snapshot: PermissionSnapshot(
                microphone: .granted,
                accessibility: .granted
            )
        ),
        audioCaptureService: audioCaptureService,
        transcriptionBackend: transcriptionBackend,
        textInsertionService: textInsertionService,
        apiKeyStore: StubAPIKeyStore(apiKey: "test-key"),
        diagnosticsStore: diagnosticsStore,
        hotkeyManager: hotkeyManager,
        clipboardWriter: clipboardWriter,
        diskSpaceChecker: diskSpaceChecker,
        diskSpaceReserver: diskSpaceReserver,
        diskSpacePolicy: diskSpacePolicy,
        hotkeyStateProvider: hotkeyStateProvider,
        transcriptionTimeout: transcriptionTimeout,
        maximumRecordingDuration: maximumRecordingDuration
    )
}

@MainActor
private func waitForWorkflowCompletion(_ model: HeadCanonModel) async {
    for _ in 0..<100 {
        if model.workflowStatus == .inserted || model.workflowStatus == .failed {
            return
        }
        await Task.yield()
    }
}

@MainActor
private func waitForInsertionAnalysis(_ model: HeadCanonModel) async {
    for _ in 0..<100 {
        if model.lastInsertionAttemptReport != nil || model.lastFailureStage == .insertion {
            return
        }
        await Task.yield()
        try? await Task.sleep(for: .milliseconds(10))
    }
}

private struct StubPermissionsManager: PermissionsManaging {
    let snapshot: PermissionSnapshot

    func refreshStatus() -> PermissionSnapshot {
        snapshot
    }

    func requestMicrophoneAccess() async -> PermissionState {
        snapshot.microphone
    }

    func promptForAccessibility() {}
}

@MainActor
private struct StubPermissionDebugService: PermissionDebugging {
    let snapshot: PermissionDebugSnapshot
    var selfTests: [PermissionSelfTestResult] = []

    func snapshot(for context: PermissionDebugContext) -> PermissionDebugSnapshot {
        snapshot
    }

    func runSelfTests(using snapshot: PermissionDebugSnapshot) -> [PermissionSelfTestResult] {
        selfTests
    }
}

@MainActor
private final class StubAudioCaptureService: AudioCapturing {
    var isRecording = false
    var unexpectedRecordingCompletionHandler: ((AudioCaptureUnexpectedCompletion) -> Void)?
    private(set) var startCallCount = 0
    var recordedDuration: TimeInterval? = 1.25
    var recordedFileSizeBytes = 2_048
    var startError: Error?
    var stopError: Error?

    func availableInputDevices() -> [MicrophoneDevice] {
        []
    }

    func startRecording(preferredDeviceID: String?) throws {
        if let startError {
            throw startError
        }
        startCallCount += 1
        isRecording = true
    }

    func stopRecording() async throws -> BoundedAudioInput {
        if let stopError {
            isRecording = false
            throw stopError
        }
        isRecording = false
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("headcanon-test-\(UUID().uuidString)")
            .appendingPathExtension("m4a")
        let byteCount = max(recordedFileSizeBytes, 1)
        try? Data(count: byteCount).write(to: fileURL)
        return BoundedAudioInput(
            fileURL: fileURL,
            mimeType: "audio/mp4",
            duration: recordedDuration
        )
    }

    func cancelRecording() {
        isRecording = false
    }

    func finishUnexpectedly(duration: TimeInterval? = 1.25) {
        isRecording = false
        let fileURL = makeRecordingFile()
        unexpectedRecordingCompletionHandler?(
            .finished(
                BoundedAudioInput(
                    fileURL: fileURL,
                    mimeType: "audio/mp4",
                    duration: duration
                )
            )
        )
    }

    func markStoppedWithoutCompletion() {
        isRecording = false
    }

    private func makeRecordingFile() -> URL {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("headcanon-test-\(UUID().uuidString)")
            .appendingPathExtension("m4a")
        let byteCount = max(recordedFileSizeBytes, 1)
        try? Data(count: byteCount).write(to: fileURL)
        return fileURL
    }
}

private struct StubDiskSpaceChecker: DiskSpaceChecking {
    var freeBytes: Int64

    func freeBytes(for url: URL) throws -> Int64 {
        freeBytes
    }
}

private final class MutableDiskSpaceChecker: DiskSpaceChecking, @unchecked Sendable {
    var freeBytes: Int64

    init(freeBytes: Int64) {
        self.freeBytes = freeBytes
    }

    func freeBytes(for url: URL) throws -> Int64 {
        freeBytes
    }
}

private final class StubDiskSpaceReserver: DiskSpaceReserving, @unchecked Sendable {
    var reservation: DiskSpaceReservation
    var checker: MutableDiskSpaceChecker?
    private(set) var ensureCallCount = 0
    private(set) var releaseCallCount = 0

    init(
        reservedBytes: Int64 = 0,
        targetBytes: Int64 = DiskSpacePolicy.gibibytes(2),
        minimumRemainingFreeBytes: Int64 = DiskSpacePolicy.gibibytes(10),
        checker: MutableDiskSpaceChecker? = nil
    ) {
        self.reservation = DiskSpaceReservation(
            reservedBytes: reservedBytes,
            targetBytes: targetBytes,
            minimumRemainingFreeBytes: minimumRemainingFreeBytes
        )
        self.checker = checker
    }

    func currentReservation(freeBytes: Int64) throws -> DiskSpaceReservation {
        reservation
    }

    func ensureReservation(freeBytes: Int64) throws -> DiskSpaceReservation {
        ensureCallCount += 1
        return reservation
    }

    func releaseReservation(freeBytes: Int64) throws -> DiskSpaceReservation {
        releaseCallCount += 1
        checker?.freeBytes += reservation.reservedBytes
        reservation = DiskSpaceReservation(
            reservedBytes: 0,
            targetBytes: reservation.targetBytes,
            minimumRemainingFreeBytes: reservation.minimumRemainingFreeBytes
        )
        return reservation
    }
}

private struct StubTranscriptionBackend: TranscriptionBackend {
    let id = "stub"
    var transcript = "stub"

    func validateConfiguration(apiKey: String) async throws {}

    func transcribe(_ input: BoundedAudioInput, apiKey: String) async throws -> TranscriptionResult {
        TranscriptionResult(text: transcript, backendID: id, duration: nil, responseMetadata: nil)
    }
}

private struct OfflineValidationTranscriptionBackend: TranscriptionBackend {
    let id = "offline-validation"

    func validateConfiguration(apiKey: String) async throws {
        throw TranscriptionBackendError.networkUnavailable()
    }

    func transcribe(_ input: BoundedAudioInput, apiKey: String) async throws -> TranscriptionResult {
        TranscriptionResult(text: "stub", backendID: id, duration: nil, responseMetadata: nil)
    }
}

private struct StubTextInsertionService: TextInsertionServicing {
    var captureError: Error?

    func captureFocusedTarget() throws -> any TextInsertionTargetHandle {
        if let captureError {
            throw captureError
        }
        return StubTextInsertionTargetHandle(id: "stub-target")
    }

    func planInsertion(
        target: (any TextInsertionTargetHandle)?,
        allowPasteFallback: Bool,
        observationLabel: String
    ) throws -> InsertionAttemptReport {
        InsertionStrategyPlanner.plan(
            capabilities: TargetCapabilities(
                applicationName: "Stub App",
                bundleIdentifier: "local.headcanon.tests.stub",
                processIdentifier: 1,
                contextKind: .axFocusedElement,
                capabilityProfile: .partialAXEditor,
                role: "AXTextArea",
                subrole: nil,
                roleDescription: "text area",
                title: "Stub Target",
                identifier: "stub-target",
                placeholderValue: nil,
                placeholderLikelyActive: false,
                domIdentifier: nil,
                valueReadable: true,
                valueSettable: true,
                selectedTextRangeReadable: true,
                selectedTextReadable: false,
                editable: true,
                secure: false,
                pasteCompatible: true,
                directInsertCompatible: true
            ),
            allowPasteFallback: allowPasteFallback,
            observationLabel: observationLabel
        )
    }

    func planExecutionInsertion(
        relativeTo target: (any TextInsertionTargetHandle)?,
        allowPasteFallback: Bool,
        observationLabel: String
    ) throws -> InsertionAttemptReport {
        try planInsertion(
            target: target,
            allowPasteFallback: allowPasteFallback,
            observationLabel: observationLabel
        )
    }

    func insert(
        _ text: String,
        target: (any TextInsertionTargetHandle)?,
        allowPasteFallback: Bool,
        observationLabel: String
    ) async throws -> InsertionAttemptReport {
        try planInsertion(
            target: target,
            allowPasteFallback: allowPasteFallback,
            observationLabel: observationLabel
        )
    }
}

@MainActor
private final class RecordingTextInsertionService: TextInsertionServicing {
    private(set) var insertedTexts: [String] = []
    private(set) var insertedTargets: [String] = []
    private(set) var lastAllowPasteFallback = true
    private(set) var lastInsertionPlan: InsertionAttemptReport?
    private(set) var executionPlanningCallCount = 0
    var focusedTarget: StubTextInsertionTargetHandle = StubTextInsertionTargetHandle(id: "stub-target")
    var supportsDirectInsert = false
    var insertVerificationOutcome: InsertionVerificationOutcome = .verified
    var omitExecutionVerificationOutcome = false
    var captureError: Error?
    var insertError: Error?
    private var captureCallCount = 0

    func captureFocusedTarget() throws -> any TextInsertionTargetHandle {
        if let captureError {
            throw captureError
        }
        captureCallCount += 1
        return focusedTarget
    }

    func planInsertion(
        target: (any TextInsertionTargetHandle)?,
        allowPasteFallback: Bool,
        observationLabel: String
    ) throws -> InsertionAttemptReport {
        let report = InsertionStrategyPlanner.plan(
            capabilities: TargetCapabilities(
                applicationName: "Stub App",
                bundleIdentifier: "local.headcanon.tests.stub",
                processIdentifier: 2,
                contextKind: .axFocusedElement,
                capabilityProfile: supportsDirectInsert ? .nativeAXStrong : .partialAXEditor,
                role: supportsDirectInsert ? "AXTextArea" : "AXWebArea",
                subrole: nil,
                roleDescription: supportsDirectInsert ? "text area" : "web content",
                title: "Stub Target",
                identifier: (target as? StubTextInsertionTargetHandle)?.id ?? focusedTarget.id,
                placeholderValue: nil,
                placeholderLikelyActive: false,
                domIdentifier: nil,
                valueReadable: supportsDirectInsert,
                valueSettable: supportsDirectInsert,
                selectedTextRangeReadable: supportsDirectInsert,
                selectedTextReadable: false,
                editable: true,
                secure: false,
                pasteCompatible: true,
                directInsertCompatible: supportsDirectInsert
            ),
            allowPasteFallback: allowPasteFallback,
            observationLabel: observationLabel
        )
        lastInsertionPlan = report
        return report
    }

    func planExecutionInsertion(
        relativeTo target: (any TextInsertionTargetHandle)?,
        allowPasteFallback: Bool,
        observationLabel: String
    ) throws -> InsertionAttemptReport {
        executionPlanningCallCount += 1
        return try planInsertion(
            target: target,
            allowPasteFallback: allowPasteFallback,
            observationLabel: observationLabel
        )
    }

    func insert(
        _ text: String,
        target: (any TextInsertionTargetHandle)?,
        allowPasteFallback: Bool,
        observationLabel: String
    ) async throws -> InsertionAttemptReport {
        lastAllowPasteFallback = allowPasteFallback

        let resolvedTarget: StubTextInsertionTargetHandle
        if let target = target as? StubTextInsertionTargetHandle {
            resolvedTarget = target
        } else {
            resolvedTarget = focusedTarget
        }

        guard !resolvedTarget.id.isEmpty else {
            throw TextInsertionError.unsupportedTarget
        }

        if !supportsDirectInsert && !allowPasteFallback {
            throw TextInsertionError.pasteFallbackDisabled
        }

        if let insertError {
            throw insertError
        }

        insertedTexts.append(text)
        insertedTargets.append(resolvedTarget.id)
        let report = try planInsertion(
            target: target,
            allowPasteFallback: allowPasteFallback,
            observationLabel: observationLabel
        )
        let appliedStrategy: InsertionStrategy = supportsDirectInsert ? .axValueReplacement : .customEditorPaste
        if omitExecutionVerificationOutcome {
            return InsertionAttemptReport(
                observedAt: report.observedAt,
                observationLabel: report.observationLabel,
                capabilities: report.capabilities,
                allowPasteFallback: report.allowPasteFallback,
                chosenStrategy: report.chosenStrategy,
                appliedStrategy: appliedStrategy,
                predictedFailureClass: report.predictedFailureClass,
                strategyReason: report.strategyReason,
                verificationOutcome: nil,
                placeholderHandlingOutcome: .noneNeeded,
                rejectedStrategies: report.rejectedStrategies
            )
        }

        return report.withExecution(
            appliedStrategy: appliedStrategy,
            placeholderHandlingOutcome: .noneNeeded,
            verificationOutcome: insertVerificationOutcome
        )
    }

    func waitUntilTargetCaptured() async {
        for _ in 0..<20 {
            if captureCallCount > 0 {
                return
            }
            await Task.yield()
        }
    }
}

private final class RecordingClipboardWriter: ClipboardWriting {
    private(set) var writes: [String] = []
    var writeSucceeds = true

    @discardableResult
    func write(_ text: String) -> Bool {
        writes.append(text)
        return writeSucceeds
    }
}

private final class StubTextInsertionTargetHandle: TextInsertionTargetHandle {
    let id: String

    init(id: String) {
        self.id = id
    }
}

@MainActor
private final class DelayedTranscriptionBackend: TranscriptionBackend {
    let id = "delayed"
    private let transcript: String
    private var continuation: CheckedContinuation<TranscriptionResult, Error>?
    private(set) var cancellationCount = 0

    init(transcript: String) {
        self.transcript = transcript
    }

    func validateConfiguration(apiKey: String) async throws {}

    func transcribe(_ input: BoundedAudioInput, apiKey: String) async throws -> TranscriptionResult {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
            }
        } onCancel: {
            Task { @MainActor in
                self.handleCancellation()
            }
        }
    }

    func waitUntilStarted() async {
        for _ in 0..<20 {
            if continuation != nil {
                return
            }
            await Task.yield()
        }
    }

    func waitUntilCancelled() async {
        for _ in 0..<20 {
            if cancellationCount > 0 {
                return
            }
            await Task.yield()
        }
    }

    func finishTranscription() {
        continuation?.resume(returning: TranscriptionResult(text: transcript, backendID: id, duration: nil, responseMetadata: nil))
        continuation = nil
    }

    private func handleCancellation() {
        cancellationCount += 1
        continuation?.resume(throwing: CancellationError())
        continuation = nil
    }
}

private struct FailingTranscriptionBackend: TranscriptionBackend {
    let id = "failing"
    let error: TranscriptionBackendError

    func validateConfiguration(apiKey: String) async throws {}

    func transcribe(_ input: BoundedAudioInput, apiKey: String) async throws -> TranscriptionResult {
        throw error
    }
}

@MainActor
private final class SequencedTranscriptionBackend: TranscriptionBackend {
    let id = "sequenced"
    private(set) var transcribeCallCount = 0
    private var results: [Result<TranscriptionResult, TranscriptionBackendError>]

    init(results: [Result<TranscriptionResult, TranscriptionBackendError>]) {
        self.results = results
    }

    func validateConfiguration(apiKey: String) async throws {}

    func transcribe(_ input: BoundedAudioInput, apiKey: String) async throws -> TranscriptionResult {
        transcribeCallCount += 1
        guard !results.isEmpty else {
            throw TranscriptionBackendError.networkUnavailable()
        }

        return switch results.removeFirst() {
        case .success(let result):
            result
        case .failure(let error):
            throw error
        }
    }
}

@MainActor
private final class CountingTranscriptionBackend: TranscriptionBackend {
    let id = "counting"
    private(set) var validateCallCount = 0

    func validateConfiguration(apiKey: String) async throws {
        validateCallCount += 1
    }

    func transcribe(_ input: BoundedAudioInput, apiKey: String) async throws -> TranscriptionResult {
        TranscriptionResult(text: "stub", backendID: id, duration: nil, responseMetadata: nil)
    }

    func waitUntilValidated() async {
        for _ in 0..<20 {
            if validateCallCount > 0 {
                return
            }
            await Task.yield()
        }
    }
}

private struct StubAPIKeyStore: APIKeyStoring {
    let apiKey: String?

    func loadAPIKey() throws -> String? {
        apiKey
    }

    func saveAPIKey(_ apiKey: String) throws {}

    func removeAPIKey() throws {}
}

actor NoOpDiagnosticsStore: DiagnosticsStoring {
    func persist(_ record: DictationAttemptRecord) async throws {}

    func persistLiveState(_ record: LiveDiagnosticsRecord) async throws {}

    func clear() async throws {}

    func diagnosticsDirectoryURL() async throws -> URL {
        FileManager.default.temporaryDirectory
    }
}

actor RecordingDiagnosticsStore: DiagnosticsStoring {
    private var records: [DictationAttemptRecord] = []
    private var liveRecords: [LiveDiagnosticsRecord] = []
    private var didClear = false
    private let directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("HeadCanonDiagnosticsStoreStub-\(UUID().uuidString)", isDirectory: true)

    func persist(_ record: DictationAttemptRecord) async throws {
        records.append(record)
    }

    func persistLiveState(_ record: LiveDiagnosticsRecord) async throws {
        liveRecords.append(record)
    }

    func clear() async throws {
        records.removeAll()
        liveRecords.removeAll()
        didClear = true
    }

    func diagnosticsDirectoryURL() async throws -> URL {
        directoryURL
    }

    func recordsSnapshot() -> [DictationAttemptRecord] {
        records
    }

    func liveRecordsSnapshot() -> [LiveDiagnosticsRecord] {
        liveRecords
    }

    func clearCalled() -> Bool {
        didClear
    }

    func waitForRecordCount(_ expectedCount: Int) async -> [DictationAttemptRecord] {
        for _ in 0..<200 {
            if records.count >= expectedCount {
                return records
            }
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(10))
        }

        return records
    }

    func waitForLiveState(where predicate: @escaping @Sendable (LiveDiagnosticsRecord) -> Bool) async -> LiveDiagnosticsRecord? {
        for _ in 0..<200 {
            if let record = liveRecords.last(where: predicate) {
                return record
            }
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(10))
        }

        return liveRecords.last(where: predicate)
    }
}

private func sampleAttemptRecord() -> DictationAttemptRecord {
    DictationAttemptRecord(
        schemaVersion: DictationAttemptRecord.schemaVersion,
        attemptID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        sessionID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
        completedAt: Date(timeIntervalSince1970: 1_715_000_000),
        terminalState: .inserted,
        truthState: .verifiedInsert,
        hotkeyDisplayString: "Control + Option + Space",
        bundle: DictationAttemptBundleRecord(
            path: "/Applications/HeadCanon.app",
            identifier: "local.headcanon.app",
            isInstalledBundle: true
        ),
        timing: DictationAttemptTimingRecord(
            hotkeyPressedAt: Date(timeIntervalSince1970: 1_715_000_000),
            recordingStartedAt: Date(timeIntervalSince1970: 1_715_000_001),
            hotkeyReleasedAt: Date(timeIntervalSince1970: 1_715_000_002),
            finalizingStateShownAt: Date(timeIntervalSince1970: 1_715_000_002),
            recordingFinalizedAt: Date(timeIntervalSince1970: 1_715_000_003),
            transcriptionRequestStartedAt: Date(timeIntervalSince1970: 1_715_000_003),
            transcriptionResponseCompletedAt: Date(timeIntervalSince1970: 1_715_000_004),
            insertionCompletedAt: Date(timeIntervalSince1970: 1_715_000_004),
            stopTrigger: HotkeyReleaseSource.carbonKeyUp.rawValue,
            pressToRecordingStartDurationMS: 60,
            releaseToFinalizingStateDurationMS: 0,
            releaseToFinalizedDurationMS: 40,
            finalizedToRequestStartDurationMS: 0,
            requestToResponseDurationMS: 980,
            responseToInsertionDurationMS: 120,
            releaseToInsertionDurationMS: 1_140
        ),
        audio: DictationAttemptAudioRecord(
            clipDurationMS: 1_760,
            recordedFileSizeBytes: 45_000
        ),
        transcript: DictationAttemptTranscriptRecord(
            characterCount: 12,
            wordCount: 2
        ),
        backend: DictationAttemptBackendRecord(
            identifier: "gpt-4o-mini-transcribe",
            requestMode: "Streamed Completed Recording",
            fellBackFromStreaming: false,
            httpStatusCode: 200,
            requestID: "req_test",
            openAIProcessingMS: 850,
            responseContentType: "text/event-stream",
            responseHeadersReceivedMS: 240,
            transportFailureStage: nil,
            networkErrorDomain: nil,
            networkErrorCode: nil,
            networkErrorCodeName: nil
        ),
        releaseTimeInsertion: DictationAttemptInsertionRecord(
            observationLabel: "Release-Time Context",
            applicationName: "TextEdit",
            bundleIdentifier: "com.apple.TextEdit",
            target: "Document",
            contextKind: InsertionContextKind.axFocusedElement.rawValue,
            capabilityProfile: ApplicationCapabilityProfile.nativeAXStrong.rawValue,
            chosenStrategy: InsertionStrategy.axValueReplacement.rawValue,
            appliedStrategy: nil,
            strategyReason: "Writable AX text field.",
            predictedFailureClass: nil,
            verificationOutcome: nil,
            placeholderPresent: false,
            placeholderLikelyActive: false,
            placeholderAmbiguousValueDetected: false,
            placeholderHandlingOutcome: nil,
            valueReadable: true,
            valueSettable: true,
            selectedTextRangeReadable: true,
            selectedTextReadable: true,
            editable: true,
            secure: false,
            pasteCompatible: true,
            directInsertCompatible: true
        ),
        insertion: DictationAttemptInsertionRecord(
            observationLabel: "Insert-Time Context",
            applicationName: "TextEdit",
            bundleIdentifier: "com.apple.TextEdit",
            target: "Document",
            contextKind: InsertionContextKind.axFocusedElement.rawValue,
            capabilityProfile: ApplicationCapabilityProfile.nativeAXStrong.rawValue,
            chosenStrategy: InsertionStrategy.axValueReplacement.rawValue,
            appliedStrategy: InsertionStrategy.axValueReplacement.rawValue,
            strategyReason: "Writable AX text field.",
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
}

private func legacyAttemptRecordData(
    from record: DictationAttemptRecord,
    schemaVersion: Int,
    truthState: String?
) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    encoder.dateEncodingStrategy = .iso8601

    let data = try encoder.encode(record)
    guard var jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        throw NSError(
            domain: "HeadCanonTests",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to build legacy diagnostics payload."]
        )
    }

    jsonObject["schemaVersion"] = schemaVersion
    if let truthState {
        jsonObject["truthState"] = truthState
    } else {
        jsonObject.removeValue(forKey: "truthState")
    }

    return try JSONSerialization.data(withJSONObject: jsonObject, options: [.sortedKeys])
}

private struct CapturedTranscriptionRequest: Equatable, Sendable {
    let acceptHeader: String?
    let bodyString: String
}

private struct StandardTranscriptionURLProtocolState: Sendable {
    var capturedRequests: [CapturedTranscriptionRequest] = []
}

private final class StandardTranscriptionURLProtocolStore: @unchecked Sendable {
    private let lock = NSLock()
    private var state = StandardTranscriptionURLProtocolState()

    func reset() {
        lock.withLock {
            state = StandardTranscriptionURLProtocolState()
        }
    }

    func capturedRequests() -> [CapturedTranscriptionRequest] {
        lock.withLock {
            state.capturedRequests
        }
    }

    func append(_ request: CapturedTranscriptionRequest) {
        lock.withLock {
            state.capturedRequests.append(request)
        }
    }
}

private final class StandardTranscriptionURLProtocol: URLProtocol, @unchecked Sendable {
    private static let store = StandardTranscriptionURLProtocolStore()

    static func reset() {
        store.reset()
    }

    static func capturedRequests() -> [CapturedTranscriptionRequest] {
        store.capturedRequests()
    }

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.absoluteString == "https://api.openai.com/v1/audio/transcriptions"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let bodyString = String(decoding: Self.bodyData(from: request), as: UTF8.self)
        let capturedRequest = CapturedTranscriptionRequest(
            acceptHeader: request.value(forHTTPHeaderField: "Accept"),
            bodyString: bodyString
        )
        Self.store.append(capturedRequest)

        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: [
                "content-type": "text/plain",
                "x-request-id": "req_standard_default",
                "openai-processing-ms": "123",
            ]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data("hello from standard mode".utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func bodyData(from request: URLRequest) -> Data {
        if let httpBody = request.httpBody {
            return httpBody
        }

        guard let httpBodyStream = request.httpBodyStream else {
            return Data()
        }

        httpBodyStream.open()
        defer {
            httpBodyStream.close()
        }

        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4_096)
        while httpBodyStream.hasBytesAvailable {
            let readCount = httpBodyStream.read(&buffer, maxLength: buffer.count)
            if readCount > 0 {
                data.append(buffer, count: readCount)
            } else {
                break
            }
        }
        return data
    }
}

private final class EmptyBodyTranscriptionURLProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.absoluteString == "https://api.openai.com/v1/audio/transcriptions"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: [
                "content-type": "text/plain",
                "content-length": "0",
                "x-request-id": "req_empty_body",
                "openai-processing-ms": "77",
            ]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private struct HangingTranscriptionURLProtocolState: Sendable {
    var startCount = 0
    var stopCount = 0
}

private final class HangingTranscriptionURLProtocolStore: @unchecked Sendable {
    private let lock = NSLock()
    private var state = HangingTranscriptionURLProtocolState()

    func reset() {
        lock.withLock {
            state = HangingTranscriptionURLProtocolState()
        }
    }

    func recordStart() {
        lock.withLock {
            state.startCount += 1
        }
    }

    func recordStop() {
        lock.withLock {
            state.stopCount += 1
        }
    }

    func startCount() -> Int {
        lock.withLock {
            state.startCount
        }
    }

    func stopCount() -> Int {
        lock.withLock {
            state.stopCount
        }
    }
}

private final class HangingTranscriptionURLProtocol: URLProtocol, @unchecked Sendable {
    private static let store = HangingTranscriptionURLProtocolStore()
    private var hasStopped = false

    static func reset() {
        store.reset()
    }

    static func stopCount() -> Int {
        store.stopCount()
    }

    static func waitUntilStarted() async {
        for _ in 0..<50 {
            if store.startCount() > 0 {
                return
            }
            await Task.yield()
        }
    }

    static func waitUntilStopped() async {
        for _ in 0..<50 {
            if store.stopCount() > 0 {
                return
            }
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.absoluteString == "https://api.openai.com/v1/audio/transcriptions"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.store.recordStart()
    }

    override func stopLoading() {
        guard !hasStopped else {
            return
        }

        hasStopped = true
        Self.store.recordStop()
        client?.urlProtocol(self, didFailWithError: URLError(.cancelled))
    }
}

private final class InMemoryAPIKeyStore: APIKeyStoring {
    var storedAPIKey: String?

    init(initialValue: String? = nil) {
        storedAPIKey = initialValue
    }

    func loadAPIKey() throws -> String? {
        storedAPIKey
    }

    func saveAPIKey(_ apiKey: String) throws {
        storedAPIKey = apiKey
    }

    func removeAPIKey() throws {
        storedAPIKey = nil
    }
}

private final class CountingAPIKeyStore: APIKeyStoring {
    private(set) var loadCallCount = 0
    private let apiKey: String?

    init(apiKey: String?) {
        self.apiKey = apiKey
    }

    func loadAPIKey() throws -> String? {
        loadCallCount += 1
        return apiKey
    }

    func saveAPIKey(_ apiKey: String) throws {}

    func removeAPIKey() throws {}
}

private struct FailingAPIKeyStore: APIKeyStoring {
    let loadError: Error

    func loadAPIKey() throws -> String? {
        throw loadError
    }

    func saveAPIKey(_ apiKey: String) throws {}

    func removeAPIKey() throws {}
}

private struct InvalidAPIKeyTranscriptionBackend: TranscriptionBackend {
    let id = "invalid-key"

    func validateConfiguration(apiKey: String) async throws {}

    func transcribe(_ input: BoundedAudioInput, apiKey: String) async throws -> TranscriptionResult {
        throw TranscriptionBackendError.invalidAPIKey
    }
}

@MainActor
private final class StubHotkeyManager: HotkeyManaging {
    private var onPress: (@MainActor () -> Void)?
    private var onRelease: (@MainActor (HotkeyReleaseContext) -> Void)?

    func register(
        shortcut: HotkeyShortcut,
        onPress: @escaping @MainActor () -> Void,
        onRelease: @escaping @MainActor (HotkeyReleaseContext) -> Void
    ) throws {
        self.onPress = onPress
        self.onRelease = onRelease
    }

    func unregister() {
        onPress = nil
        onRelease = nil
    }

    func press() {
        onPress?()
    }

    func release(source: HotkeyReleaseSource = .carbonKeyUp) {
        onRelease?(
            HotkeyReleaseContext(
                source: source,
                observedAt: Date()
            )
        )
    }
}
