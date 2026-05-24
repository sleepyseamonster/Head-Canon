#!/usr/bin/env swift

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

struct HostResultEnvelope: Encodable {
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

let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601

let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .iso8601

func readMessage() -> Data? {
    let stdinHandle = FileHandle.standardInput
    let lengthData: Data
    do {
        guard let candidate = try stdinHandle.read(upToCount: 4), candidate.count == 4 else {
            return nil
        }
        lengthData = candidate
    } catch {
        return nil
    }

    let messageLength = lengthData.withUnsafeBytes { rawBuffer in
        rawBuffer.load(as: UInt32.self)
    }
    let payloadLength = Int(UInt32(littleEndian: messageLength))
    guard payloadLength > 0 else {
        return nil
    }

    do {
        guard let payload = try stdinHandle.read(upToCount: payloadLength) else {
            return nil
        }
        return payload
    } catch {
        return nil
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

func snapshotFileURL() -> URL? {
    guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
        return nil
    }

    return appSupportURL
        .appendingPathComponent("HeadCanon", isDirectory: true)
        .appendingPathComponent("browser-companion", isDirectory: true)
        .appendingPathComponent("latest-target.json", isDirectory: false)
}

func persistSnapshot(_ snapshot: HostTargetSnapshot, observedAt: Date) throws {
    guard let fileURL = snapshotFileURL() else {
        return
    }

    try FileManager.default.createDirectory(
        at: fileURL.deletingLastPathComponent(),
        withIntermediateDirectories: true,
        attributes: [.posixPermissions: 0o700]
    )

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

func handle(_ command: HostCommandEnvelope) -> HostResultEnvelope {
    switch command.command {
    case .healthCheck:
        return HostResultEnvelope(
            protocolVersion: command.protocolVersion,
            result: "healthy",
            operationID: command.operationID,
            observedAt: Date(),
            target: nil,
            message: "Head Canon native host scaffold is reachable."
        )
    case .captureFocusedTarget, .insertTranscript:
        return HostResultEnvelope(
            protocolVersion: command.protocolVersion,
            result: "unavailable",
            operationID: command.operationID,
            observedAt: Date(),
            target: nil,
            message: "The native host scaffold is installed, but the Head Canon app has not started driving browser commands yet."
        )
    case .targetSnapshotUpdate:
        do {
            if let target = command.target {
                try persistSnapshot(target, observedAt: command.issuedAt)
            }
            return HostResultEnvelope(
                protocolVersion: command.protocolVersion,
                result: "targetSnapshot",
                operationID: command.operationID,
                observedAt: Date(),
                target: command.target,
                message: "Stored the latest browser target snapshot for Head Canon."
            )
        } catch {
            return HostResultEnvelope(
                protocolVersion: command.protocolVersion,
                result: "failed",
                operationID: command.operationID,
                observedAt: Date(),
                target: command.target,
                message: "The browser companion host could not persist the latest target snapshot."
            )
        }
    }
}

while let payload = readMessage() {
    do {
        let command = try decoder.decode(HostCommandEnvelope.self, from: payload)
        let response = handle(command)
        try writeMessage(response)
    } catch {
        let fallback = HostResultEnvelope(
            protocolVersion: 1,
            result: "failed",
            operationID: UUID(),
            observedAt: Date(),
            target: nil,
            message: "The native host scaffold could not decode the incoming browser companion command."
        )
        try? writeMessage(fallback)
    }
}
