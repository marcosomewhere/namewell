// MARK: - CommandSuggestion
import Foundation

struct CommandSuggestion: Identifiable, Equatable {
    let id: String
    let label: String
    let completion: String
    let detail: String?
    let searchTerms: [String]
    let requiresArgument: Bool
    let cursorOffset: Int?

    private static let reservedAddKeywords = ["date", "index", "prefix", "suffix", "text"]

    static let all: [CommandSuggestion] = [
        CommandSuggestion(label: "remove text", completion: "remove text ", detail: "text entfernen", searchTerms: ["remove", "remove text", "text entfernen"], requiresArgument: true),
        CommandSuggestion(label: "replace", completion: "replace \"\" with \"\"", detail: "text ersetzen", searchTerms: ["replace", "replace text", "text ersetzen"], requiresArgument: true, cursorOffset: "replace \"".count),
        CommandSuggestion(label: "replace all", completion: "replace all with ", detail: "alles neu benennen", searchTerms: ["replace all", "replace all with", "all", "alles ersetzen", "neu benennen"], requiresArgument: true),
        CommandSuggestion(label: "rename to", completion: "rename to ", detail: "neue namen mit index", searchTerms: ["rename", "rename to", "new name", "neu benennen", "neuer name"], requiresArgument: true),
        CommandSuggestion(label: "add text prefix", completion: "add text  prefix", detail: "text vorne", searchTerms: ["add", "add text", "add text prefix", "text", "text vorne"], requiresArgument: true, cursorOffset: "add text ".count),
        CommandSuggestion(label: "add text suffix", completion: "add text  suffix", detail: "text hinten", searchTerms: ["add", "add text", "add text suffix", "text", "text hinten"], requiresArgument: true, cursorOffset: "add text ".count),
        CommandSuggestion(label: "prefix text", completion: "add prefix ", detail: "text vorne", searchTerms: ["add", "prefix", "add prefix"], requiresArgument: true),
        CommandSuggestion(label: "suffix text", completion: "add suffix ", detail: "text hinten", searchTerms: ["add", "suffix", "add suffix"], requiresArgument: true),
        CommandSuggestion(label: "date prefix", completion: "add date prefix", detail: "datum vorne", searchTerms: ["add", "add date", "add date prefix", "date", "date prefix", "datum", "datum vorne"], requiresArgument: false),
        CommandSuggestion(label: "date suffix", completion: "add date suffix", detail: "datum hinten", searchTerms: ["add", "add date", "add date suffix", "date", "date suffix", "datum", "datum hinten"], requiresArgument: false),
        CommandSuggestion(label: "index prefix", completion: "add index prefix", detail: "nummer vorne", searchTerms: ["add", "add index", "add index prefix", "index", "index prefix", "nummer", "nummer vorne"], requiresArgument: false),
        CommandSuggestion(label: "index suffix", completion: "add index suffix", detail: "nummer hinten", searchTerms: ["add", "add index", "add index suffix", "index", "index suffix", "nummer", "nummer hinten"], requiresArgument: false),
        CommandSuggestion(label: "lowercase", completion: "lowercase", detail: nil, searchTerms: ["lowercase"], requiresArgument: false),
        CommandSuggestion(label: "uppercase", completion: "uppercase", detail: nil, searchTerms: ["uppercase"], requiresArgument: false),
        CommandSuggestion(label: "clean filename", completion: "clean filename", detail: "dateiname säubern", searchTerms: ["clean", "clean filename", "dateiname säubern"], requiresArgument: false),
        CommandSuggestion(label: "clean text", completion: "clean text ", detail: "zeichen entfernen", searchTerms: ["clean", "clean text", "zeichen entfernen"], requiresArgument: true),
    ]

    init(
        label: String,
        completion: String,
        detail: String?,
        searchTerms: [String],
        requiresArgument: Bool,
        cursorOffset: Int? = nil
    ) {
        self.id = label
        self.label = label
        self.completion = completion
        self.detail = detail
        self.searchTerms = searchTerms
        self.requiresArgument = requiresArgument
        self.cursorOffset = cursorOffset
    }

    static func matches(for input: String, limit: Int = 8) -> [CommandSuggestion] {
        let segmentStart = currentSegmentStart(in: input)
        let segment = currentSegment(in: input, start: segmentStart)
        let query = segment.lowercased()

        if query.isEmpty, segmentStart != nil {
            return Array(all.prefix(limit))
        }

        guard !query.isEmpty else { return [] }

        let commandSuggestions = all
            .filter { suggestion in
                suggestion.searchTerms.contains { $0.hasPrefix(query) }
            }

        if !commandSuggestions.isEmpty {
            return Array(commandSuggestions.prefix(limit))
        }

        return Array(customAddPlacementSuggestions(for: segment).prefix(limit))
    }

    static func applying(_ suggestion: CommandSuggestion, to input: String) -> String {
        let trimmedInput = input.trimmingCharacters(in: .whitespaces)
        guard !trimmedInput.isEmpty else { return suggestion.completion }

        guard let currentStart = currentSegmentStart(in: input) else { return suggestion.completion }
        let prefix = input[..<currentStart]
        guard !prefix.isEmpty else { return suggestion.completion }
        return String(prefix) + suggestion.completion
    }

    static func cursorOffset(afterApplying suggestion: CommandSuggestion, to input: String) -> Int? {
        guard let cursorOffset = suggestion.cursorOffset else { return nil }

        let trimmedInput = input.trimmingCharacters(in: .whitespaces)
        guard !trimmedInput.isEmpty,
              let currentStart = currentSegmentStart(in: input),
              !input[..<currentStart].isEmpty else {
            return cursorOffset
        }

        return (String(input[..<currentStart]) as NSString).length + cursorOffset
    }

    private static func currentSegment(in input: String, start: String.Index?) -> String {
        guard let start else {
            return input.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return String(input[start...]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func currentSegmentStart(in input: String) -> String.Index? {
        CommandSyntax.currentSegmentStart(in: input)
    }

    private static func customAddPlacementSuggestions(for segment: String) -> [CommandSuggestion] {
        let lowerSegment = segment.lowercased()
        guard lowerSegment.hasPrefix("add ") else { return [] }

        var text = String(segment.dropFirst("add ".count)).trimmingCharacters(in: .whitespacesAndNewlines)
        if text.lowercased().hasPrefix("text ") {
            text = String(text.dropFirst("text ".count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let lowerText = text.lowercased()

        guard !text.isEmpty,
              !isReservedAddPrefix(lowerText),
              !lowerText.hasPrefix("prefix "),
              !lowerText.hasPrefix("suffix "),
              !lowerText.hasSuffix(" prefix"),
              !lowerText.hasSuffix(" suffix") else {
            return []
        }

        return [
            CommandSuggestion(
                label: "\(text) prefix",
                completion: "add text \(text) prefix",
                detail: "text vorne",
                searchTerms: [lowerSegment],
                requiresArgument: false
            ),
            CommandSuggestion(
                label: "\(text) suffix",
                completion: "add text \(text) suffix",
                detail: "text hinten",
                searchTerms: [lowerSegment],
                requiresArgument: false
            ),
        ]
    }

    private static func isReservedAddPrefix(_ text: String) -> Bool {
        reservedAddKeywords.contains { reserved in
            reserved.hasPrefix(text) || text.hasPrefix(reserved + " ")
        }
    }
}
