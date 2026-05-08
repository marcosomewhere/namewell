// MARK: - FileRenameService
import Foundation

/// The ONLY service that performs actual file-system rename operations.
/// Supports atomic rollback: if any rename fails, all previous renames in
/// the same batch are reversed before the error is thrown.
struct FileRenameService {

    enum RenameError: LocalizedError {
        case partialFailure(completed: [(URL, URL)], failedAt: URL, underlying: Error)
        case rollbackFailed(original: Error, rollbackErrors: [Error])

        var errorDescription: String? {
            switch self {
            case .partialFailure(_, let url, let err):
                return String(format: L10n.string("rename.partialFailure", comment: ""),
                              url.lastPathComponent, err.localizedDescription)
            case .rollbackFailed(let orig, _):
                return String(format: L10n.string("rename.rollbackFailed", comment: ""),
                              orig.localizedDescription)
            }
        }
    }

    // MARK: Public

    /// Renames all items whose `previewStem` differs from their `originalStem`.
    /// Returns a `RenameOperation` snapshot suitable for undo.
    /// Throws `RenameError` if any rename fails (with rollback attempted).
    @discardableResult
    func performRename(items: [RenameItem], commandDescription: String) throws -> RenameOperation {
        let pending: [(from: URL, to: URL)] = items.compactMap { item in
            guard let stem = item.previewStem, stem != item.originalStem else { return nil }
            let to = item.originalURL.deletingLastPathComponent()
                .appendingPathComponent(stem + item.fileExtension)
            return (from: item.originalURL, to: to)
        }

        var completed: [(from: URL, to: URL)] = []

        for pair in pending {
            do {
                try moveItemHandlingCaseOnlyRename(at: pair.from, to: pair.to)
                completed.append(pair)
            } catch {
                // Attempt rollback of all completed renames
                var rollbackErrors: [Error] = []
                for done in completed.reversed() {
                    do {
                        try moveItemHandlingCaseOnlyRename(at: done.to, to: done.from)
                    } catch let rollbackErr {
                        rollbackErrors.append(rollbackErr)
                    }
                }
                if rollbackErrors.isEmpty {
                    throw RenameError.partialFailure(completed: completed, failedAt: pair.from, underlying: error)
                } else {
                    throw RenameError.rollbackFailed(original: error, rollbackErrors: rollbackErrors)
                }
            }
        }

        return RenameOperation(renames: completed.map { ($0.from, $0.to) }, commandDescription: commandDescription)
    }

    /// Undoes a previously completed `RenameOperation`.
    func undo(operation: RenameOperation) throws {
        for rename in operation.renames.reversed() {
            try moveItemHandlingCaseOnlyRename(at: rename.to, to: rename.from)
        }
    }

    /// Re-applies a previously undone `RenameOperation`.
    func redo(operation: RenameOperation) throws {
        for rename in operation.renames {
            try moveItemHandlingCaseOnlyRename(at: rename.from, to: rename.to)
        }
    }

    // MARK: Private

    private func moveItemHandlingCaseOnlyRename(at sourceURL: URL, to destinationURL: URL) throws {
        guard isCaseOnlyRename(from: sourceURL, to: destinationURL) else {
            try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
            return
        }

        let temporaryURL = try makeTemporarySiblingURL(for: sourceURL)
        try FileManager.default.moveItem(at: sourceURL, to: temporaryURL)

        do {
            try FileManager.default.moveItem(at: temporaryURL, to: destinationURL)
        } catch {
            try? FileManager.default.moveItem(at: temporaryURL, to: sourceURL)
            throw error
        }
    }

    private func isCaseOnlyRename(from sourceURL: URL, to destinationURL: URL) -> Bool {
        sourceURL.path != destinationURL.path
            && sourceURL.path.lowercased() == destinationURL.path.lowercased()
    }

    private func makeTemporarySiblingURL(for sourceURL: URL) throws -> URL {
        let directoryURL = sourceURL.deletingLastPathComponent()
        let baseName = ".namewell-rename-\(UUID().uuidString)"

        for attempt in 0..<10 {
            let candidate = directoryURL.appendingPathComponent("\(baseName)-\(attempt)")
            if !FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
        }

        throw CocoaError(.fileWriteFileExists)
    }
}
