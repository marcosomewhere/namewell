// MARK: - RenameValidationError
import Foundation

/// A specific validation problem found for a single RenameItem.
enum RenameValidationError: Equatable, LocalizedError {
    case emptyName
    case duplicateTarget(conflictingWith: String)
    case targetAlreadyExists(url: URL)
    case invalidCharacters(characters: String)
    case permissionDenied
    case nameUnchanged

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return L10n.string("error.emptyName", comment: "")
        case .duplicateTarget(let other):
            return String(format: L10n.string("error.duplicateTarget", comment: ""), other)
        case .targetAlreadyExists(let url):
            return String(format: L10n.string("error.targetExists", comment: ""), url.lastPathComponent)
        case .invalidCharacters(let chars):
            return String(format: L10n.string("error.invalidChars", comment: ""), chars)
        case .permissionDenied:
            return L10n.string("error.permissionDenied", comment: "")
        case .nameUnchanged:
            return L10n.string("error.nameUnchanged", comment: "")
        }
    }
}
