// MARK: - RenameOperation
import Foundation

/// A completed rename operation. Stores all the information needed to undo it.
struct RenameOperation {
    /// Mapping of original URL → URL it was renamed to.
    let renames: [(from: URL, to: URL)]
    /// Human-readable description of the command that produced this operation.
    let commandDescription: String
    /// When the operation was performed.
    let performedAt: Date

    init(renames: [(from: URL, to: URL)], commandDescription: String) {
        self.renames = renames
        self.commandDescription = commandDescription
        self.performedAt = Date()
    }
}
