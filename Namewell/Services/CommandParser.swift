// MARK: - CommandParser
import Foundation

/// Parses a natural-language rename command string into an ordered array of `RenameRule`s.
///
/// Supported syntax (case-insensitive):
///   remove <text>
///   remove text <text>
///   replace <old> with <new>
///   replace all with <text>
///   rename to <text>
///   add prefix <text>
///   add suffix <text>
///   add <text> [prefix|suffix]
///   add text <text> [prefix|suffix]
///   add index [prefix|suffix]
///   add date [prefix|suffix]
///   lowercase
///   uppercase
///   clean filename
///   clean <text>
///   clean text <text>
///
/// Combinations via AND/and, &, &&, comma, semicolon, or THEN/then:
///   remove IMG_ AND add index
///   replace " " with "_" then lowercase
///
/// This is a pure function — no I/O, no state.
struct CommandParser {

    // MARK: Public

    enum ParseResult {
        case success([RenameRule])
        case failure(String)
        case empty
    }

    func parse(_ input: String) -> ParseResult {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return .empty }

        let segments = splitByConnectors(trimmed)
        var rules: [RenameRule] = []

        for segment in segments {
            let s = segment.trimmingCharacters(in: .whitespaces)
            if s.isEmpty {
                return .failure(String(format: L10n.string("parser.unknownCommand", comment: ""), s))
            } else if isIncompleteSegment(s) {
                return .failure(L10n.string("parser.incompleteCommand", comment: ""))
            } else if let rule = parseSegment(s) {
                rules.append(rule)
            } else {
                return .failure(String(format: L10n.string("parser.unknownCommand", comment: ""), s))
            }
        }

        return rules.isEmpty ? .empty : .success(rules)
    }

    // MARK: Private

    private func splitByConnectors(_ input: String) -> [String] {
        CommandSyntax.splitByConnectors(input)
    }

    private func isIncompleteSegment(_ s: String) -> Bool {
        let lower = s.lowercased()
        return [
            "replace",
            "replace all with",
            "rename to",
            "remove",
            "remove text",
            "clean text",
            "add prefix",
            "add suffix",
            "add text",
        ].contains(lower) || lower.hasSuffix(" with")
    }

    private func parseSegment(_ s: String) -> RenameRule? {
        let lower = s.lowercased()

        // lowercase
        if lower == "lowercase" { return .lowercase }

        // uppercase
        if lower == "uppercase" { return .uppercase }

        // clean filename
        if lower == "clean filename" || lower == "clean" { return .cleanFilename }

        // rename to <text>
        if lower.hasPrefix("rename to ") {
            let text = extractArgument(from: s, afterPrefix: "rename to ")
            guard !text.isEmpty else { return nil }
            return .renameAll(base: text)
        }

        // replace all with <text>
        if lower.hasPrefix("replace all with ") {
            let text = extractArgument(from: s, afterPrefix: "replace all with ")
            guard !text.isEmpty else { return nil }
            return .renameAll(base: text)
        }

        // clean <text>
        if lower.hasPrefix("clean ") {
            let text = extractArgumentSkippingTextKeyword(from: s, afterPrefix: "clean ")
            guard !text.isEmpty else { return nil }
            return .cleanText(text: text)
        }

        // add index
        if lower == "add index" || lower == "add index suffix" || lower == "add suffix index" {
            return .addIndex(startingAt: 1, digits: 2, placement: .suffix)
        }

        if lower == "add index prefix" || lower == "add prefix index" {
            return .addIndex(startingAt: 1, digits: 2, placement: .prefix)
        }

        // add date
        if lower == "add date" || lower == "add date suffix" || lower == "add suffix date" {
            return .addDate(format: "yyyy-MM-dd", placement: .suffix)
        }

        if lower == "add date prefix" || lower == "add prefix date" {
            return .addDate(format: "yyyy-MM-dd", placement: .prefix)
        }

        // remove <text>
        if lower.hasPrefix("remove ") {
            let text = extractArgumentSkippingTextKeyword(from: s, afterPrefix: "remove ")
            guard !text.isEmpty else { return nil }
            return .remove(text: text)
        }

        // add prefix <text>
        if lower.hasPrefix("add prefix ") {
            let text = extractArgument(from: s, afterPrefix: "add prefix ")
            guard !text.isEmpty else { return nil }
            return .addPrefix(text: text)
        }

        // add suffix <text>
        if lower.hasPrefix("add suffix ") {
            let text = extractArgument(from: s, afterPrefix: "add suffix ")
            guard !text.isEmpty else { return nil }
            return .addSuffix(text: text)
        }

        // add <text> [prefix|suffix]
        if lower.hasPrefix("add ") {
            return parseCustomAdd(s)
        }

        // replace <old> with <new>
        if lower.hasPrefix("replace ") {
            return parseReplace(s)
        }

        return nil
    }

    /// Extracts the argument after a known prefix, stripping optional surrounding quotes.
    private func extractArgument(from s: String, afterPrefix prefix: String) -> String {
        let rest = String(s.dropFirst(prefix.count))
        return stripQuotes(rest)
    }

    private func extractArgumentSkippingTextKeyword(from s: String, afterPrefix prefix: String) -> String {
        let textKeyword = "text "
        let argument = extractArgument(from: s, afterPrefix: prefix)

        guard argument.lowercased().hasPrefix(textKeyword) else {
            return argument
        }

        return stripQuotes(String(argument.dropFirst(textKeyword.count)))
    }

    private func stripQuotes(_ s: String) -> String {
        let trimmed = s.trimmingCharacters(in: .whitespaces)
        if (trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"")) ||
           (trimmed.hasPrefix("'") && trimmed.hasSuffix("'")) {
            return String(trimmed.dropFirst().dropLast())
        }
        return trimmed
    }

    /// Parses `add <text>`, plus the trailing placement variants
    /// `add <text> prefix` and `add <text> suffix`.
    private func parseCustomAdd(_ s: String) -> RenameRule? {
        var rest = String(s.dropFirst("add ".count)).trimmingCharacters(in: .whitespaces)
        guard !rest.isEmpty else { return nil }

        if rest.lowercased().hasPrefix("text ") {
            rest = String(rest.dropFirst("text ".count)).trimmingCharacters(in: .whitespaces)
        }

        let lowerRest = rest.lowercased()

        if lowerRest.hasSuffix(" prefix") {
            let text = stripQuotes(String(rest.dropLast(" prefix".count)))
            guard !text.isEmpty else { return nil }
            return .addPrefix(text: text)
        }

        if lowerRest.hasSuffix(" suffix") {
            let text = stripQuotes(String(rest.dropLast(" suffix".count)))
            guard !text.isEmpty else { return nil }
            return .addSuffix(text: text)
        }

        let text = stripQuotes(rest)
        guard !text.isEmpty else { return nil }
        return .addSuffix(text: text)
    }

    /// Parses `replace <old> with <new>` handling quoted and unquoted arguments.
    private func parseReplace(_ s: String) -> RenameRule? {
        // Drop "replace "
        let rest = String(s.dropFirst("replace ".count))

        // Find " with " separator (outside of quotes)
        guard let (oldPart, newPart) = splitByWith(rest) else { return nil }
        let old = stripQuotes(oldPart)
        let new = stripQuotes(newPart)
        return .replace(old: old, new: new)
    }

    private func splitByWith(_ s: String) -> (String, String)? {
        let lower = s.lowercased()
        // Search for " with " outside quotes
        var inQuote = false
        var quoteChar: Character = "\""
        var i = lower.startIndex

        while i < lower.endIndex {
            let ch = lower[i]
            if inQuote {
                if ch == quoteChar { inQuote = false }
                i = lower.index(after: i)
                continue
            }
            if ch == "\"" || ch == "'" {
                inQuote = true
                quoteChar = ch
                i = lower.index(after: i)
                continue
            }
            let keyword = " with "
            if lower.distance(from: i, to: lower.endIndex) >= keyword.count {
                let candidate = String(lower[i...].prefix(keyword.count))
                if candidate == keyword {
                    let oldPart = String(s[s.startIndex..<i])
                    let afterWith = lower.index(i, offsetBy: keyword.count)
                    let newPart = String(s[s.index(s.startIndex, offsetBy: lower.distance(from: lower.startIndex, to: afterWith))...])
                    return (oldPart, newPart)
                }
            }
            i = lower.index(after: i)
        }
        return nil
    }
}

enum CommandSyntax {
    static func splitByConnectors(_ input: String) -> [String] {
        var segments: [String] = []
        var current = ""
        var scanner = QuoteAwareScanner(input)

        while let character = scanner.currentCharacter {
            if scanner.consumeQuoteIfNeeded() {
                current.append(character)
                continue
            }

            if let nextIndex = matchConnector(in: input, at: scanner.currentIndex) {
                segments.append(current)
                current = ""
                scanner.move(to: nextIndex)
                continue
            }

            current.append(character)
            scanner.advance()
        }

        segments.append(current)
        return segments
    }

    static func currentSegmentStart(in input: String) -> String.Index? {
        var scanner = QuoteAwareScanner(input)
        var lastStart: String.Index?

        while scanner.currentCharacter != nil {
            if scanner.consumeQuoteIfNeeded() {
                continue
            }

            if let nextIndex = matchConnector(in: input, at: scanner.currentIndex) {
                lastStart = nextIndex
                scanner.move(to: nextIndex)
                continue
            }

            scanner.advance()
        }

        return lastStart
    }

    /// Returns the index after a connector if it matches at position `index`.
    private static func matchConnector(in input: String, at index: String.Index) -> String.Index? {
        let character = input[index]

        if character == "," || character == ";" {
            return skipSpaces(in: input, from: input.index(after: index))
        }

        if character == "&" {
            let next = input.index(after: index)
            if next < input.endIndex, input[next] == "&" {
                return skipSpaces(in: input, from: input.index(after: next))
            }
            return skipSpaces(in: input, from: next)
        }

        guard isAtWordBoundary(in: input, at: index) else { return nil }

        for keyword in ["and", "then"] {
            guard input.distance(from: index, to: input.endIndex) >= keyword.count else { continue }
            let end = input.index(index, offsetBy: keyword.count)
            let candidate = String(input[index..<end]).lowercased()
            if candidate == keyword, isAtWordBoundary(in: input, at: end) {
                return skipSpaces(in: input, from: end)
            }
        }

        return nil
    }

    private static func isAtWordBoundary(in input: String, at index: String.Index) -> Bool {
        if index == input.startIndex || index == input.endIndex { return true }
        let previous = input[input.index(before: index)]
        let current = input[index]
        return previous.isWhitespace || current.isWhitespace
    }

    private static func skipSpaces(in input: String, from index: String.Index) -> String.Index {
        var i = index
        while i < input.endIndex, input[i].isWhitespace {
            i = input.index(after: i)
        }
        return i
    }
}

private struct QuoteAwareScanner {
    private let input: String
    private(set) var currentIndex: String.Index
    private var inQuote = false
    private var quoteCharacter: Character = "\""

    init(_ input: String) {
        self.input = input
        self.currentIndex = input.startIndex
    }

    var currentCharacter: Character? {
        guard currentIndex < input.endIndex else { return nil }
        return input[currentIndex]
    }

    mutating func consumeQuoteIfNeeded() -> Bool {
        guard let character = currentCharacter else { return false }

        if inQuote {
            if character == quoteCharacter {
                inQuote = false
            }
            advance()
            return true
        }

        guard character == "\"" || character == "'" else { return false }
        inQuote = true
        quoteCharacter = character
        advance()
        return true
    }

    mutating func advance() {
        currentIndex = input.index(after: currentIndex)
    }

    mutating func move(to index: String.Index) {
        currentIndex = index
    }
}
