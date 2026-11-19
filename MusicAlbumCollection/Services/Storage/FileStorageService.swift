import Foundation

/// Errors related to file persistence.
enum FileStorageError: LocalizedError, Equatable {
    case directoryCreationFailed(String)
    case fileNotFound(URL)
    case encodingFailed(String)
    case decodingFailed(String)
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .directoryCreationFailed(let msg):
            return "Failed to create directory: \(msg)"
        case .fileNotFound(let url):
            return "File not found at: \(url.path)"
        case .encodingFailed(let msg):
            return "JSON encoding failed: \(msg)"
        case .decodingFailed(let msg):
            return "JSON decoding failed: \(msg)"
        case .writeFailed(let msg):
            return "Atomic file write failed: \(msg)"
        }
    }
}

/// Protocol abstracting atomic file read/write operations for codable entities.
protocol FileStorageProtocol: Sendable {
    func load<T: Decodable>(from url: URL) throws -> T
    func save<T: Encodable>(_ value: T, to url: URL) throws
    func fileExists(at url: URL) -> Bool
    func backupCorruptedFile(at url: URL) -> URL?
}

/// Production implementation of FileStorageProtocol utilizing JSONEncoder/JSONDecoder and atomic writes.
struct FileStorageService: FileStorageProtocol {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func fileExists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }

    /// Loads and decodes JSON data from a given file URL.
    func load<T: Decodable>(from url: URL) throws -> T {
        guard fileExists(at: url) else {
            throw FileStorageError.fileNotFound(url)
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw FileStorageError.fileNotFound(url)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            // Backup corrupted file to prevent permanent loss of unreadable raw data
            _ = backupCorruptedFile(at: url)
            throw FileStorageError.decodingFailed(error.localizedDescription)
        }
    }

    /// Encodes and writes data atomically to a file URL, creating intermediate directories if needed.
    func save<T: Encodable>(_ value: T, to url: URL) throws {
        let directoryURL = url.deletingLastPathComponent()

        if !fileManager.fileExists(atPath: directoryURL.path) {
            do {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            } catch {
                throw FileStorageError.directoryCreationFailed(error.localizedDescription)
            }
        }

        let data: Data
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            data = try encoder.encode(value)
        } catch {
            throw FileStorageError.encodingFailed(error.localizedDescription)
        }

        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw FileStorageError.writeFailed(error.localizedDescription)
        }
    }

    /// Renames a corrupted file with a timestamp suffix for diagnostic recovery.
    func backupCorruptedFile(at url: URL) -> URL? {
        let timestamp = Int(Date().timeIntervalSince1970)
        let backupURL = url.deletingPathExtension().appendingPathExtension("corrupted.\(timestamp).json")
        do {
            try fileManager.moveItem(at: url, to: backupURL)
            return backupURL
        } catch {
            return nil
        }
    }
}
