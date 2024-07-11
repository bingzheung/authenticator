import SwiftUI
import CoreImage.CIFilterBuiltins

struct TokenDetailView: View {

        @Binding var isPresented: Bool
        let token: Token

        @State private var isImageActivityViewPresented: Bool = false

        var body: some View {
                NavigationView {
                        List {
                                Section {
                                        Text(verbatim: "Issuer").font(.headline)
                                        Text(verbatim: token.displayIssuer).textSelection(.enabled)
                                        #if targetEnvironment(macCatalyst)
                                                .contextMenu {
                                                        MenuCopyButton(token.displayIssuer)
                                                }
                                        #endif
                                }
                                Section {
                                        Text(verbatim: "Account Name").font(.headline)
                                        Text(verbatim: token.displayAccountName).textSelection(.enabled)
                                        #if targetEnvironment(macCatalyst)
                                                .contextMenu {
                                                        MenuCopyButton(token.displayAccountName)
                                                }
                                        #endif
                                }
                                Section {
                                        Text(verbatim: "Secret Key").font(.headline)
                                        Text(verbatim: token.secret).font(.footnote.monospaced()).textSelection(.enabled)
                                        #if targetEnvironment(macCatalyst)
                                                .contextMenu {
                                                        MenuCopyButton(token.secret)
                                                }
                                        #endif
                                }
                                Section {
                                        Text(verbatim: "Key URI").font(.headline)
                                        Text(verbatim: token.uri).font(.footnote.monospaced()).textSelection(.enabled)
                                        #if targetEnvironment(macCatalyst)
                                                .contextMenu {
                                                        MenuCopyButton(token.uri)
                                                }
                                        #endif
                                }
                                if let uiImage = qrCodeImage {
                                        Section {
                                                Image(uiImage: uiImage)
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 180, height: 180)
                                                        .onLongPressGesture {
                                                                isImageActivityViewPresented = true
                                                        }
                                        } header: {
                                                Text(verbatim: "Key URI as QR Code").textCase(nil)
                                        }
                                        .listRowBackground(Color.clear)
                                }
                        }
                        .sheet(isPresented: $isImageActivityViewPresented) {
                                if let url = saveQRCodeImage() {
                                        #if targetEnvironment(macCatalyst)
                                        DocumentExporter(url: url)
                                        #else
                                        ActivityView(activityItems: [url]) {
                                                isImageActivityViewPresented = false
                                        }
                                        #endif
                                }
                        }
                        .navigationTitle("NavigationTitle.AccountDetail")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                        Button("Back", role: .cancel) {
                                                isPresented = false
                                        }
                                }
                        }
                }
        }

        private var qrCodeImage: UIImage? {
                let context: CIContext = CIContext()
                let filter = CIFilter.qrCodeGenerator()
                let data: Data = Data(token.uri.utf8)
                filter.setValue(data, forKey: "inputMessage")
                filter.setValue("H", forKey: "inputCorrectionLevel")
                let transform: CGAffineTransform = CGAffineTransform(scaleX: 5, y: 5)
                guard let ciImage: CIImage = filter.outputImage?.transformed(by: transform) else { return nil }
                guard let cgImage: CGImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
                return UIImage(cgImage: cgImage)
        }
        private func saveQRCodeImage() -> URL? {
                let context: CIContext = CIContext()
                let filter = CIFilter.qrCodeGenerator()
                let data: Data = Data(token.uri.utf8)
                filter.setValue(data, forKey: "inputMessage")
                filter.setValue("H", forKey: "inputCorrectionLevel")
                let transform: CGAffineTransform = CGAffineTransform(scaleX: 5, y: 5)
                guard let ciImage: CIImage = filter.outputImage?.transformed(by: transform) else { return nil }
                guard let cgImage: CGImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
                let image = UIImage(cgImage: cgImage)
                let url: URL = URL.tmpDirectoryUrl.appendingPathComponent(imageName, isDirectory: false)
                do {
                        try image.pngData()?.write(to: url)
                } catch {
                        return nil
                }
                return url
        }
        private var imageName: String {
                var name: String = Date.currentDateText + ".png"
                if let accountName: String = token.accountName, !accountName.isEmpty {
                        let prefix: String = accountName + "-"
                        name.insert(contentsOf: prefix, at: name.startIndex)
                }
                if let issuer: String = token.issuer, !issuer.isEmpty {
                        let prefix: String = issuer + "-"
                        name.insert(contentsOf: prefix, at: name.startIndex)
                }
                return name
        }
}
