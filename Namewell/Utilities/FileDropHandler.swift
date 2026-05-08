// MARK: - FileDropHandler
import Foundation

enum FileDropHandler {

    private static let fileURLTypeIdentifier = "public.file-url"

    static func loadFirstDirectory(
        from providers: [NSItemProvider],
        completion: @escaping @MainActor @Sendable (URL) -> Void
    ) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: fileURLTypeIdentifier, options: nil) { item, _ in
            guard let url = directoryURL(from: item) else { return }
            Task { @MainActor in
                completion(url)
            }
        }

        return true
    }

    private static func directoryURL(from item: NSSecureCoding?) -> URL? {
        guard let data = item as? Data,
              let url = URL(dataRepresentation: data, relativeTo: nil) else {
            return nil
        }

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return nil
        }

        return url
    }
}
