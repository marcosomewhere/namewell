// MARK: - RenameItem
import Foundation

/// Represents a single file that is a candidate for renaming.
/// This is a pure value type — no I/O, no side effects.
struct RenameItem: Identifiable, Equatable {
    let id: UUID
    /// The original URL of the file on disk.
    let originalURL: URL
    /// The stem of the original filename (without extension).
    let originalStem: String
    /// The file extension, including the leading dot (e.g. ".jpg"), or empty string if none.
    let fileExtension: String
    /// The preview name stem after applying the current rules. Nil if no command is active.
    var previewStem: String?
    /// Validation errors discovered for this item in the last validation pass.
    var validationErrors: [RenameValidationError] = []

    // MARK: Convenience

    /// The original full filename (stem + extension).
    var originalFilename: String { originalStem + fileExtension }

    /// The preview full filename. Falls back to originalFilename if no preview is set.
    var previewFilename: String {
        guard let stem = previewStem else { return originalFilename }
        return stem + fileExtension
    }

    /// True when the preview differs from the original.
    var willChange: Bool { previewStem != nil && previewStem != originalStem }

    /// True when the item has at least one validation error.
    var hasErrors: Bool { !validationErrors.isEmpty }

    // MARK: Init

    init(url: URL) {
        self.id = UUID()
        self.originalURL = url
        let filename = url.lastPathComponent
        if filename.hasPrefix(".") {
            // Hidden files: treat the whole name as the stem, no extension.
            self.originalStem = filename
            self.fileExtension = ""
        } else {
            let ext = url.pathExtension
            self.fileExtension = ext.isEmpty ? "" : "." + ext
            self.originalStem = ext.isEmpty ? filename : String(filename.dropLast(ext.count + 1))
        }
    }
}
