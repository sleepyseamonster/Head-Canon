import Darwin
import Foundation

protocol DiskSpaceReserving: Sendable {
    func currentReservation(freeBytes: Int64) throws -> DiskSpaceReservation
    func ensureReservation(freeBytes: Int64) throws -> DiskSpaceReservation
    func releaseReservation(freeBytes: Int64) throws -> DiskSpaceReservation
}

struct DiskSpaceReservePolicy: Equatable, Sendable {
    let targetReservationBytes: Int64
    let minimumRemainingFreeBytes: Int64

    static let `default` = DiskSpaceReservePolicy(
        targetReservationBytes: DiskSpacePolicy.gibibytes(2),
        minimumRemainingFreeBytes: DiskSpacePolicy.gibibytes(10)
    )
}

enum DiskSpaceReservationStatus: String, Codable, Equatable, Identifiable, Sendable {
    case none
    case partial
    case reserved

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none:
            "None"
        case .partial:
            "Partial"
        case .reserved:
            "Reserved"
        }
    }
}

struct DiskSpaceReservation: Equatable, Sendable {
    let reservedBytes: Int64
    let targetBytes: Int64
    let minimumRemainingFreeBytes: Int64

    var status: DiskSpaceReservationStatus {
        if reservedBytes <= 0 {
            return .none
        }

        if reservedBytes >= targetBytes {
            return .reserved
        }

        return .partial
    }

    var reservedSpaceLabel: String {
        ByteCountFormatter.string(fromByteCount: reservedBytes, countStyle: .file)
    }

    var targetSpaceLabel: String {
        ByteCountFormatter.string(fromByteCount: targetBytes, countStyle: .file)
    }

    var detail: String {
        switch status {
        case .none:
            "No Head Canon disk reserve is currently allocated."
        case .partial:
            "Head Canon has partially reserved \(reservedSpaceLabel) of \(targetSpaceLabel) in cache space."
        case .reserved:
            "Head Canon has reserved \(reservedSpaceLabel) in cache space for low-disk recovery."
        }
    }
}

final class DiskSpaceReserveManager: @unchecked Sendable, DiskSpaceReserving {
    static let reserveFileURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
        .appendingPathComponent("HeadCanon", isDirectory: true)
        .appendingPathComponent("DiskReserve", isDirectory: true)
        .appendingPathComponent("headcanon-disk-reserve.bin", isDirectory: false)

    private let fileManager: FileManager
    private let policy: DiskSpaceReservePolicy
    private let reserveFileURL: URL
    private let lock = NSLock()

    init(
        fileManager: FileManager = .default,
        policy: DiskSpaceReservePolicy = .default,
        reserveFileURL: URL? = DiskSpaceReserveManager.reserveFileURL
    ) {
        self.fileManager = fileManager
        self.policy = policy
        self.reserveFileURL = reserveFileURL ?? FileManager.default.temporaryDirectory
            .appendingPathComponent("HeadCanon", isDirectory: true)
            .appendingPathComponent("DiskReserve", isDirectory: true)
            .appendingPathComponent("headcanon-disk-reserve.bin", isDirectory: false)
    }

    func currentReservation(freeBytes: Int64) throws -> DiskSpaceReservation {
        try lockLocked {
            makeReservation(reservedBytes: try reservedBytesOnDisk())
        }
    }

    func ensureReservation(freeBytes: Int64) throws -> DiskSpaceReservation {
        try lockLocked {
            let currentReservedBytes = try reservedBytesOnDisk()
            let additionalReservableBytes = max(0, freeBytes - policy.minimumRemainingFreeBytes)
            let remainingTargetBytes = max(0, policy.targetReservationBytes - currentReservedBytes)
            let desiredAdditionalBytes = min(remainingTargetBytes, additionalReservableBytes)
            let desiredReservedBytes = currentReservedBytes + desiredAdditionalBytes

            guard desiredReservedBytes > currentReservedBytes else {
                return makeReservation(reservedBytes: currentReservedBytes)
            }

            try ensureReserveDirectory()
            try allocateReserveFile(to: desiredReservedBytes)
            return makeReservation(reservedBytes: desiredReservedBytes)
        }
    }

    func releaseReservation(freeBytes: Int64) throws -> DiskSpaceReservation {
        try lockLocked {
            if fileManager.fileExists(atPath: reserveFileURL.path) {
                try fileManager.removeItem(at: reserveFileURL)
            }

            return makeReservation(reservedBytes: 0)
        }
    }

    private func makeReservation(reservedBytes: Int64) -> DiskSpaceReservation {
        DiskSpaceReservation(
            reservedBytes: reservedBytes,
            targetBytes: policy.targetReservationBytes,
            minimumRemainingFreeBytes: policy.minimumRemainingFreeBytes
        )
    }

    private func ensureReserveDirectory() throws {
        let directoryURL = reserveFileURL.deletingLastPathComponent()
        try fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
    }

    private func reservedBytesOnDisk() throws -> Int64 {
        guard fileManager.fileExists(atPath: reserveFileURL.path) else {
            return 0
        }

        let attributes = try fileManager.attributesOfItem(atPath: reserveFileURL.path)
        return (attributes[.size] as? NSNumber)?.int64Value ?? 0
    }

    private func allocateReserveFile(to reservedBytes: Int64) throws {
        if !fileManager.fileExists(atPath: reserveFileURL.path) {
            fileManager.createFile(atPath: reserveFileURL.path, contents: nil)
            try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: reserveFileURL.path)
        }

        let fileDescriptor = open(reserveFileURL.path, O_RDWR)
        guard fileDescriptor >= 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }

        defer {
            close(fileDescriptor)
        }

        let currentSize = try reservedBytesOnDisk()
        guard reservedBytes > currentSize else {
            return
        }

        if try preallocateReserveFile(fileDescriptor: fileDescriptor, reservedBytes: reservedBytes) == false {
            try allocateReserveFileByWriting(fileDescriptor: fileDescriptor, from: currentSize, to: reservedBytes)
        }

        if ftruncate(fileDescriptor, off_t(reservedBytes)) != 0 {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
    }

    private func preallocateReserveFile(fileDescriptor: Int32, reservedBytes: Int64) throws -> Bool {
        var allocation = fstore_t(
            fst_flags: UInt32(F_ALLOCATECONTIG),
            fst_posmode: Int32(F_PEOFPOSMODE),
            fst_offset: 0,
            fst_length: off_t(reservedBytes),
            fst_bytesalloc: 0
        )

        if fcntl(fileDescriptor, F_PREALLOCATE, &allocation) == -1 {
            if errno != ENOSPC {
                allocation.fst_flags = UInt32(F_ALLOCATEALL)
                if fcntl(fileDescriptor, F_PREALLOCATE, &allocation) == 0 {
                    return true
                }
            }

            if errno == ENOTSUP || errno == EINVAL || errno == ENOSYS {
                return false
            }

            if errno == ENOSPC {
                throw POSIXError(.ENOSPC)
            }

            return false
        }

        return true
    }

    private func allocateReserveFileByWriting(fileDescriptor: Int32, from currentSize: Int64, to reservedBytes: Int64) throws {
        if lseek(fileDescriptor, off_t(currentSize), SEEK_SET) < 0 {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }

        var remainingBytes = reservedBytes - currentSize
        let zeroChunk = [UInt8](repeating: 0, count: 1_048_576)

        while remainingBytes > 0 {
            let writeCount = Int(min(Int64(zeroChunk.count), remainingBytes))
            let wroteBytes = zeroChunk.withUnsafeBytes { chunkBytes in
                write(fileDescriptor, chunkBytes.baseAddress, writeCount)
            }
            guard wroteBytes >= 0 else {
                throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
            }
            remainingBytes -= Int64(wroteBytes)
        }
    }

    private func lockLocked<T>(_ body: () throws -> T) throws -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }
}
