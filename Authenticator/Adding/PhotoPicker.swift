import SwiftUI
import PhotosUI

struct PhotoPicker: UIViewControllerRepresentable {

        let completion: (String) -> Void

        func makeUIViewController(context: Context) -> PHPickerViewController {
                var configuration = PHPickerConfiguration()
                configuration.filter = .images
                configuration.selectionLimit = 1
                configuration.preferredAssetRepresentationMode = .current
                let controller = PHPickerViewController(configuration: configuration)
                controller.delegate = context.coordinator
                return controller
        }
        func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

        func makeCoordinator() -> Coordinator {
                Coordinator(self)
        }
        final class Coordinator: PHPickerViewControllerDelegate {
                private let parent: PhotoPicker
                init(_ parent: PhotoPicker) {
                        self.parent = parent
                }
                func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
                        picker.dismiss(animated: true) {
                                self.handle(results)
                        }
                }
                private func handle(_ results: [PHPickerResult]) {
                        guard let result: PHPickerResult = results.first else { return }
                        guard result.itemProvider.canLoadObject(ofClass: UIImage.self) else { return }
                        result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                                guard let image = object as? UIImage else { return }
                                guard let detector: CIDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]) else { return }
                                guard let ciImage: CIImage = CIImage(image: image) else { return }
                                var qrCodeText: String = .empty
                                let features: [CIFeature] = detector.features(in: ciImage)
                                _ = features.map {
                                        let newText: String = ($0 as? CIQRCodeFeature)?.messageString ?? .empty
                                        qrCodeText += newText
                                }
                                guard !qrCodeText.isEmpty else { return }
                                self.parent.completion(qrCodeText)
                        }
                }
        }
}
