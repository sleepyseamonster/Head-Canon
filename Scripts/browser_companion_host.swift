#!/usr/bin/env swift

import Foundation

enum HostCommand: String, Decodable {
    case healthCheck
    case captureFocusedTarget
    case insertTranscript
}

struct HostCommandEnvelope: Decodable {
    let protocolVersion: Int
    let command: HostCommand
    let operationID: UUID
    let issuedAt: Date
    let expiresAt: Date?
}

struct HostResultEnvelope: Encodable {
    let protocolVersion: Int
    let result: String
    let operationID: UUID
    let observedAt: Date
    let target: HostTargetSnapshot?
    let message: String?
}

struct HostTargetSnapshot: Encodable {
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
