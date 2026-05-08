// MARK: - StatusBarView
import SwiftUI

struct StatusBarView: View {

    @ObservedObject var viewModel: RenameViewModel

    private var changedCount: Int {
        viewModel.items.filter { $0.willChange && !$0.hasErrors }.count
    }

    private var unchangedCount: Int {
        viewModel.items.filter { !$0.willChange && $0.previewStem != nil }.count
    }

    var body: some View {
        HStack(spacing: 12) {
            // File count
            StatusChip(
                icon: "doc.on.doc",
                label: String.localizedStringWithFormat(
                    L10n.string("status.files", comment: ""),
                    viewModel.items.count
                ),
                style: .neutral
            )

            // Renames pending
            if changedCount > 0 {
                StatusChip(
                    icon: "arrow.right.arrow.left",
                    label: String.localizedStringWithFormat(
                        L10n.string("status.willChange", comment: ""),
                        changedCount
                    ),
                    style: .accent
                )
            }

            // Unchanged (name stays same)
            if unchangedCount > 0 {
                StatusChip(
                    icon: "minus.circle",
                    label: String.localizedStringWithFormat(
                        L10n.string("status.unchanged", comment: ""),
                        unchangedCount
                    ),
                    style: .neutral
                )
            }

            // Errors
            if viewModel.totalErrors > 0 {
                StatusChip(
                    icon: "exclamationmark.triangle",
                    label: String.localizedStringWithFormat(
                        L10n.string("status.errors", comment: ""),
                        viewModel.totalErrors
                    ),
                    style: .warning
                )
            }

            Spacer()

            // Last undo info
            if let last = viewModel.undoService.lastOperation {
                Text(String(format: L10n.string("status.lastOp", comment: ""),
                            last.commandDescription))
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - StatusChip

private struct StatusChip: View {
    enum Style { case neutral, accent, warning }

    let icon: String
    let label: String
    let style: Style

    private var foreground: Color {
        switch style {
        case .neutral: return .secondary
        case .accent:  return .accentColor
        case .warning: return .orange
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(label)
                .font(.system(size: 11))
        }
        .foregroundStyle(foreground)
    }
}
