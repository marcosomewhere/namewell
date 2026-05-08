// MARK: - UndoManagerService
import Foundation

/// Manages the stack of completed rename operations that can be undone.
/// Decoupled from SwiftUI's UndoManager to allow fine-grained control.
final class UndoManagerService: ObservableObject {

    @Published private(set) var lastOperation: RenameOperation?
    @Published private(set) var canUndo: Bool = false
    @Published private(set) var canRedo: Bool = false

    private var undoStack: [RenameOperation] = []
    private var redoStack: [RenameOperation] = []
    private let renameService = FileRenameService()

    // MARK: Public

    func push(_ operation: RenameOperation) {
        undoStack.append(operation)
        redoStack.removeAll()
        lastOperation = operation
        syncState()
    }

    /// Undoes the most recent operation.
    /// Returns the undone operation on success, throws on failure.
    @discardableResult
    func undoLast() throws -> RenameOperation {
        guard let operation = undoStack.last else {
            throw UndoError.nothingToUndo
        }
        try renameService.undo(operation: operation)
        undoStack.removeLast()
        redoStack.append(operation)
        syncState()
        return operation
    }

    /// Repeats the most recently undone operation.
    @discardableResult
    func redoLast() throws -> RenameOperation {
        guard let operation = redoStack.last else {
            throw UndoError.nothingToRedo
        }
        try renameService.redo(operation: operation)
        redoStack.removeLast()
        undoStack.append(operation)
        syncState()
        return operation
    }

    func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
        syncState()
    }

    private func syncState() {
        lastOperation = undoStack.last ?? redoStack.last
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }

    // MARK: Error

    enum UndoError: LocalizedError {
        case nothingToUndo
        case nothingToRedo

        var errorDescription: String? {
            switch self {
            case .nothingToUndo:
                return L10n.string("undo.nothingToUndo", comment: "")
            case .nothingToRedo:
                return L10n.string("undo.nothingToRedo", comment: "")
            }
        }
    }
}
