// MARK: - RenameValidator
import Foundation

/// Validates a set of RenameItems before any file-system operation is performed.
/// Pure service — no I/O except for the filesystem existence check.
struct RenameValidator {
    private static let invalidFilenameScalars = CharacterSet(charactersIn: "/\0")

    // MARK: Public

    /// Validates all items and returns an array parallel to `items`,
    /// each entry containing zero or more errors for that item.
    func validate(_ items: [RenameItem]) -> [[RenameValidationError]] {
        let fileManager = FileManager.default
        var results: [[RenameValidationError]] = Array(repeating: [], count: items.count)

        // Build a frequency map of preview filenames to detect duplicates.
        var seenFilenames: [String: Int] = [:] // filename → first index

        for (index, item) in items.enumerated() {
            guard let stem = item.previewStem else { continue }
            let filename = stem + item.fileExtension

            // 1. Empty name
            if stem.trimmingCharacters(in: .whitespaces).isEmpty {
                results[index].append(.emptyName)
            }

            // 2. Invalid characters
            let invalid = invalidCharacters(in: stem)
            if !invalid.isEmpty {
                results[index].append(.invalidCharacters(characters: invalid))
            }

            // 3. Duplicate target names
            if let firstIndex = seenFilenames[filename] {
                // Mark both the first occurrence and this one.
                if !results[firstIndex].contains(.duplicateTarget(conflictingWith: filename)) {
                    results[firstIndex].append(.duplicateTarget(conflictingWith: filename))
                }
                results[index].append(.duplicateTarget(conflictingWith: filename))
            } else {
                seenFilenames[filename] = index
            }
        }

        // 4. Target already exists on disk (skip items that already have other errors)
        for (index, item) in items.enumerated() {
            guard results[index].isEmpty, let stem = item.previewStem else { continue }
            // Only check if the name actually changes
            if stem == item.originalStem { continue }
            let targetURL = item.originalURL.deletingLastPathComponent()
                .appendingPathComponent(stem + item.fileExtension)
            if fileManager.fileExists(atPath: targetURL.path),
               !targetURLPointsToOriginalFile(targetURL, originalURL: item.originalURL) {
                results[index].append(.targetAlreadyExists(url: targetURL))
            }
        }

        // 5. Permission check (heuristic: can we write to the parent directory?)
        var writableParents: [String: Bool] = [:]
        for (index, item) in items.enumerated() {
            guard results[index].isEmpty, item.previewStem != nil else { continue }
            let parentPath = item.originalURL.deletingLastPathComponent().path
            let isWritable = writableParents[parentPath] ?? fileManager.isWritableFile(atPath: parentPath)
            writableParents[parentPath] = isWritable

            if !isWritable {
                results[index].append(.permissionDenied)
            }
        }

        return results
    }

    // MARK: Private

    /// Returns a string containing any forbidden characters found in `name`.
    private func invalidCharacters(in name: String) -> String {
        var found = String.UnicodeScalarView()
        for scalar in name.unicodeScalars where Self.invalidFilenameScalars.contains(scalar) {
            found.append(scalar)
        }
        return String(found)
    }

    /// Allows case-only renames on case-insensitive file systems, where the
    /// destination path can appear to exist because it is the same file.
    private func targetURLPointsToOriginalFile(_ targetURL: URL, originalURL: URL) -> Bool {
        if targetURL.path == originalURL.path {
            return true
        }

        do {
            let targetAttributes = try FileManager.default.attributesOfItem(atPath: targetURL.path)
            let originalAttributes = try FileManager.default.attributesOfItem(atPath: originalURL.path)
            return targetAttributes[.systemNumber] as? NSNumber == originalAttributes[.systemNumber] as? NSNumber
                && targetAttributes[.systemFileNumber] as? NSNumber == originalAttributes[.systemFileNumber] as? NSNumber
        } catch {
            return false
        }
    }
}
