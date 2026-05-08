import XCTest
@testable import Namewell

// MARK: - Localization Tests

final class L10nTests: XCTestCase {

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "settings.languageCode")
        super.tearDown()
    }

    func test_explicitGermanLanguageUsesGermanStrings() {
        UserDefaults.standard.set("de", forKey: "settings.languageCode")
        XCTAssertEqual(L10n.string("action.rename"), "Umbenennen")
    }

    func test_languageIdentifiersAreNormalized() {
        XCTAssertEqual(L10n.resolvedLanguageCode(for: "de-DE"), "de")
    }
}

// MARK: - CommandParser Tests

final class CommandParserTests: XCTestCase {

    let parser = CommandParser()

    func test_empty_input_returns_empty() {
        guard case .empty = parser.parse("") else {
            XCTFail("Expected .empty"); return
        }
    }

    func test_whitespace_only_returns_empty() {
        guard case .empty = parser.parse("   ") else {
            XCTFail("Expected .empty"); return
        }
    }

    func test_lowercase() {
        guard case .success(let rules) = parser.parse("lowercase") else {
            XCTFail("Expected success"); return
        }
        XCTAssertEqual(rules, [.lowercase])
    }

    func test_uppercase() {
        guard case .success(let rules) = parser.parse("UPPERCASE") else {
            XCTFail("Expected success"); return
        }
        XCTAssertEqual(rules, [.uppercase])
    }

    func test_remove() {
        guard case .success(let rules) = parser.parse("remove IMG_") else {
            XCTFail("Expected success"); return
        }
        XCTAssertEqual(rules, [.remove(text: "IMG_")])
    }

    func test_remove_text_alias() {
        guard case .success(let rules) = parser.parse("remove text IMG_") else {
            XCTFail("Expected success"); return
        }
        XCTAssertEqual(rules, [.remove(text: "IMG_")])
    }

    func test_replace_unquoted() {
        guard case .success(let rules) = parser.parse("replace foo with bar") else {
            XCTFail("Expected success"); return
        }
        XCTAssertEqual(rules, [.replace(old: "foo", new: "bar")])
    }

    func test_replace_quoted() {
        guard case .success(let rules) = parser.parse("replace \" \" with \"_\"") else {
            XCTFail("Expected success"); return
        }
        XCTAssertEqual(rules, [.replace(old: " ", new: "_")])
    }

    func test_replaceAllWith() {
        guard case .success(let rules) = parser.parse("replace all with photo") else {
            XCTFail("Expected success"); return
        }
        XCTAssertEqual(rules, [.renameAll(base: "photo")])
    }

    func test_replaceAllWithWithoutValueReturnsIncompleteFailure() {
        guard case .failure(let message) = parser.parse("replace all with") else {
            XCTFail("Expected failure"); return
        }
        XCTAssertEqual(message, L10n.string("parser.incompleteCommand"))
    }

    func test_renameTo() {
        guard case .success(let rules) = parser.parse("rename to photo") else {
            XCTFail("Expected success"); return
        }
        XCTAssertEqual(rules, [.renameAll(base: "photo")])
    }

    func test_add_prefix() {
        guard case .success(let rules) = parser.parse("add prefix 2024_") else {
            XCTFail("Expected success"); return
        }
        XCTAssertEqual(rules, [.addPrefix(text: "2024_")])
    }

    func test_add_suffix() {
        guard case .success(let rules) = parser.parse("add suffix _final") else {
            XCTFail("Expected success"); return
        }
        XCTAssertEqual(rules, [.addSuffix(text: "_final")])
    }

    func test_add_custom_defaults_to_suffix() {
        guard case .success(let rules) = parser.parse("add columbus") else {
            XCTFail("Expected success"); return
        }
        XCTAssertEqual(rules, [.addSuffix(text: "columbus")])
    }

    func test_add_text_alias_defaults_to_suffix() {
        guard case .success(let rules) = parser.parse("add text photo") else {
            XCTFail("Expected success"); return
        }
        XCTAssertEqual(rules, [.addSuffix(text: "photo")])
    }

    func test_add_text_alias_supportsPrefix() {
        guard case .success(let rules) = parser.parse("add text photo prefix") else {
            XCTFail("Expected success"); return
        }
        XCTAssertEqual(rules, [.addPrefix(text: "photo")])
    }

    func test_add_custom_prefix() {
        guard case .success(let rules) = parser.parse("add columbus prefix") else {
            XCTFail("Expected success"); return
        }
        XCTAssertEqual(rules, [.addPrefix(text: "columbus")])
    }

    func test_add_custom_suffix() {
        guard case .success(let rules) = parser.parse("add columbus suffix") else {
            XCTFail("Expected success"); return
        }
        XCTAssertEqual(rules, [.addSuffix(text: "columbus")])
    }

    func test_add_index() {
        guard case .success(let rules) = parser.parse("add index") else {
            XCTFail("Expected success"); return
        }
        XCTAssertEqual(rules, [.addIndex(startingAt: 1, digits: 2)])
    }

    func test_add_index_prefix() {
        guard case .success(let rules) = parser.parse("add index prefix") else {
            XCTFail("Expected success"); return
        }
        XCTAssertEqual(rules, [.addIndex(startingAt: 1, digits: 2, placement: .prefix)])
    }

    func test_add_date() {
        guard case .success(let rules) = parser.parse("add date") else {
            XCTFail("Expected success"); return
        }
        XCTAssertEqual(rules, [.addDate(format: "yyyy-MM-dd")])
    }

    func test_add_date_prefix() {
        guard case .success(let rules) = parser.parse("add date prefix") else {
            XCTFail("Expected success"); return
        }
        XCTAssertEqual(rules, [.addDate(format: "yyyy-MM-dd", placement: .prefix)])
    }

    func test_clean_filename() {
        guard case .success(let rules) = parser.parse("clean filename") else {
            XCTFail("Expected success"); return
        }
        XCTAssertEqual(rules, [.cleanFilename])
    }

    func test_clean_text() {
        guard case .success(let rules) = parser.parse("clean hli") else {
            XCTFail("Expected success"); return
        }
        XCTAssertEqual(rules, [.cleanText(text: "hli")])
    }

    func test_clean_text_alias() {
        guard case .success(let rules) = parser.parse("clean text hli") else {
            XCTFail("Expected success"); return
        }
        XCTAssertEqual(rules, [.cleanText(text: "hli")])
    }

    func test_combination_remove_and_add_index() {
        guard case .success(let rules) = parser.parse("remove IMG_ and add index") else {
            XCTFail("Expected success"); return
        }
        XCTAssertEqual(rules, [.remove(text: "IMG_"), .addIndex(startingAt: 1, digits: 2)])
    }

    func test_combination_acceptsUppercaseAnd() {
        guard case .success(let rules) = parser.parse("add index prefix AND clean hli") else {
            XCTFail("Expected success"); return
        }
        XCTAssertEqual(rules, [
            .addIndex(startingAt: 1, digits: 2, placement: .prefix),
            .cleanText(text: "hli"),
        ])
    }

    func test_combination_acceptsJQLStyleSeparators() {
        guard case .success(let rules) = parser.parse("clean hli, lowercase; add date suffix && add index prefix") else {
            XCTFail("Expected success"); return
        }
        XCTAssertEqual(rules, [
            .cleanText(text: "hli"),
            .lowercase,
            .addDate(format: "yyyy-MM-dd", placement: .suffix),
            .addIndex(startingAt: 1, digits: 2, placement: .prefix),
        ])
    }

    func test_combination_doesNotSplitInsideQuotes() {
        guard case .success(let rules) = parser.parse("replace \"rock and roll\" with \"pop\" AND lowercase") else {
            XCTFail("Expected success"); return
        }
        XCTAssertEqual(rules, [
            .replace(old: "rock and roll", new: "pop"),
            .lowercase,
        ])
    }

    func test_trailingConnectorReturnsFailure() {
        guard case .failure = parser.parse("add index prefix AND ") else {
            XCTFail("Expected failure"); return
        }
    }

    func test_combination_replace_and_lowercase() {
        guard case .success(let rules) = parser.parse("replace \" \" with \"_\" and lowercase") else {
            XCTFail("Expected success"); return
        }
        XCTAssertEqual(rules, [.replace(old: " ", new: "_"), .lowercase])
    }

    func test_unknown_command_returns_failure() {
        guard case .failure = parser.parse("delete everything") else {
            XCTFail("Expected failure"); return
        }
    }
}

// MARK: - CommandSuggestion Tests

final class CommandSuggestionTests: XCTestCase {

    func test_matches_add_returns_add_commands() {
        let suggestions = CommandSuggestion.matches(for: "add")
        XCTAssertEqual(suggestions.map(\.completion), [
            "add text  prefix",
            "add text  suffix",
            "add prefix ",
            "add suffix ",
            "add date prefix",
            "add date suffix",
            "add index prefix",
            "add index suffix",
        ])
    }

    func test_applying_replaces_current_segment() {
        let suggestion = CommandSuggestion.all.first { $0.label == "index suffix" }!
        let result = CommandSuggestion.applying(suggestion, to: "remove IMG_ and add")
        XCTAssertEqual(result, "remove IMG_ and add index suffix")
    }

    func test_cursorOffsetForAddTextSuffixPointsBeforePlacement() {
        let suggestion = CommandSuggestion.all.first { $0.label == "add text suffix" }!
        let result = CommandSuggestion.applying(suggestion, to: "")
        let cursorOffset = CommandSuggestion.cursorOffset(afterApplying: suggestion, to: "")

        XCTAssertEqual(result, "add text  suffix")
        XCTAssertEqual(cursorOffset, "add text ".count)
    }

    func test_cursorOffsetAfterConnectorIncludesPreviousSegment() {
        let suggestion = CommandSuggestion.all.first { $0.label == "add text suffix" }!
        let input = "clean filename AND add tex"
        let result = CommandSuggestion.applying(suggestion, to: input)
        let cursorOffset = CommandSuggestion.cursorOffset(afterApplying: suggestion, to: input)

        XCTAssertEqual(result, "clean filename AND add text  suffix")
        XCTAssertEqual(cursorOffset, "clean filename AND add text ".count)
    }

    func test_applying_replaces_currentSegmentAfterUppercaseAnd() {
        let suggestion = CommandSuggestion.all.first { $0.label == "clean filename" }!
        let result = CommandSuggestion.applying(suggestion, to: "add index prefix AND cle")
        XCTAssertEqual(result, "add index prefix AND clean filename")
    }

    func test_matchesAfterTrailingAndShowsBaseCommands() {
        let suggestions = CommandSuggestion.matches(for: "add index prefix AND ")
        XCTAssertEqual(suggestions.prefix(3).map(\.completion), [
            "remove text ",
            "replace \"\" with \"\"",
            "replace all with ",
        ])
    }

    func test_addTextShowsPrefixAndSuffixSuggestions() {
        let suggestions = CommandSuggestion.matches(for: "add tex")
        XCTAssertEqual(suggestions.map(\.completion), [
            "add text  prefix",
            "add text  suffix",
        ])
    }

    func test_applying_empty_input_uses_completion() {
        let suggestion = CommandSuggestion.all.first { $0.label == "clean filename" }!
        XCTAssertEqual(CommandSuggestion.applying(suggestion, to: ""), "clean filename")
    }

    func test_removeTextSuggestion() {
        let suggestions = CommandSuggestion.matches(for: "remove tex")
        XCTAssertEqual(suggestions.map(\.completion), ["remove text "])
    }

    func test_cleanShowsFilenameAndTextSuggestions() {
        let suggestions = CommandSuggestion.matches(for: "clean")
        XCTAssertEqual(suggestions.map(\.completion), [
            "clean filename",
            "clean text ",
        ])
    }

    func test_replaceAllSuggestion() {
        let suggestions = CommandSuggestion.matches(for: "replace all")
        XCTAssertEqual(suggestions.map(\.completion), ["replace all with "])
    }

    func test_renameToSuggestion() {
        let suggestions = CommandSuggestion.matches(for: "rename")
        XCTAssertEqual(suggestions.map(\.completion), ["rename to "])
    }

    func test_custom_add_returns_prefixAndSuffixSuggestions() {
        let suggestions = CommandSuggestion.matches(for: "add columbus")
        XCTAssertEqual(suggestions.map(\.completion), [
            "add text columbus prefix",
            "add text columbus suffix",
        ])
    }

    func test_addIndexSuggestionsWinOverCustomText() {
        let suggestions = CommandSuggestion.matches(for: "add text photo AND add i")
        XCTAssertEqual(suggestions.map(\.completion), [
            "add index prefix",
            "add index suffix",
        ])
    }

    func test_customAddTextAliasReturnsPlacementSuggestions() {
        let suggestions = CommandSuggestion.matches(for: "add text photo")
        XCTAssertEqual(suggestions.map(\.completion), [
            "add text photo prefix",
            "add text photo suffix",
        ])
    }
}

// MARK: - RenameEngine Tests

final class RenameEngineTests: XCTestCase {

    let engine = RenameEngine()

    private func makeItems(_ stems: [String]) -> [RenameItem] {
        stems.map { stem in
            // Create a temp URL with a .jpg extension for testing
            let url = URL(fileURLWithPath: "/tmp/\(stem).jpg")
            return RenameItem(url: url)
        }
    }

    func test_lowercase() {
        let items = makeItems(["Hello_World", "FooBAR"])
        let result = engine.apply(rules: [.lowercase], to: items)
        XCTAssertEqual(result, ["hello_world", "foobar"])
    }

    func test_uppercase() {
        let items = makeItems(["hello", "world"])
        let result = engine.apply(rules: [.uppercase], to: items)
        XCTAssertEqual(result, ["HELLO", "WORLD"])
    }

    func test_remove() {
        let items = makeItems(["IMG_001", "IMG_002"])
        let result = engine.apply(rules: [.remove(text: "IMG_")], to: items)
        XCTAssertEqual(result, ["001", "002"])
    }

    func test_remove_is_case_insensitive() {
        let items = makeItems(["Clipwell-1_2_0"])
        let result = engine.apply(rules: [.remove(text: "clip")], to: items)
        XCTAssertEqual(result, ["well-1_2_0"])
    }

    func test_replace() {
        let items = makeItems(["hello world", "foo bar"])
        let result = engine.apply(rules: [.replace(old: " ", new: "_")], to: items)
        XCTAssertEqual(result, ["hello_world", "foo_bar"])
    }

    func test_replace_is_case_insensitive() {
        let items = makeItems(["Clipwell"])
        let result = engine.apply(rules: [.replace(old: "clip", new: "name")], to: items)
        XCTAssertEqual(result, ["namewell"])
    }

    func test_renameAll_addsRunningNumbers() {
        let items = makeItems(["IMG_001", "DSC_002", "scan"])
        let result = engine.apply(rules: [.renameAll(base: "photo")], to: items)
        XCTAssertEqual(result, ["photo_01", "photo_02", "photo_03"])
    }

    func test_addPrefix() {
        let items = makeItems(["photo", "video"])
        let result = engine.apply(rules: [.addPrefix(text: "2024_")], to: items)
        XCTAssertEqual(result, ["2024_photo", "2024_video"])
    }

    func test_addSuffix() {
        let items = makeItems(["report", "draft"])
        let result = engine.apply(rules: [.addSuffix(text: "_final")], to: items)
        XCTAssertEqual(result, ["report_final", "draft_final"])
    }

    func test_addPrefix_isIdempotent() {
        let items = makeItems(["2024_photo"])
        let result = engine.apply(rules: [.addPrefix(text: "2024_")], to: items)
        XCTAssertEqual(result, ["2024_photo"])
    }

    func test_addSuffix_isIdempotent() {
        let items = makeItems(["report_final"])
        let result = engine.apply(rules: [.addSuffix(text: "_final")], to: items)
        XCTAssertEqual(result, ["report_final"])
    }

    func test_addIndex() {
        let items = makeItems(["a", "b", "c"])
        let result = engine.apply(rules: [.addIndex(startingAt: 1, digits: 2)], to: items)
        XCTAssertEqual(result, ["a_01", "b_02", "c_03"])
    }

    func test_addIndexSuffix_isIdempotent() {
        let items = makeItems(["a_01", "b_02", "c_03"])
        let result = engine.apply(rules: [.addIndex(startingAt: 1, digits: 2)], to: items)
        XCTAssertEqual(result, ["a_01", "b_02", "c_03"])
    }

    func test_addIndexPrefix() {
        let items = makeItems(["a", "b", "c"])
        let result = engine.apply(rules: [.addIndex(startingAt: 1, digits: 2, placement: .prefix)], to: items)
        XCTAssertEqual(result, ["01_a", "02_b", "03_c"])
    }

    func test_addIndexPrefix_isIdempotent() {
        let items = makeItems(["01_a", "02_b", "03_c"])
        let result = engine.apply(rules: [.addIndex(startingAt: 1, digits: 2, placement: .prefix)], to: items)
        XCTAssertEqual(result, ["01_a", "02_b", "03_c"])
    }

    func test_addIndex_10Plus() {
        let items = makeItems(Array(repeating: "x", count: 12))
        let result = engine.apply(rules: [.addIndex(startingAt: 1, digits: 2)], to: items)
        XCTAssertEqual(result.last, "x_12")
    }

    func test_addDatePrefix() {
        let items = makeItems(["report"])
        let result = engine.apply(rules: [.addDate(format: "yyyy-MM-dd", placement: .prefix)], to: items)
        XCTAssertTrue(result[0].hasSuffix("_report"))
    }

    func test_addDateSuffix_isIdempotent() {
        let first = engine.apply(rules: [.addDate(format: "yyyy-MM-dd")], to: makeItems(["report"]))
        let second = engine.apply(rules: [.addDate(format: "yyyy-MM-dd")], to: makeItems(first))
        XCTAssertEqual(second, first)
    }

    func test_addDatePrefix_isIdempotent() {
        let first = engine.apply(rules: [.addDate(format: "yyyy-MM-dd", placement: .prefix)], to: makeItems(["report"]))
        let second = engine.apply(rules: [.addDate(format: "yyyy-MM-dd", placement: .prefix)], to: makeItems(first))
        XCTAssertEqual(second, first)
    }

    func test_cleanFilename_replaces_spaces() {
        let items = makeItems(["hello   world"])
        let result = engine.apply(rules: [.cleanFilename], to: items)
        XCTAssertEqual(result, ["hello_world"])
    }

    func test_cleanFilename_collapses_underscores() {
        let items = makeItems(["foo___bar"])
        let result = engine.apply(rules: [.cleanFilename], to: items)
        XCTAssertEqual(result, ["foo_bar"])
    }

    func test_cleanFilename_trims_underscores() {
        let items = makeItems(["_hello_"])
        let result = engine.apply(rules: [.cleanFilename], to: items)
        XCTAssertEqual(result, ["hello"])
    }

    func test_cleanText_removesCharactersCaseInsensitive() {
        let items = makeItems(["go_hiluliumkojno", "go_HLI_report"])
        let result = engine.apply(rules: [.cleanText(text: "hli")], to: items)
        XCTAssertEqual(result, ["go_uumkojno", "go__report"])
    }

    func test_combination_remove_and_addIndex() {
        let items = makeItems(["IMG_photo", "IMG_sunset"])
        let result = engine.apply(rules: [.remove(text: "IMG_"), .addIndex(startingAt: 1, digits: 2)], to: items)
        XCTAssertEqual(result, ["photo_01", "sunset_02"])
    }

    func test_combination_replace_and_lowercase() {
        let items = makeItems(["Hello World", "Foo BAR"])
        let result = engine.apply(rules: [.replace(old: " ", new: "_"), .lowercase], to: items)
        XCTAssertEqual(result, ["hello_world", "foo_bar"])
    }

    func test_extension_preserved_in_item() {
        let url = URL(fileURLWithPath: "/tmp/photo.jpeg")
        let item = RenameItem(url: url)
        XCTAssertEqual(item.originalStem, "photo")
        XCTAssertEqual(item.fileExtension, ".jpeg")
        XCTAssertEqual(item.originalFilename, "photo.jpeg")
    }

    func test_no_extension_item() {
        let url = URL(fileURLWithPath: "/tmp/Makefile")
        let item = RenameItem(url: url)
        XCTAssertEqual(item.originalStem, "Makefile")
        XCTAssertEqual(item.fileExtension, "")
    }

    func test_hidden_file_item() {
        let url = URL(fileURLWithPath: "/tmp/.gitignore")
        let item = RenameItem(url: url)
        XCTAssertEqual(item.originalStem, ".gitignore")
        XCTAssertEqual(item.fileExtension, "")
    }
}

// MARK: - RenameValidator Tests

final class RenameValidatorTests: XCTestCase {

    let validator = RenameValidator()

    private func makeItem(stem: String, preview: String?, ext: String = ".txt") -> RenameItem {
        var item = RenameItem(url: URL(fileURLWithPath: "/tmp/\(stem)\(ext)"))
        item.previewStem = preview
        return item
    }

    func test_empty_preview_stem_flagged() {
        let item = makeItem(stem: "hello", preview: "")
        let errors = validator.validate([item])
        XCTAssertTrue(errors[0].contains(.emptyName))
    }

    func test_duplicate_targets_flagged() {
        let a = makeItem(stem: "a", preview: "same")
        let b = makeItem(stem: "b", preview: "same")
        let errors = validator.validate([a, b])
        XCTAssertTrue(errors[0].contains(.duplicateTarget(conflictingWith: "same.txt")))
        XCTAssertTrue(errors[1].contains(.duplicateTarget(conflictingWith: "same.txt")))
    }

    func test_invalid_slash_character_flagged() {
        let item = makeItem(stem: "hello", preview: "he/llo")
        let errors = validator.validate([item])
        XCTAssertTrue(errors[0].contains(.invalidCharacters(characters: "/")))
    }

    func test_valid_item_has_no_errors() {
        let item = makeItem(stem: "hello", preview: "world")
        let errors = validator.validate([item])
        XCTAssertTrue(errors[0].isEmpty)
    }

    func test_caseOnlyRenameDoesNotCountAsExistingTarget() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("NamewellValidator-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let url = directory.appendingPathComponent("macOS02.txt")
        try Data("test".utf8).write(to: url)

        var item = RenameItem(url: url)
        item.previewStem = "macos02"

        let errors = validator.validate([item])
        XCTAssertTrue(errors[0].isEmpty)
    }
}

// MARK: - FileLoadingService Tests

final class FileLoadingServiceTests: XCTestCase {

    let service = FileLoadingService()

    func test_hiddenSystemFilesAreSkipped() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("NamewellLoading-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        try Data("system".utf8).write(to: directory.appendingPathComponent(".DS_Store"))
        try Data("visible".utf8).write(to: directory.appendingPathComponent("photo.jpg"))

        let items = try service.loadItems(from: directory)

        XCTAssertEqual(items.map(\.originalFilename), ["photo.jpg"])
    }
}

// MARK: - FileRenameService Tests

final class FileRenameServiceTests: XCTestCase {

    let service = FileRenameService()

    func test_caseOnlyRenameLowercaseSucceeds() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("NamewellRename-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let originalURL = directory.appendingPathComponent("macOS02.txt")
        try Data("test".utf8).write(to: originalURL)

        var item = RenameItem(url: originalURL)
        item.previewStem = "macos02"

        let operation = try service.performRename(items: [item], commandDescription: "lowercase")
        let renamedNames = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        XCTAssertTrue(renamedNames.contains("macos02.txt"))

        try service.undo(operation: operation)
        let restoredNames = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        XCTAssertTrue(restoredNames.contains("macOS02.txt"))

        try service.redo(operation: operation)
        let repeatedNames = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        XCTAssertTrue(repeatedNames.contains("macos02.txt"))
    }
}

// MARK: - RenameViewModel Tests

@MainActor
final class RenameViewModelTests: XCTestCase {

    func test_refreshAfterRenamePreservesUndoStack() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("NamewellViewModel-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let originalURL = directory.appendingPathComponent("old.txt")
        let renamedURL = directory.appendingPathComponent("new.txt")
        try Data("test".utf8).write(to: renamedURL)

        let viewModel = RenameViewModel()
        viewModel.loadFolder(url: directory)
        viewModel.undoService.push(
            RenameOperation(
                renames: [(from: originalURL, to: renamedURL)],
                commandDescription: "test"
            )
        )

        viewModel.loadFolder(url: directory, preservingUndo: true)

        XCTAssertTrue(viewModel.undoService.canUndo)
    }

    func test_loadingDifferentFolderClearsUndoStack() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("NamewellViewModel-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let originalURL = directory.appendingPathComponent("old.txt")
        let renamedURL = directory.appendingPathComponent("new.txt")
        try Data("test".utf8).write(to: renamedURL)

        let viewModel = RenameViewModel()
        viewModel.loadFolder(url: directory)
        viewModel.undoService.push(
            RenameOperation(
                renames: [(from: originalURL, to: renamedURL)],
                commandDescription: "test"
            )
        )

        viewModel.loadFolder(url: directory)

        XCTAssertFalse(viewModel.undoService.canUndo)
    }

    func test_undoClearsActivePreviewAndReloadsRestoredName() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("NamewellViewModel-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let originalURL = directory.appendingPathComponent("old.txt")
        let renamedURL = directory.appendingPathComponent("new.txt")
        try Data("test".utf8).write(to: renamedURL)

        let viewModel = RenameViewModel()
        viewModel.loadFolder(url: directory)
        viewModel.commandText = "replace old with new"
        viewModel.items[0].previewStem = "new"
        viewModel.undoService.push(
            RenameOperation(
                renames: [(from: originalURL, to: renamedURL)],
                commandDescription: "replace old with new"
            )
        )

        viewModel.undoLastRename()

        XCTAssertEqual(viewModel.commandText, "")
        XCTAssertEqual(viewModel.items.map(\.originalFilename), ["old.txt"])
        XCTAssertFalse(viewModel.items.contains(where: \.willChange))
        XCTAssertFalse(viewModel.undoService.canUndo)
        XCTAssertTrue(viewModel.undoService.canRedo)
        XCTAssertTrue(FileManager.default.fileExists(atPath: originalURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: renamedURL.path))
    }

    func test_redoRepeatsUndoneRenameAndClearsPreview() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("NamewellViewModel-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let originalURL = directory.appendingPathComponent("old.txt")
        let renamedURL = directory.appendingPathComponent("new.txt")
        try Data("test".utf8).write(to: renamedURL)

        let viewModel = RenameViewModel()
        viewModel.loadFolder(url: directory)
        viewModel.commandText = "replace old with new"
        viewModel.undoService.push(
            RenameOperation(
                renames: [(from: originalURL, to: renamedURL)],
                commandDescription: "replace old with new"
            )
        )
        viewModel.undoLastRename()

        viewModel.commandText = "replace old with new"
        viewModel.redoLastRename()

        XCTAssertEqual(viewModel.commandText, "")
        XCTAssertEqual(viewModel.items.map(\.originalFilename), ["new.txt"])
        XCTAssertFalse(viewModel.items.contains(where: \.willChange))
        XCTAssertTrue(viewModel.undoService.canUndo)
        XCTAssertFalse(viewModel.undoService.canRedo)
        XCTAssertFalse(FileManager.default.fileExists(atPath: originalURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: renamedURL.path))
    }
}
