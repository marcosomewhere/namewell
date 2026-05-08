// MARK: - FolderSelectionService
import AppKit

struct FolderSelectionService {

    @MainActor
    func selectFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = L10n.string("panel.chooseFolder", comment: "")
        panel.message = L10n.string("panel.message", comment: "")

        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }
}
