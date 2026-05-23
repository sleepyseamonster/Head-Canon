import Foundation

protocol DiskSpaceChecking: Sendable {
    func freeBytes(for url: URL) throws -> Int64
}

struct VolumeDiskSpaceChecker: DiskSpaceChecking {
    func freeBytes(for url: URL) throws -> Int64 {
        let importantKeys: Set<URLResourceKey> = [.volumeAvailableCapacityForImportantUsageKey]
        if let importantCapacity = try url.resourceValues(forKeys: importantKeys).volumeAvailableCapacityForImportantUsage {
            return importantCapacity
        }

        let fallbackKeys: Set<URLResourceKey> = [.volumeAvailableCapacityKey]
        if let fallbackCapacity = try url.resourceValues(forKeys: fallbackKeys).volumeAvailableCapacity {
            return Int64(fallbackCapacity)
        }

        throw CocoaError(.fileReadUnknown)
    }
}

struct DiskSpacePolicy: Equatable, Sendable {
    let warningThresholdBytes: Int64
    let minimumRecordingBytes: Int64

    static let `default` = DiskSpacePolicy(
        warningThresholdBytes: gibibytes(10),
        minimumRecordingBytes: gibibytes(2)
    )

    static func gibibytes(_ value: Int64) -> Int64 {
        value * 1_024 * 1_024 * 1_024
    }

    var warningThresholdLabel: String {
        Self.thresholdLabel(for: warningThresholdBytes)
    }

    var minimumRecordingLabel: String {
        Self.thresholdLabel(for: minimumRecordingBytes)
    }

    private static func thresholdLabel(for bytes: Int64) -> String {
        let gibibytes = bytes / gibibytes(1)
        return "\(gibibytes) GB"
    }
}

enum DiskSpaceStatus: String, Codable, Equatable, Identifiable, Sendable {
    case healthy
    case warning
    case blocked

    var id: String { rawValue }

    var title: String {
        switch self {
        case .healthy:
            "Healthy"
        case .warning:
            "Low"
        case .blocked:
            "Blocked"
        }
    }
}

struct DiskSpaceReadiness: Equatable, Sendable {
    let freeBytes: Int64
    let reclaimableReserveBytes: Int64
    let policy: DiskSpacePolicy
    let reservation: DiskSpaceReservation

    var effectiveAvailableBytes: Int64 {
        freeBytes + reclaimableReserveBytes
    }

    var status: DiskSpaceStatus {
        if effectiveAvailableBytes < policy.minimumRecordingBytes {
            return .blocked
        }

        if effectiveAvailableBytes < policy.warningThresholdBytes {
            return .warning
        }

        return .healthy
    }

    var freeSpaceLabel: String {
        ByteCountFormatter.string(fromByteCount: freeBytes, countStyle: .file)
    }

    var effectiveAvailableSpaceLabel: String {
        ByteCountFormatter.string(fromByteCount: effectiveAvailableBytes, countStyle: .file)
    }

    var reclaimableReserveLabel: String {
        ByteCountFormatter.string(fromByteCount: reclaimableReserveBytes, countStyle: .file)
    }

    var warningMessage: String? {
        guard status == .warning else {
            return nil
        }

        if reclaimableReserveBytes > 0 {
            return "Disk space is low. Head Canon can reclaim \(reclaimableReserveLabel) of reserved cache space. Current free space: \(freeSpaceLabel). Effective Head Canon space: \(effectiveAvailableSpaceLabel)."
        }

        return "Disk space is low. Head Canon recommends at least \(policy.warningThresholdLabel) free. Current free space: \(freeSpaceLabel)."
    }

    var blockingMessage: String? {
        guard status == .blocked else {
            return nil
        }

        if reclaimableReserveBytes > 0 {
            return "Head Canon needs at least \(policy.minimumRecordingLabel) free to record safely. Even after reclaiming \(reclaimableReserveLabel) of reserved cache space, only \(effectiveAvailableSpaceLabel) is available."
        }

        return "Head Canon needs at least \(policy.minimumRecordingLabel) free to record safely. Free up disk space and try again."
    }

    var detail: String {
        blockingMessage ?? warningMessage ?? "Disk space is healthy for recording."
    }
}

struct DiskSpaceReadinessService: Sendable {
    let checker: any DiskSpaceChecking
    let reserver: any DiskSpaceReserving
    let policy: DiskSpacePolicy
    let monitoredURL: URL

    func currentReadiness() throws -> DiskSpaceReadiness {
        let freeBytes = try checker.freeBytes(for: monitoredURL)
        let reservation = try reserver.currentReservation(freeBytes: freeBytes)
        return DiskSpaceReadiness(
            freeBytes: freeBytes,
            reclaimableReserveBytes: reservation.reservedBytes,
            policy: policy,
            reservation: reservation
        )
    }

    func ensureReserve() throws -> DiskSpaceReadiness {
        let freeBytes = try checker.freeBytes(for: monitoredURL)
        let reservation = try reserver.ensureReservation(freeBytes: freeBytes)
        let refreshedFreeBytes = try checker.freeBytes(for: monitoredURL)
        return DiskSpaceReadiness(
            freeBytes: refreshedFreeBytes,
            reclaimableReserveBytes: reservation.reservedBytes,
            policy: policy,
            reservation: reservation
        )
    }

    func releaseReserve() throws -> DiskSpaceReadiness {
        let freeBytes = try checker.freeBytes(for: monitoredURL)
        _ = try reserver.releaseReservation(freeBytes: freeBytes)
        let refreshedFreeBytes = try checker.freeBytes(for: monitoredURL)
        let reservation = try reserver.currentReservation(freeBytes: refreshedFreeBytes)
        return DiskSpaceReadiness(
            freeBytes: refreshedFreeBytes,
            reclaimableReserveBytes: reservation.reservedBytes,
            policy: policy,
            reservation: reservation
        )
    }
}
