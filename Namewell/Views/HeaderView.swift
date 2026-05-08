// MARK: - HeaderView
import SwiftUI

struct HeaderView: View {

    @ObservedObject var viewModel: RenameViewModel
    @State private var isShowingAbout = false
    @State private var isShowingSettings = false
    @AppStorage("settings.languageCode") private var languageCode = AppLanguage.system.rawValue

    var body: some View {
        HStack(spacing: 12) {
            // App wordmark
            HStack(spacing: 0) {
                Image("BrandIcon")
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 34, height: 34)
            }

            Spacer()

            // Folder path pill
            if let url = viewModel.currentFolderURL {
                Button {
                    viewModel.openFolder()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Text(url.lastPathComponent)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: 260)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Undo button
            Button {
                viewModel.undoLastRename()
            } label: {
                Label(L10n.string("action.undo", comment: ""), systemImage: "arrow.uturn.backward")
                    .font(.system(size: 13))
            }
            .disabled(!viewModel.undoService.canUndo)
            .help(L10n.string("help.undo", comment: ""))
            .keyboardShortcut("z", modifiers: .command)

            // Redo button
            Button {
                viewModel.redoLastRename()
            } label: {
                Label(L10n.string("action.redo", comment: ""), systemImage: "arrow.uturn.forward")
                    .font(.system(size: 13))
            }
            .disabled(!viewModel.undoService.canRedo)
            .help(L10n.string("help.redo", comment: ""))
            .keyboardShortcut("z", modifiers: [.command, .shift])

            // Rename button
            Button {
                viewModel.performRename()
            } label: {
                HStack(spacing: 6) {
                    if viewModel.isRenaming {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 12, height: 12)
                    }
                    Text(L10n.string("action.rename", comment: ""))
                        .font(.system(size: 13, weight: .semibold))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canRename)
            .help(L10n.string("help.rename", comment: ""))
            .keyboardShortcut(.return, modifiers: .command)

            // Settings button
            Button {
                isShowingAbout = false
                isShowingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help(L10n.string("help.settings", comment: ""))
            .popover(isPresented: $isShowingSettings, arrowEdge: .bottom) {
                SettingsView()
            }

            // About button
            Button {
                isShowingSettings = false
                isShowingAbout = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help(L10n.string("help.about", comment: ""))
            .popover(isPresented: $isShowingAbout, arrowEdge: .bottom) {
                AboutView()
            }
        }
        .id(languageCode)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Settings

private struct SettingsView: View {

    @Environment(\.dismiss) private var dismiss
    @AppStorage("settings.languageCode") private var languageCode = AppLanguage.system.rawValue

    private var selectedLanguage: Binding<AppLanguage> {
        Binding {
            AppLanguage(rawValue: languageCode) ?? .system
        } set: { language in
            languageCode = language.rawValue
            applyLanguage(language)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label(L10n.string("settings.title", comment: ""), systemImage: "gearshape")
                    .font(.system(size: 20, weight: .semibold))

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .help(L10n.string("alert.ok", comment: ""))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.string("settings.general", comment: ""))
                    .font(.system(size: 13, weight: .semibold))

                VStack(alignment: .leading, spacing: 0) {
                    SettingsRow {
                        HStack {
                            Text(L10n.string("settings.storage", comment: ""))
                            Spacer()
                            Text(L10n.string("settings.local", comment: ""))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.string("settings.language", comment: ""))
                    .font(.system(size: 13, weight: .semibold))

                VStack(alignment: .leading, spacing: 0) {
                    SettingsRow {
                        Picker(L10n.string("settings.appLanguage", comment: ""), selection: selectedLanguage) {
                            ForEach(AppLanguage.allCases) { language in
                                Text(language.title).tag(language)
                            }
                        }
                    }

                    Divider()

                    SettingsRow {
                        Text(L10n.string("settings.restartHint", comment: ""))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(24)
        .frame(width: 520)
        .onAppear {
            applyLanguage(AppLanguage(rawValue: languageCode) ?? .system)
        }
    }

    private func applyLanguage(_ language: AppLanguage) {
        switch language {
        case .system:
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        default:
            UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
        }
    }
}

private enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case english = "en"
    case german = "de"
    case french = "fr"
    case polish = "pl"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return L10n.string("settings.languageSystem", comment: "")
        case .english:
            return "English"
        case .german:
            return "Deutsch"
        case .french:
            return "Français"
        case .polish:
            return "Polski"
        }
    }
}

private struct SettingsRow<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .font(.system(size: 13))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
    }
}

// MARK: - About

private struct AboutView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var isShowingHowToUse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 10) {
                Image("BrandIcon")
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Namewell")
                        .font(.system(size: 22, weight: .semibold))
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .help(L10n.string("alert.ok", comment: ""))
            }

            VStack(alignment: .leading, spacing: 0) {
                AboutRow {
                    HStack(spacing: 5) {
                        Text(L10n.string("about.madeWith", comment: ""))
                        Image(systemName: "heart.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text(L10n.string("about.author", comment: ""))
                    }
                }

                Divider()

                AboutRow {
                    HStack {
                        Text(L10n.string("about.developmentStatus", comment: ""))
                        Spacer()
                        Text("2026")
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                AboutRow {
                    Text(L10n.string("about.description", comment: ""))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider()

                AboutRow {
                    Button {
                        isShowingHowToUse = true
                    } label: {
                        Label(L10n.string("about.howToUse", comment: ""), systemImage: "questionmark.circle")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.string("about.securityTitle", comment: ""))
                    .font(.system(size: 13, weight: .semibold))

                VStack(alignment: .leading, spacing: 0) {
                    AboutRow {
                        Text(L10n.string("about.localOnly", comment: ""))
                    }

                    Divider()

                    AboutRow {
                        Text(L10n.string("about.privacy", comment: ""))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(24)
        .frame(width: 520)
        .sheet(isPresented: $isShowingHowToUse) {
            HowToUseView()
        }
    }
}

private struct HowToUseView: View {

    @Environment(\.dismiss) private var dismiss

    private let examples = [
        ("remove clip", "howto.example.remove"),
        ("replace \" \" with \"_\"", "howto.example.replace"),
        ("rename to photo", "howto.example.renameAll"),
        ("add date prefix", "howto.example.datePrefix"),
        ("add date suffix", "howto.example.dateSuffix"),
        ("add custom text prefix", "howto.example.customPrefix"),
        ("add custom text suffix", "howto.example.customSuffix"),
        ("lowercase", "howto.example.lowercase"),
        ("clean filename", "howto.example.clean")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label(L10n.string("howto.title", comment: ""), systemImage: "questionmark.circle")
                    .font(.system(size: 20, weight: .semibold))

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .help(L10n.string("alert.ok", comment: ""))
            }

            VStack(alignment: .leading, spacing: 0) {
                AboutRow {
                    Text(L10n.string("howto.step.openFolder", comment: ""))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider()

                AboutRow {
                    Text(L10n.string("howto.step.chooseCommand", comment: ""))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider()

                AboutRow {
                    Text(L10n.string("howto.step.preview", comment: ""))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.string("howto.examples", comment: ""))
                    .font(.system(size: 13, weight: .semibold))

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(examples.indices, id: \.self) { index in
                        let example = examples[index]
                        AboutRow {
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text(example.0)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 180, alignment: .leading)
                                    .textSelection(.enabled)

                                Text(L10n.string(example.1, comment: ""))
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        if index < examples.count - 1 {
                            Divider()
                        }
                    }
                }
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            }

            Text(L10n.string("howto.note", comment: ""))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(width: 640)
    }
}

private struct AboutRow<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .font(.system(size: 13))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
    }
}
