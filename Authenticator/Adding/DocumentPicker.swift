// Use .fileImporter() instead

/*
import SwiftUI

struct DocumentPicker: UIViewControllerRepresentable {

        @Binding var isPresented: Bool
        let completion: (URL?) -> Void

        func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
                let viewController = UIDocumentPickerViewController(forOpeningContentTypes: [.text, .image], asCopy: false)
                viewController.delegate = context.coordinator
                return viewController
        }

        func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

        func makeCoordinator() -> Coordinator {
                Coordinator(self)
        }

        final class Coordinator: NSObject, UIDocumentPickerDelegate {

                private let parent: DocumentPicker

                init(_ parent: DocumentPicker) {
                        self.parent = parent
                }

                private var feedbackGenerator: UINotificationFeedbackGenerator? = UINotificationFeedbackGenerator()
                func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
                        defer {
                                parent.isPresented = false
                                feedbackGenerator = nil
                        }
                        guard let url: URL = urls.first else { return }

                        guard url.startAccessingSecurityScopedResource() else { return }
                        let temporaryDirectoryUrl: URL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                        let cacheUrl: URL = temporaryDirectoryUrl.appendingPathComponent(Date.currentDateText + url.lastPathComponent, isDirectory: false)
                        try? FileManager.default.copyItem(at: url, to: cacheUrl)
                        url.stopAccessingSecurityScopedResource()

                        guard FileManager.default.fileExists(atPath: cacheUrl.path) else { return }
                        feedbackGenerator?.notificationOccurred(.success)
                        parent.completion(cacheUrl)
                }
        }
}
*/
