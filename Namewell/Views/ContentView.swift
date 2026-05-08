// MARK: - ContentView
import SwiftUI

struct ContentView: View {

    @StateObject private var viewModel = RenameViewModel()
    @AppStorage("settings.languageCode") private var languageCode = "system"

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(viewModel: viewModel)

            Divider()

            Group {
                if viewModel.hasItems {
                    CommandInputView(viewModel: viewModel)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)

                    Divider()

                    PreviewListView(viewModel: viewModel)

                    Divider()

                    StatusBarView(viewModel: viewModel)
                } else {
                    EmptyStateView(viewModel: viewModel)
                }
            }
            .id(languageCode)
        }
        .frame(minWidth: 700, minHeight: 500)
        .alert(
            L10n.string("alert.title", comment: ""),
            isPresented: $viewModel.showAlert,
            actions: {
                Button(L10n.string("alert.ok", comment: ""), role: .cancel) {}
            },
            message: {
                Text(viewModel.alertMessage ?? "")
            }
        )
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openFolderRequested)) { _ in
            viewModel.openFolder()
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        FileDropHandler.loadFirstDirectory(from: providers) { url in
            viewModel.loadFolder(url: url)
        }
    }
}
