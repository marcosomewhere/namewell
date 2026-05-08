// MARK: - PreviewListView
import SwiftUI

struct PreviewListView: View {

    @ObservedObject var viewModel: RenameViewModel

    var body: some View {
        List(viewModel.items) { item in
            PreviewRowView(item: item)
                .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
                .listRowSeparator(.visible)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - PreviewRowView

struct PreviewRowView: View {

    let item: RenameItem

    var body: some View {
        HStack(spacing: 0) {
            // File icon
            fileIcon
                .frame(width: 32)

            // Names column
            VStack(alignment: .leading, spacing: 2) {
                // Original filename
                Text(item.originalFilename)
                    .font(.system(size: 13))
                    .foregroundStyle(item.willChange ? .secondary : .primary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                // Preview filename (only shown when it differs)
                if item.willChange || item.hasErrors {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(item.hasErrors ? .orange : .accentColor)

                        Text(item.previewFilename)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(item.hasErrors ? .orange : .accentColor)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                // Validation errors
                ForEach(item.validationErrors, id: \.errorDescription) { error in
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                        Text(error.errorDescription ?? "")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.orange)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 7)

            // Status badge
            statusBadge
                .frame(width: 20)
        }
    }

    // MARK: Sub-views

    @ViewBuilder
    private var fileIcon: some View {
        let ext = item.fileExtension.isEmpty ? "" : String(item.fileExtension.dropFirst())
        Image(systemName: systemIcon(for: ext))
            .font(.system(size: 16))
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var statusBadge: some View {
        if item.hasErrors {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13))
                .foregroundStyle(.orange)
        } else if item.willChange {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 13))
                .foregroundStyle(.green)
        } else if !item.willChange && item.previewStem != nil {
            // Name would not change
            Image(systemName: "minus.circle")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
        } else {
            EmptyView()
        }
    }

    private func systemIcon(for ext: String) -> String {
        switch ext.lowercased() {
        case "jpg", "jpeg", "png", "gif", "webp", "heic", "tiff", "bmp", "svg":
            return "photo"
        case "mp4", "mov", "avi", "mkv", "m4v":
            return "film"
        case "mp3", "m4a", "aac", "wav", "flac", "aiff":
            return "music.note"
        case "pdf":
            return "doc.richtext"
        case "doc", "docx":
            return "doc.text"
        case "xls", "xlsx", "csv":
            return "tablecells"
        case "ppt", "pptx":
            return "rectangle.on.rectangle"
        case "zip", "rar", "7z", "gz", "tar":
            return "archivebox"
        case "swift", "py", "js", "ts", "html", "css", "json", "xml", "sh":
            return "doc.plaintext"
        default:
            return "doc"
        }
    }
}
