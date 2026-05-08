// MARK: - RenameRule

/// A single atomic transformation that can be applied to a filename stem.
/// Combinable: an array of RenameRules forms a pipeline.
enum RenameRule: Equatable {
    case remove(text: String)
    case replace(old: String, new: String)
    case renameAll(base: String)
    case addPrefix(text: String)
    case addSuffix(text: String)
    case addIndex(startingAt: Int, digits: Int, placement: RenamePlacement = .suffix)
    case addDate(format: String, placement: RenamePlacement = .suffix)
    case lowercase
    case uppercase
    case cleanFilename
    case cleanText(text: String)
}

enum RenamePlacement: Equatable {
    case prefix
    case suffix
}
