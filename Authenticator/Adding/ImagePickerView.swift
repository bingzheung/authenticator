import SwiftUI

struct ImagePickerView: UIViewControllerRepresentable {
        
        @Binding var isPresented: Bool
        let completion: (String?) -> Void
        
        func makeUIViewController(context: Context) -> UIImagePickerController {
                let picker = UIImagePickerController()
                picker.delegate = context.coordinator
                return picker
        }
        
        func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
        
        func makeCoordinator() -> Coordinator {
                Coordinator(self)
        }
        
        final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
                var parent: ImagePickerView
                init(_ parent: ImagePickerView) {
                        self.parent = parent
                }
                private var feedbackGenerator: UINotificationFeedbackGenerator? = UINotificationFeedbackGenerator()
                func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
                        defer {
                                parent.isPresented = false
                                feedbackGenerator = nil
                        }
                        feedbackGenerator?.prepare()
                        guard let pickedImage = info[.originalImage] as? UIImage else { return }
                        guard let detector: CIDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]) else { return }
                        guard let ciImage: CIImage = CIImage(image: pickedImage) else { return }
                        var qrCodeText: String = ""
                        let features: [CIFeature] = detector.features(in: ciImage)
                        _ = features.map {
                                qrCodeText += ($0 as? CIQRCodeFeature)?.messageString ?? ""
                        }
                        guard !qrCodeText.isEmpty else { return }
                        feedbackGenerator?.notificationOccurred(.success)
                        parent.completion(qrCodeText)
                }
        }
}
