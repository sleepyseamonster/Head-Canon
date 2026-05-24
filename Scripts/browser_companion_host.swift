#!/usr/bin/env swift

import Dispatch
import Foundation

enum HostCommand: String, Decodable {
    case healthCheck
    case captureFocusedTarget
    case insertTranscript
    case targetSnapshotUpdate
}

struct HostCommandEnvelope: Decodable {
    let protocolVersion: Int
    let command: HostCommand
    let operationID: UUID
    let issuedAt: Date
    let expiresAt: Date?
    let target: HostTargetSnapshot?
    let transcript: String?
}

struct HostResultEnvelope: Codable {
    let protocolVersion: Int
    let result: String
    let operationID: UUID
    let observedAt: Date
    let target: HostTargetSnapshot?
    let message: String?
}

struct HostTargetSnapshot: Codable {
    let browser: String
    let pageOrigin: String?
    let pageTitle: String?
    let framePath: String?
    let frameIdentifier: String?
    let targetClass: String
    let editorFamily: String
    let targetFingerprint: String?
    let editable: Bool
    let secure: Bool
}

struct StoredTargetSnapshot: Codable {
    let browser: String
    let observedAt: Date
    let pageOrigin: String?
    let pageTitle: String?
    let framePath: String?
    let frameIdentifier: String?
    let targetClass: String
    let editorFamily: String
    let targetFingerprint: String?
    let editable: Bool
    let secure: Bool
}

enum PendingCommandKind: String, Codable {
    case healthCheck
    case captureFocusedTarget
    case insertTranscript
}

enum PendingResultKind: String, Codable {
    case targetSnapshot
    case inserted
    case unverifiedInsert
    case expired
    case unsupported
    case unavailable
    case failed
}

struct PendingTargetSnapshot: Codable {
    let browser: String
    let pageOrigin: String?
    let pageTitle: String?
    let framePath: String?
    let frameIdentifier: String?
    let targetClass: String
    let editorFamily: String
    let targetFingerprint: String?
    let editable: Bool
    let secure: Bool
}

struct PendingCommandEnvelope: Codable {
    let protocolVersion: Int
    let command: PendingCommandKind
    let operationID: UUID
    let issuedAt: Date
    let expiresAt: Date?
    let target: PendingTargetSnapshot?
    let transcript: String?
}

struct PendingResultEnvelope: Codable {
    let protocolVersion: Int
    let result: PendingResultKind
    let operationID: UUID
    let observedAt: Date
    let target: PendingTargetSnapshot?
    let message: String?
}

private enum HostPaths {
    static func baseDirectory() -> URL? {
        let homePath = ProcessInfo.processInfo.environment["HOME"] ?? NSHomeDirectory()
        return URL(fileURLWithPath: homePath, isDirectory: true)
            .appendingPathComponent("Library/Application Support", isDirectory: true)
            .appendingPathComponent("HeadCanon", isDirectory: true)
            .appendingPathComponent("browser-companion", isDirectory: true)
    }

    static func commandsDirectory() -> URL? {
        baseDirectory()?.appendingPathComponent("commands", isDirectory: true)
    }

    static func inflightDirectory() -> URL? {
        baseDirectory()?.appendingPathComponent("inflight", isDirectory: true)
    }

    static func resultsDirectory() -> URL? {
        baseDirectory()?.appendingPathComponent("results", isDirectory: true)
    }

    static func latestSnapshotFile() -> URL? {
        baseDirectory()?.appendingPathComponent("latest-target.json", isDirectory: false)
    }

    static func latestResultFile() -> URL? {
        baseDirectory()?.appendingPathComponent("latest-result.json", isDirectory: false)
    }
}

let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601

let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .iso8601

let ioQueue = DispatchQueue(label: "local.headcanon.browser-companion-host")
var readBuffer = Data()
let stdinHandle = FileHandle.standardInput
let timerSource = DispatchSource.makeTimerSource(queue: ioQueue)

func ensureDirectories() throws {
    guard let baseDirectory = HostPaths.baseDirectory() else {
        return
    }

    for directory in [
        baseDirectory,
        HostPaths.commandsDirectory(),
        HostPaths.inflightDirectory(),
        HostPaths.resultsDirectory(),
    ].compactMap({ $0 }) {
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
    }
}

func writeMessage<T: Encodable>(_ value: T) throws {
    let payload = try encoder.encode(value)
    var length = UInt32(payload.count).littleEndian
    let lengthData = Data(bytes: &length, count: MemoryLayout<UInt32>.size)
    try FileHandle.standardOutput.write(contentsOf: lengthData)
    try FileHandle.standardOutput.write(contentsOf: payload)
    try FileHandle.standardOutput.synchronize()
}

func persistSnapshot(_ snapshot: HostTargetSnapshot, observedAt: Date) throws {
    guard let fileURL = HostPaths.latestSnapshotFile() else {
        return
    }

    let stored = StoredTargetSnapshot(
        browser: snapshot.browser,
        observedAt: observedAt,
        pageOrigin: snapshot.pageOrigin,
        pageTitle: snapshot.pageTitle,
        framePath: snapshot.framePath,
        frameIdentifier: snapshot.frameIdentifier,
        targetClass: snapshot.targetClass,
        editorFamily: snapshot.editorFamily,
        targetFingerprint: snapshot.targetFingerprint,
        editable: snapshot.editable,
        secure: snapshot.secure
    )
    let payload = try encoder.encode(stored)
    try payload.write(to: fileURL, options: [.atomic])
    try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
}

func persistResult(_ result: HostResultEnvelope) throws {
    guard
        let resultsDirectory = HostPaths.resultsDirectory(),
        let latestResultFile = HostPaths.latestResultFile()
    else {
        return
    }

    let payload = try encoder.encode(result)
    let resultURL = resultsDirectory.appendingPathComponent("\(result.operationID.uuidString).json", isDirectory: false)
    try payload.write(to: resultURL, options: [.atomic])
    try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: resultURL.path)
    try payload.write(to: latestResultFile, options: [.atomic])
    try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: latestResultFile.path)

    if let target = result.target {
        try persistSnapshot(target, observedAt: result.observedAt)
    }

    if let inflightDirectory = HostPaths.inflightDirectory() {
        let inflightURL = inflightDirectory.appendingPathComponent("\(result.operationID.uuidString).json", isDirectory: false)
        try? FileManager.default.removeItem(at: inflightURL)
    }
}

func forwardPendingCommandsIfNeeded() {
    guard
        let commandsDirectory = HostPaths.commandsDirectory(),
        let inflightDirectory = HostPaths.inflightDirectory()
    else {
        return
    }

    let fileManager = FileManager.default
    let commandURLs = (try? fileManager.contentsOfDirectory(
        at: commandsDirectory,
        includingPropertiesForKeys: [.contentModificationDateKey],
        options: [.skipsHiddenFiles]
    )) ?? []

    let sortedCommands = commandURLs
        .filter { $0.pathExtension == "json" }
        .sorted { lhs, rhs in
            let lhsDate = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let rhsDate = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return lhsDate < rhsDate
        }

    for commandURL in sortedCommands {
        do {
            let payload = try Data(contentsOf: commandURL)
            let command = try decoder.decode(PendingCommandEnvelope.self, from: payload)

            if let expiresAt = command.expiresAt, expiresAt < Date() {
                let expiredResult = HostResultEnvelope(
                    protocolVersion: command.protocolVersion,
                    result: PendingResultKind.expired.rawValue,
                    operationID: command.operationID,
                    observedAt: Date(),
                    target: command.target.map(hostTargetSnapshot(from:)),
                    message: "The pending browser companion command expired before it could be dispatched."
                )
                try persistResult(expiredResult)
                try? fileManager.removeItem(at: commandURL)
                continue
            }

            let inflightURL = inflightDirectory.appendingPathComponent(commandURL.lastPathComponent, isDirectory: false)
            if fileManager.fileExists(atPath: inflightURL.path) {
                continue
            }

            try fileManager.moveItem(at: commandURL, to: inflightURL)
            try writeMessage(command)
        } catch {
            try? fileManager.removeItem(at: commandURL)
        }
    }
}

func hostTargetSnapshot(from snapshot: PendingTargetSnapshot) -> HostTargetSnapshot {
    HostTargetSnapshot(
        browser: snapshot.browser,
        pageOrigin: snapshot.pageOrigin,
        pageTitle: snapshot.pageTitle,
        framePath: snapshot.framePath,
        frameIdentifier: snapshot.frameIdentifier,
        targetClass: snapshot.targetClass,
        editorFamily: snapshot.editorFamily,
        targetFingerprint: snapshot.targetFingerprint,
        editable: snapshot.editable,
        secure: snapshot.secure
    )
}

func handleCommand(_ command: HostCommandEnvelope) {
    switch command.command {
    case .healthCheck:
        let result = HostResultEnvelope(
            protocolVersion: command.protocolVersion,
            result: "healthy",
            operationID: command.operationID,
            observedAt: Date(),
            target: nil,
            message: "Head Canon native host scaffold is reachable."
        )
        try? persistResult(result)
        try? writeMessage(result)
    case .targetSnapshotUpdate:
        let result: HostResultEnvelope
        do {
            if let target = command.target {
                try persistSnapshot(target, observedAt: command.issuedAt)
            }
            result = HostResultEnvelope(
                protocolVersion: command.protocolVersion,
                result: PendingResultKind.targetSnapshot.rawValue,
                operationID: command.operationID,
                observedAt: Date(),
                target: command.target,
                message: "Stored the latest browser target snapshot for Head Canon."
            )
        } catch {
            result = HostResultEnvelope(
                protocolVersion: command.protocolVersion,
                result: PendingResultKind.failed.rawValue,
                operationID: command.operationID,
                observedAt: Date(),
                target: command.target,
                message: "The browser companion host could not persist the latest target snapshot."
            )
        }

        try? persistResult(result)
        try? writeMessage(result)
    case .captureFocusedTarget, .insertTranscript:
        let result = HostResultEnvelope(
            protocolVersion: command.protocolVersion,
            result: PendingResultKind.unavailable.rawValue,
            operationID: command.operationID,
            observedAt: Date(),
            target: command.target,
            message: "The native host bridge is reachable, but no browser companion session is actively consuming app commands yet."
        )
        try? persistResult(result)
        try? writeMessage(result)
    }
}

func handleResult(_ result: PendingResultEnvelope) {
    let hostResult = HostResultEnvelope(
        protocolVersion: result.protocolVersion,
        result: result.result.rawValue,
        operationID: result.operationID,
        observedAt: result.observedAt,
        target: result.target.map(hostTargetSnapshot(from:)),
        message: result.message
    )
    try? persistResult(hostResult)
}

func extractNextMessage(from buffer: inout Data) -> Data? {
    guard buffer.count >= 4 else {
        return nil
    }

    let messageLength = buffer.prefix(4).withUnsafeBytes { rawBuffer in
        rawBuffer.load(as: UInt32.self)
    }
    let payloadLength = Int(UInt32(littleEndian: messageLength))
    guard buffer.count >= 4 + payloadLength else {
        return nil
    }

    let payload = buffer.subdata(in: 4..<(4 + payloadLength))
    buffer.removeSubrange(0..<(4 + payloadLength))
    return payload
}

func handleIncomingPayload(_ payload: Data) {
    if let result = try? decoder.decode(PendingResultEnvelope.self, from: payload) {
        handleResult(result)
        return
    }

    if let command = try? decoder.decode(HostCommandEnvelope.self, from: payload) {
        handleCommand(command)
        return
    }

    let fallback = HostResultEnvelope(
        protocolVersion: 1,
        result: PendingResultKind.failed.rawValue,
        operationID: UUID(),
        observedAt: Date(),
        target: nil,
        message: "The native host scaffold could not decode the incoming browser companion payload."
    )
    try? persistResult(fallback)
    try? writeMessage(fallback)
}

do {
    try ensureDirectories()
} catch {
    exit(1)
}

let readSource = DispatchSource.makeReadSource(fileDescriptor: stdinHandle.fileDescriptor, queue: ioQueue)
readSource.setEventHandler {
    let data = stdinHandle.availableData
    if data.isEmpty {
        timerSource.cancel()
        readSource.cancel()
        exit(0)
        return
    }

    readBuffer.append(data)
    while let payload = extractNextMessage(from: &readBuffer) {
        handleIncomingPayload(payload)
    }
}

timerSource.schedule(deadline: .now(), repeating: .milliseconds(200))
timerSource.setEventHandler {
    forwardPendingCommandsIfNeeded()
}

readSource.resume()
timerSource.resume()
dispatchMain()
