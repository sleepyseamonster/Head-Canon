import AVFoundation
import Foundation

struct MicrophoneDevice: Identifiable, Equatable {
    let id: String
    let name: String
}

private struct CaptureSessionTeardownToken: @unchecked Sendable {
    let session: AVCaptureSession
}

enum AudioCaptureUnexpectedCompletion {
    case finished(BoundedAudioInput)
    case failed(String)
}

@MainActor
protocol AudioCapturing: AnyObject {
    func availableInputDevices() -> [MicrophoneDevice]
    func startRecording(preferredDeviceID: String?) throws
    func stopRecording() async throws -> BoundedAudioInput
    func cancelRecording()
    var isRecording: Bool { get }
    var unexpectedRecordingCompletionHandler: ((AudioCaptureUnexpectedCompletion) -> Void)? { get set }
}

enum AudioCaptureError: LocalizedError {
    case alreadyRecording
    case inputDeviceUnavailable
    case captureDeviceOpenFailed
    case sessionConfigurationFailed
    case recorderStartFailed
    case noActiveRecording
    case outputMissing
    case unsupportedOutputFormat
    case finalizationFailed(String)

    var errorDescription: String? {
        switch self {
        case .alreadyRecording:
            "Head Canon is already recording."
        case .inputDeviceUnavailable:
            "Head Canon could not find the selected microphone."
        case .captureDeviceOpenFailed:
            "Head Canon could not open the selected microphone for recording."
        case .sessionConfigurationFailed:
            "Head Canon could not configure audio capture for the selected microphone."
        case .recorderStartFailed:
            "Head Canon could not start recording audio."
        case .noActiveRecording:
            "Head Canon tried to stop recording, but no recording was active."
        case .outputMissing:
            "Head Canon could not find the recorded audio file."
        case .unsupportedOutputFormat:
            "Head Canon could not find a supported audio output format."
        case .finalizationFailed(let message):
            message
        }
    }
}

@MainActor
final class AudioCaptureService: NSObject, AudioCapturing {
    static let recordingsDirectoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("HeadCanon", isDirectory: true)
        .appendingPathComponent("Recordings", isDirectory: true)

    private let sessionQueue = DispatchQueue(label: "local.headcanon.audio-capture.session")
    private var captureSession: AVCaptureSession?
    private var captureInput: AVCaptureDeviceInput?
    private var fileOutput: AVCaptureAudioFileOutput?
    private var activeOutputURL: URL?
    private var activeMimeType = "audio/mp4"
    private var startedAt: Date?
    private var pendingStopContinuation: CheckedContinuation<BoundedAudioInput, Error>?
    private var pendingDuration: TimeInterval?
    private var shouldDiscardRecording = false
    var unexpectedRecordingCompletionHandler: ((AudioCaptureUnexpectedCompletion) -> Void)?

    override init() {
        super.init()
        cleanupStaleRecordings()
    }

    var isRecording: Bool {
        captureSession != nil
    }

    func availableInputDevices() -> [MicrophoneDevice] {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external],
            mediaType: .audio,
            position: .unspecified
        )
        .devices
        .map { device in
            MicrophoneDevice(id: device.uniqueID, name: device.localizedName)
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func startRecording(preferredDeviceID: String?) throws {
        guard !isRecording else {
            throw AudioCaptureError.alreadyRecording
        }

        let device = try selectedInputDevice(preferredDeviceID: preferredDeviceID)
        let captureInput: AVCaptureDeviceInput

        do {
            captureInput = try AVCaptureDeviceInput(device: device)
        } catch {
            throw AudioCaptureError.captureDeviceOpenFailed
        }

        let captureSession = AVCaptureSession()
        let fileOutput = AVCaptureAudioFileOutput()

        captureSession.beginConfiguration()
        var configurationCommitted = false
        defer {
            if !configurationCommitted {
                captureSession.commitConfiguration()
            }
        }

        guard captureSession.canAddInput(captureInput) else {
            throw AudioCaptureError.sessionConfigurationFailed
        }

        guard captureSession.canAddOutput(fileOutput) else {
            throw AudioCaptureError.sessionConfigurationFailed
        }

        captureSession.addInput(captureInput)
        captureSession.addOutput(fileOutput)
        fileOutput.audioSettings = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 24_000,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 64_000,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        let outputFormat = try outputFormatConfiguration(for: fileOutput)
        let recordingsDirectoryURL = try prepareRecordingsDirectory()
        let outputURL = recordingsDirectoryURL
            .appendingPathComponent("head-canon-\(UUID().uuidString)")
            .appendingPathExtension(outputFormat.fileExtension)

        self.captureSession = captureSession
        self.captureInput = captureInput
        self.fileOutput = fileOutput
        self.activeOutputURL = outputURL
        self.activeMimeType = outputFormat.mimeType
        self.startedAt = Date()
        self.pendingStopContinuation = nil
        self.pendingDuration = nil
        self.shouldDiscardRecording = false

        // AVCaptureSession must finish configuration before startRunning().
        captureSession.commitConfiguration()
        configurationCommitted = true

        sessionQueue.sync {
            captureSession.startRunning()
        }

        guard captureSession.isRunning else {
            cleanup(removeOutputFile: true)
            throw AudioCaptureError.recorderStartFailed
        }

        fileOutput.startRecording(
            to: outputURL,
            outputFileType: outputFormat.fileType,
            recordingDelegate: self
        )
    }

    func stopRecording() async throws -> BoundedAudioInput {
        guard let fileOutput else {
            throw AudioCaptureError.noActiveRecording
        }

        let duration = startedAt.map { Date().timeIntervalSince($0) }

        return try await withCheckedThrowingContinuation { continuation in
            pendingStopContinuation = continuation
            pendingDuration = duration
            shouldDiscardRecording = false
            fileOutput.stopRecording()
        }
    }

    func cancelRecording() {
        guard let fileOutput else {
            cleanup(removeOutputFile: true)
            return
        }

        shouldDiscardRecording = true

        if fileOutput.isRecording {
            fileOutput.stopRecording()
        } else {
            cleanup(removeOutputFile: true)
        }
    }

    private func selectedInputDevice(preferredDeviceID: String?) throws -> AVCaptureDevice {
        let devices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external],
            mediaType: .audio,
            position: .unspecified
        ).devices

        if let preferredDeviceID, let selectedDevice = devices.first(where: { $0.uniqueID == preferredDeviceID }) {
            return selectedDevice
        }

        if preferredDeviceID != nil {
            throw AudioCaptureError.inputDeviceUnavailable
        }

        if let defaultDevice = AVCaptureDevice.default(for: .audio) {
            return defaultDevice
        }

        guard let firstDevice = devices.first else {
            throw AudioCaptureError.inputDeviceUnavailable
        }

        return firstDevice
    }

    private func outputFormatConfiguration(for output: AVCaptureAudioFileOutput) throws -> (fileType: AVFileType, fileExtension: String, mimeType: String) {
        let supportedTypes = Set(type(of: output).availableOutputFileTypes())

        if supportedTypes.contains(.m4a) {
            return (.m4a, "m4a", "audio/mp4")
        }

        throw AudioCaptureError.unsupportedOutputFormat
    }

    private func prepareRecordingsDirectory() throws -> URL {
        do {
            try FileManager.default.createDirectory(
                at: Self.recordingsDirectoryURL,
                withIntermediateDirectories: true
            )
            return Self.recordingsDirectoryURL
        } catch {
            throw AudioCaptureError.sessionConfigurationFailed
        }
    }

    private func cleanupStaleRecordings() {
        guard
            let recordingURLs = try? FileManager.default.contentsOfDirectory(
                at: Self.recordingsDirectoryURL,
                includingPropertiesForKeys: nil
            )
        else {
            return
        }

        for recordingURL in recordingURLs where recordingURL.pathExtension == "m4a" {
            try? FileManager.default.removeItem(at: recordingURL)
        }
    }

    private func cleanup(removeOutputFile: Bool) {
        if let fileOutput, fileOutput.isRecording {
            fileOutput.stopRecording()
        }

        let captureSession = captureSession
        let activeOutputURL = activeOutputURL

        if removeOutputFile, let activeOutputURL {
            try? FileManager.default.removeItem(at: activeOutputURL)
        }

        self.captureSession = nil
        self.captureInput = nil
        self.fileOutput = nil
        self.activeOutputURL = nil
        activeMimeType = "audio/mp4"
        startedAt = nil
        pendingStopContinuation = nil
        pendingDuration = nil
        shouldDiscardRecording = false

        if let captureSession {
            let teardownToken = CaptureSessionTeardownToken(session: captureSession)

            // Stop the session off the hot path. A later startRecording() call uses the same
            // serial queue, so any pending teardown finishes before a new session starts.
            sessionQueue.async {
                if teardownToken.session.isRunning {
                    teardownToken.session.stopRunning()
                }
            }
        }
    }
}

extension AudioCaptureService: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        Task { @MainActor [weak self] in
            self?.handleRecordingFinished(outputFileURL: outputFileURL, error: error as NSError?)
        }
    }

    @MainActor
    private func handleRecordingFinished(outputFileURL: URL, error: NSError?) {
        let continuation = pendingStopContinuation
        let duration = pendingDuration ?? startedAt.map { Date().timeIntervalSince($0) }
        let mimeType = activeMimeType
        let shouldDiscardRecording = shouldDiscardRecording

        let recordingFinishedSuccessfully =
            (error?.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? NSNumber)?.boolValue ?? (error == nil)

        cleanup(removeOutputFile: shouldDiscardRecording || !recordingFinishedSuccessfully)

        guard let continuation else {
            notifyUnexpectedCompletion(
                outputFileURL: outputFileURL,
                mimeType: mimeType,
                duration: duration,
                shouldDiscardRecording: shouldDiscardRecording,
                recordingFinishedSuccessfully: recordingFinishedSuccessfully,
                error: error
            )
            return
        }

        if shouldDiscardRecording {
            continuation.resume(throwing: AudioCaptureError.noActiveRecording)
            return
        }

        guard recordingFinishedSuccessfully else {
            continuation.resume(
                throwing: AudioCaptureError.finalizationFailed(
                    error?.localizedDescription ?? "Head Canon could not finish writing the recorded audio file."
                )
            )
            return
        }

        guard FileManager.default.fileExists(atPath: outputFileURL.path()) else {
            continuation.resume(throwing: AudioCaptureError.outputMissing)
            return
        }

        continuation.resume(
            returning: BoundedAudioInput(
                fileURL: outputFileURL,
                mimeType: mimeType,
                duration: duration
            )
        )
    }

    private func notifyUnexpectedCompletion(
        outputFileURL: URL,
        mimeType: String,
        duration: TimeInterval?,
        shouldDiscardRecording: Bool,
        recordingFinishedSuccessfully: Bool,
        error: NSError?
    ) {
        guard !shouldDiscardRecording else {
            return
        }

        guard recordingFinishedSuccessfully else {
            unexpectedRecordingCompletionHandler?(
                .failed(
                    error?.localizedDescription ?? "Head Canon's audio capture stopped before recording finalization completed."
                )
            )
            return
        }

        guard FileManager.default.fileExists(atPath: outputFileURL.path()) else {
            unexpectedRecordingCompletionHandler?(.failed(AudioCaptureError.outputMissing.localizedDescription))
            return
        }

        unexpectedRecordingCompletionHandler?(
            .finished(
                BoundedAudioInput(
                    fileURL: outputFileURL,
                    mimeType: mimeType,
                    duration: duration
                )
            )
        )
    }
}
