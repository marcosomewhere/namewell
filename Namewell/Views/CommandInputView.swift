// MARK: - CommandInputView
import AppKit
import SwiftUI

struct CommandInputView: View {

    @ObservedObject var viewModel: RenameViewModel
    @FocusState private var isFocused: Bool

    private var autocompleteSuggestions: [CommandSuggestion] {
        CommandSuggestion.matches(for: viewModel.commandText)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                // Prompt indicator
                Text(">")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.accentColor)

                // Text field
                TextField(
                    L10n.string("command.placeholder", comment: ""),
                    text: $viewModel.commandText
                )
                .font(.system(size: 14, design: .monospaced))
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onSubmit {
                    if !applyFirstAutocompleteSuggestion() {
                        viewModel.performRename()
                    }
                }

                // Clear button
                if !viewModel.commandText.isEmpty {
                    Button {
                        viewModel.commandText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                }

                // Parse status indicator
                if let _ = viewModel.parseError {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.system(size: 14))
                } else if !viewModel.commandText.isEmpty && viewModel.parseError == nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 14))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isFocused ? Color.accentColor : Color(nsColor: .separatorColor),
                        lineWidth: isFocused ? 1.5 : 0.5
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(nsColor: .textBackgroundColor))
                    )
            }

            if isFocused && !autocompleteSuggestions.isEmpty {
                AutocompleteSuggestionView(
                    suggestions: autocompleteSuggestions,
                    onSelect: applyAutocompleteSuggestion
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Parse error message
            if let error = viewModel.parseError {
                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 11))
                    Text(error)
                        .font(.system(size: 11))
                }
                .foregroundStyle(.orange)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Command hint chips
            CommandHintView(
                commandText: viewModel.commandText,
                onSelect: toggleCommandSuggestion
            )
        }
        .animation(.easeInOut(duration: 0.15), value: viewModel.parseError)
        .animation(.easeInOut(duration: 0.15), value: viewModel.commandText.isEmpty)
        .animation(.easeInOut(duration: 0.12), value: autocompleteSuggestions)
    }

    @discardableResult
    private func applyFirstAutocompleteSuggestion() -> Bool {
        guard let suggestion = autocompleteSuggestions.first else { return false }
        applyAutocompleteSuggestion(suggestion)
        return true
    }

    private func applyAutocompleteSuggestion(_ suggestion: CommandSuggestion) {
        let cursorOffset = CommandSuggestion.cursorOffset(afterApplying: suggestion, to: viewModel.commandText)
        viewModel.commandText = CommandSuggestion.applying(suggestion, to: viewModel.commandText)
        isFocused = true
        placeCursorIfNeeded(at: cursorOffset)
    }

    private func toggleCommandSuggestion(_ suggestion: CommandSuggestion) {
        let currentCommand = viewModel.commandText.trimmingCharacters(in: .whitespacesAndNewlines)
        let suggestedCommand = suggestion.completion.trimmingCharacters(in: .whitespacesAndNewlines)

        if !suggestion.requiresArgument && currentCommand == suggestedCommand {
            viewModel.commandText = ""
        } else {
            applyAutocompleteSuggestion(suggestion)
        }
        isFocused = true
    }

    private func placeCursorIfNeeded(at offset: Int?) {
        guard let offset else { return }

        DispatchQueue.main.async {
            guard let fieldEditor = NSApp.keyWindow?.firstResponder as? NSTextView else { return }
            let clampedOffset = min(max(offset, 0), fieldEditor.string.utf16.count)
            fieldEditor.setSelectedRange(NSRange(location: clampedOffset, length: 0))
        }
    }
}

// MARK: - Autocomplete Suggestions

private struct AutocompleteSuggestionView: View {
    let suggestions: [CommandSuggestion]
    let onSelect: (CommandSuggestion) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(suggestions) { suggestion in
                    Button {
                        onSelect(suggestion)
                    } label: {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(suggestion.completion)
                                .font(.system(size: 11, design: .monospaced))
                                .lineLimit(1)
                            if let detail = suggestion.detail {
                                Text(detail)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.18), in: RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)
                    .help(suggestion.completion)
                }
            }
            .padding(.vertical, 1)
        }
    }
}

// MARK: - Command Hint Chips

private struct CommandHintView: View {

    let commandText: String
    let onSelect: (CommandSuggestion) -> Void

    @State private var showHints = false

    var body: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    showHints.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: showHints ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                    Text(L10n.string("command.hints", comment: ""))
                        .font(.system(size: 11))
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()
        }

        if showHints {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(CommandSuggestion.all) { suggestion in
                        ChipView(
                            suggestion: suggestion,
                            isActive: isActive(suggestion),
                            onSelect: onSelect
                        )
                    }
                }
                .padding(.vertical, 2)
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private func isActive(_ suggestion: CommandSuggestion) -> Bool {
        guard !suggestion.requiresArgument else { return false }
        return commandText.trimmingCharacters(in: .whitespacesAndNewlines)
            == suggestion.completion.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct ChipView: View {
    let suggestion: CommandSuggestion
    let isActive: Bool
    let onSelect: (CommandSuggestion) -> Void

    var body: some View {
        Button {
            onSelect(suggestion)
        } label: {
            HStack(spacing: 4) {
                if isActive {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                }
                Text(suggestion.label)
                    .font(.system(size: 11, design: .monospaced))
            }
            .foregroundStyle(isActive ? Color.accentColor : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                isActive ? Color.accentColor.opacity(0.16) : Color(nsColor: .quaternaryLabelColor).opacity(0.18),
                in: RoundedRectangle(cornerRadius: 4)
            )
        }
        .buttonStyle(.plain)
        .help(isActive ? "Ausschalten" : suggestion.completion)
    }
}
