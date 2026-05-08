// MARK: - RenameEngine
import Foundation

/// Applies an ordered pipeline of `RenameRule`s to filename stems.
/// This is a pure service — no I/O, no state, no side effects.
struct RenameEngine {
    private static let cleanFilenameForbiddenScalars = CharacterSet(charactersIn: "/:*?\"<>|\\")
        .union(.controlCharacters)
    private static let cleanFilenameTrimCharacters = CharacterSet(charactersIn: "_")
        .union(.whitespaces)

    // MARK: Public

    /// Applies `rules` to `items` and returns new stems.
    /// The index rule uses the file's position in the array.
    /// File extensions are preserved externally; this engine works on stems only.
    func apply(rules: [RenameRule], to items: [RenameItem]) -> [String] {
        let context = RenameContext(rules: rules)

        return items.enumerated().map { index, item in
            var stem = item.originalStem
            for (ruleIndex, rule) in rules.enumerated() {
                stem = applyRule(rule, to: stem, index: index, ruleIndex: ruleIndex, context: context)
            }
            return stem
        }
    }

    // MARK: Private

    private func applyRule(
        _ rule: RenameRule,
        to stem: String,
        index: Int,
        ruleIndex: Int,
        context: RenameContext
    ) -> String {
        switch rule {

        case .remove(let text):
            return stem.replacingOccurrences(of: text, with: "", options: [.caseInsensitive])

        case .replace(let old, let new):
            return stem.replacingOccurrences(of: old, with: new, options: [.caseInsensitive])

        case .renameAll(let base):
            let number = String(format: "%02d", index + 1)
            return "\(base)_\(number)"

        case .addPrefix(let text):
            return stem.hasPrefix(text) ? stem : text + stem

        case .addSuffix(let text):
            return stem.hasSuffix(text) ? stem : stem + text

        case .addIndex(let start, let digits, let placement):
            let n = start + index
            let formatted = String(format: "%0\(digits)d", n)
            return placeIfMissing(formatted, in: stem, placement: placement, separator: "_")

        case .addDate(let format, let placement):
            let dateString = context.dateStrings[format] ?? ""
            return placeIfMissing(dateString, in: stem, placement: placement, separator: "_")

        case .lowercase:
            return stem.lowercased()

        case .uppercase:
            return stem.uppercased()

        case .cleanFilename:
            return cleanFilename(stem)

        case .cleanText(let text):
            let charactersToRemove = context.cleanTextCharacters[ruleIndex] ?? Set(text.lowercased())
            return cleanText(charactersToRemove: charactersToRemove, from: stem)
        }
    }

    private func placeIfMissing(
        _ value: String,
        in stem: String,
        placement: RenamePlacement,
        separator: String
    ) -> String {
        switch placement {
        case .prefix:
            let placedValue = value + separator
            guard !stem.hasPrefix(placedValue), stem != value else { return stem }
            return placedValue + stem
        case .suffix:
            let appendedValue = separator + value
            guard !stem.hasSuffix(appendedValue), stem != value else { return stem }
            return stem + appendedValue
        }
    }

    fileprivate static func formattedDateStrings(for rules: [RenameRule]) -> [String: String] {
        let formats = Set(rules.compactMap { rule -> String? in
            guard case .addDate(let format, _) = rule else { return nil }
            return format
        })
        guard !formats.isEmpty else { return [:] }

        let date = Date()
        return Dictionary(uniqueKeysWithValues: formats.map { format in
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return (format, formatter.string(from: date))
        })
    }

    /// Removes or replaces characters that are problematic in filenames.
    /// - Replaces multiple whitespace runs with a single underscore.
    /// - Removes leading/trailing whitespace and underscores.
    /// - Collapses multiple underscores.
    /// - Removes characters that are forbidden on common filesystems.
    private func cleanFilename(_ stem: String) -> String {
        var result = stem

        // Replace runs of whitespace with _
        result = result.replacingOccurrences(
            of: "\\s+",
            with: "_",
            options: .regularExpression
        )

        // Remove characters forbidden in filenames: / : * ? " < > | \ 0x00
        var allowedScalars = String.UnicodeScalarView()
        for scalar in result.unicodeScalars where !Self.cleanFilenameForbiddenScalars.contains(scalar) {
            allowedScalars.append(scalar)
        }
        result = String(allowedScalars)

        // Collapse multiple underscores
        result = result.replacingOccurrences(
            of: "_+",
            with: "_",
            options: .regularExpression
        )

        // Trim leading/trailing underscores and whitespace
        result = result.trimmingCharacters(in: Self.cleanFilenameTrimCharacters)

        return result.isEmpty ? stem : result
    }

    private func cleanText(charactersToRemove: Set<Character>, from stem: String) -> String {
        let result = stem.filter { character in
            !charactersToRemove.contains(String(character).lowercased().first ?? character)
        }
        return result.isEmpty ? stem : result
    }
}

private struct RenameContext {
    let dateStrings: [String: String]
    let cleanTextCharacters: [Int: Set<Character>]

    init(rules: [RenameRule]) {
        self.dateStrings = RenameEngine.formattedDateStrings(for: rules)
        self.cleanTextCharacters = Dictionary(uniqueKeysWithValues: rules.enumerated().compactMap { index, rule in
            guard case .cleanText(let text) = rule else { return nil }
            return (index, Set(text.lowercased()))
        })
    }
}
