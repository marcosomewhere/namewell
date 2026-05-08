// MARK: - NamewellApp
import AppKit
import SwiftUI

@main
struct NamewellApp: App {

    @NSApplicationDelegateAdaptor(NamewellAppDelegate.self) private var appDelegate
    @AppStorage("settings.languageCode") private var languageCode = "system"

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            // Remove default New Window shortcut to avoid confusion
            CommandGroup(replacing: .newItem) {}

            // File menu additions
            CommandGroup(after: .newItem) {
                Button(L10n.string("action.openFolder", comment: "")) {
                    NotificationCenter.default.post(name: .openFolderRequested, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
                .id(languageCode)
            }
        }
    }
}

private final class NamewellAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        applyDockIcon()
    }

    func applicationWillTerminate(_ notification: Notification) {
        applyDockIcon()
    }

    @MainActor
    private func applyDockIcon() {
        if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: iconURL) {
            NSApplication.shared.applicationIconImage = icon
        }
    }
}
