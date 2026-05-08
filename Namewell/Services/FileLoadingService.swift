// MARK: - FileLoadingService
import Foundation

/// Loads files from a directory URL (non-recursive) and produces RenameItems.
/// This is the only service besides FileRenameService that touches the filesystem.
struct FileLoadingService {

    enum LoadError: LocalizedError {
        case notADirectory
        case unreadable(underlying: Error)

        var errorDescription: String? {
            switch self {
            case .notADirectory:
                return L10n.string("load.notADirectory", comment: "")
            case .unreadable(let err):
                return String(format: L10n.string("load.unreadable", comment: ""), err.localizedDescription)
            }
        }
    }

    // MARK: Public

    /// Loads all non-directory files from `directoryURL` (one level deep).
    /// Returns items sorted by filename, case-insensitively.
    func loadItems(from directoryURL: URL) throws -> [RenameItem] {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: &isDir),
              isDir.boolValue else {
            throw LoadError.notADirectory
        }

        let contents: [URL]
        do {
            contents = try FileManager.default.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants, .skipsPackageDescendants]
            )
        } catch {
            throw LoadError.unreadable(underlying: error)
        }

        let files = contents.filter { url in
            guard let values = try? url.resourceValues(forKeys: [.isRegularFileKey]),
                  let isRegular = values.isRegularFile else { return false }
            return isRegular
        }

        return files
            .sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }
            .map { RenameItem(url: $0) }
    }
}
