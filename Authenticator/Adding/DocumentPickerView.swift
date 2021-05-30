import SwiftUI

struct DocumentPickerView: UIViewControllerRepresentable {
                
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
                
                let parent: DocumentPickerView
                
                init(_ parent: DocumentPickerView) {
                        self.parent = parent
                }
                
                private var feedbackGenerator: UINotificationFeedbackGenerator? = UINotificationFeedbackGenerator()
                func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
                        defer {
                                parent.isPresented = false
                                feedbackGenerator = nil
                        }
                        guard let url: URL = urls.first else { return }
                        feedbackGenerator?.notificationOccurred(.success)
                        parent.completion(url)
                }
        }
}
