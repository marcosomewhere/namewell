// MARK: - RenameViewModel
import Foundation
import Combine

@MainActor
final class RenameViewModel: ObservableObject {

    // MARK: Published State

    @Published var items: [RenameItem] = []
    @Published var commandText: String = ""
    @Published var currentFolderURL: URL?
    @Published var parseError: String?
    @Published var alertMessage: String?
    @Published var showAlert: Bool = false
    @Published var isRenaming: Bool = false

    // MARK: Derived (computed from items)

    var hasItems: Bool { !items.isEmpty }
    var hasValidPreview: Bool { items.contains { $0.willChange && !$0.hasErrors } }
    var totalErrors: Int { items.reduce(0) { $0 + $1.validationErrors.count } }
    var canRename: Bool {
        hasValidPreview && totalErrors == 0 && !isRenaming
    }

    var undoService: UndoManagerService { _undoService }

    // MARK: Private Services

    private let parser = CommandParser()
    private let engine = RenameEngine()
    private let validator = RenameValidator()
    private let loader = FileLoadingService()
    private let folderSelection = FolderSelectionService()
    private let renamer = FileRenameService()
    private let _undoService = UndoManagerService()

    // MARK: Debounce

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Debounce command input → re-compute preview after 150 ms idle.
        $commandText
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.recomputePreview() }
            .store(in: &cancellables)
    }

    // MARK: - Public Actions

    /// Opens an NSOpenPanel for folder selection and loads files.
    func openFolder() {
        guard let url = folderSelection.selectFolder() else { return }
        loadFolder(url: url)
    }

    /// Loads (or reloads) files from a given directory URL.
    func loadFolder(url: URL, preservingUndo: Bool = false) {
        do {
            let loaded = try loader.loadItems(from: url)
            currentFolderURL = url
            items = loaded
            if !preservingUndo {
                _undoService.clear()
            }
            recomputePreview()
        } catch {
            presentAlert(error.localizedDescription)
        }
    }

    /// Performs the actual rename on disk for all valid, changed items.
    func performRename() {
        guard canRename else { return }
        isRenaming = true

        let description = commandText

        Task {
            defer { isRenaming = false }
            do {
                let operation = try renamer.performRename(items: items, commandDescription: description)
                _undoService.push(operation)
                // Reload the folder to reflect the new filenames on disk.
                if let url = currentFolderURL {
                    loadFolder(url: url, preservingUndo: true)
                }
            } catch {
                presentAlert(error.localizedDescription)
            }
        }
    }

    /// Undoes the last rename operation.
    func undoLastRename() {
        do {
            try _undoService.undoLast()
            commandText = ""
            if let url = currentFolderURL {
                loadFolder(url: url, preservingUndo: true)
            }
        } catch {
            presentAlert(error.localizedDescription)
        }
    }

    /// Repeats the last undone rename operation.
    func redoLastRename() {
        do {
            try _undoService.redoLast()
            commandText = ""
            if let url = currentFolderURL {
                loadFolder(url: url, preservingUndo: true)
            }
        } catch {
            presentAlert(error.localizedDescription)
        }
    }

    // MARK: - Private

    private func recomputePreview() {
        guard !items.isEmpty else {
            parseError = nil
            return
        }

        let trimmed = commandText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            clearPreview()
            parseError = nil
            return
        }

        switch parser.parse(trimmed) {
        case .empty:
            clearPreview()
            parseError = nil

        case .failure(let message):
            clearPreview()
            parseError = message

        case .success(let rules):
            parseError = nil
            let newStems = engine.apply(rules: rules, to: items)
            for i in items.indices {
                items[i].previewStem = newStems[i]
                items[i].validationErrors = []
            }
            runValidation()
        }
    }

    private func clearPreview() {
        for i in items.indices {
            items[i].previewStem = nil
            items[i].validationErrors = []
        }
    }

    private func runValidation() {
        let errors = validator.validate(items)
        for i in items.indices {
            items[i].validationErrors = errors[i]
        }
    }

    private func presentAlert(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}
