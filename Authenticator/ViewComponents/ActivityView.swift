import SwiftUI

struct ActivityView: UIViewControllerRepresentable {

        let activityItems: [Any]
        let completion: () -> Void

        private func completionHandler(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, activityError: Error?) {
                completion()
        }

        func makeUIViewController(context: Context) -> UIActivityViewController {
                let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
                controller.completionWithItemsHandler = completionHandler
                return controller
        }

        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
