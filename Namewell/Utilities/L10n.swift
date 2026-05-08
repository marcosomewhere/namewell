// MARK: - L10n
import Foundation

enum L10n {
    private static let languageKey = "settings.languageCode"
    private static let systemLanguageCode = "system"
    private static let supportedLanguageCodes = ["en", "de", "fr", "pl"]
    private static var resourceBundles: [Bundle] {
        #if SWIFT_PACKAGE
        return [Bundle.main, Bundle.module, Bundle(for: L10nBundleToken.self)]
        #else
        return [Bundle.main, Bundle(for: L10nBundleToken.self)]
        #endif
    }

    static func string(_ key: String, comment: String = "") -> String {
        let selectedLanguage = UserDefaults.standard.string(forKey: languageKey) ?? systemLanguageCode
        let languageCode = resolvedLanguageCode(for: selectedLanguage)

        guard let bundle = localizedBundle(for: languageCode) else {
            return Bundle.main.localizedString(forKey: key, value: nil, table: nil)
        }

        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    static func resolvedLanguageCode(for selectedLanguage: String) -> String {
        guard selectedLanguage == systemLanguageCode else {
            let code = normalizedLanguageCode(selectedLanguage)
            return supportedLanguageCodes.contains(code) ? code : "en"
        }

        let globalLanguages = UserDefaults.standard
            .persistentDomain(forName: UserDefaults.globalDomain)?["AppleLanguages"] as? [String] ?? []
        let candidates = globalLanguages + [
            Locale.autoupdatingCurrent.identifier,
            Locale.current.identifier,
        ]

        for candidate in candidates {
            let code = normalizedLanguageCode(candidate)
            if supportedLanguageCodes.contains(code) {
                return code
            }
        }

        return "en"
    }

    private static func normalizedLanguageCode(_ identifier: String) -> String {
        identifier
            .replacingOccurrences(of: "_", with: "-")
            .split(separator: "-")
            .first
            .map(String.init)?
            .lowercased() ?? identifier.lowercased()
    }

    private static func localizedBundle(for languageCode: String) -> Bundle? {
        for resourceBundle in candidateResourceBundles() {
            if let path = resourceBundle.path(forResource: languageCode, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                return bundle
            }
        }

        return nil
    }

    private static func candidateResourceBundles() -> [Bundle] {
        let loadedBundles = Bundle.allBundles + Bundle.allFrameworks
        let siblingBundleURL = Bundle.main.bundleURL
            .deletingLastPathComponent()
            .appendingPathComponent("Namewell_Namewell.bundle")
        let siblingBundle = Bundle(url: siblingBundleURL)

        return (resourceBundles + loadedBundles + [siblingBundle].compactMap { $0 })
            .reduce(into: []) { bundles, bundle in
                guard !bundles.contains(where: { $0.bundleURL == bundle.bundleURL }) else { return }
                bundles.append(bundle)
            }
    }
}

private final class L10nBundleToken {}
