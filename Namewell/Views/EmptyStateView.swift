// MARK: - EmptyStateView
import SwiftUI

struct EmptyStateView: View {

    @ObservedObject var viewModel: RenameViewModel
    @State private var isDropTargeted = false

    var body: some View {
        ZStack {
            // Drop zone background
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isDropTargeted ? Color.accentColor : Color(nsColor: .separatorColor),
                    style: StrokeStyle(lineWidth: isDropTargeted ? 2 : 1, dash: [8, 5])
                )
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isDropTargeted
                              ? Color.accentColor.opacity(0.06)
                              : Color.clear)
                )
                .animation(.easeInOut(duration: 0.15), value: isDropTargeted)
                .padding(32)

            VStack(spacing: 20) {
                // Icon
                ZStack {
                    Circle()
                        .fill(.quaternary)
                        .frame(width: 72, height: 72)
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 30, weight: .light))
                        .foregroundStyle(.secondary)
                }

                // Text
                VStack(spacing: 6) {
                    Text(L10n.string("empty.title", comment: ""))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(L10n.string("empty.subtitle", comment: ""))
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Open folder button
                Button {
                    viewModel.openFolder()
                } label: {
                    Label(L10n.string("action.openFolder", comment: ""), systemImage: "folder")
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut("o", modifiers: .command)

                Text(L10n.string("empty.shortcut", comment: ""))
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            isDropTargeted = false
            return FileDropHandler.loadFirstDirectory(from: providers) { url in
                viewModel.loadFolder(url: url)
            }
        }
    }
}
