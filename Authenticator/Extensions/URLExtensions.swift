import UIKit
import UniformTypeIdentifiers

extension URL {
        func readText() -> String? {
                guard let typeID: String = try? self.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier else { return nil }
                guard let type = UTType(typeID) else { return nil }
                if type.conforms(to: .text) {
                        guard let content: String = try? String(contentsOf: self) else { return nil }
                        guard !content.isEmpty else { return nil }
                        return content
                } else if type.conforms(to: .image) {
                        guard let pickedImage: UIImage = UIImage(contentsOfFile: self.path) else { return nil }
                        guard let detector: CIDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]) else { return nil }
                        guard let ciImage: CIImage = CIImage(image: pickedImage) else { return nil }
                        var qrCodeText: String = ""
                        let features: [CIFeature] = detector.features(in: ciImage)
                        _ = features.map {
                                qrCodeText += ($0 as? CIQRCodeFeature)?.messageString ?? ""
                        }
                        guard !qrCodeText.isEmpty else { return nil }
                        return qrCodeText
                } else {
                        return nil
                }
        }
}
