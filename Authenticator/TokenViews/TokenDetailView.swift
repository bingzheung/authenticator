import SwiftUI
import CoreImage.CIFilterBuiltins

struct TokenDetailView: View {

        @Binding var isPresented: Bool
        let token: Token

        @State private var isImageActivityViewPresented: Bool = false

        var body: some View {
                NavigationView {
                        ZStack {
                                GlobalBackgroundColor().ignoresSafeArea()
                                ScrollView {
                                        MessageCardView(heading: "Issuer", message: token.displayIssuer, messageFont: .body)
                                                .padding()

                                        MessageCardView(heading: "Account Name", message: token.displayAccountName, messageFont: .body)
                                                .padding(.horizontal)

                                        MessageCardView(heading: "Secret Key",
                                                        message: token.secret,
                                                        messageFont: .system(.footnote, design: .monospaced))
                                                .padding()

                                        MessageCardView(heading: "Key URI",
                                                        message: token.uri,
                                                        messageFont: .system(.footnote, design: .monospaced))
                                                .padding(.horizontal)
                                                .padding(.bottom, 30)

                                        if let uiImage = qrCodeImage {
                                                HStack {
                                                        Spacer()
                                                        Text("Key URI as QR Code")
                                                        Spacer()
                                                }
                                                .padding(.horizontal)
                                                
                                                Image(uiImage: uiImage)
                                                        .resizable()
                                                        .scaledToFit()
                                                        .padding()
                                                        .fillBackground()
                                                        .padding()
                                                        .frame(idealWidth: 250, maxWidth: 400, idealHeight: 250, maxHeight: 400)
                                                        .onLongPressGesture {
                                                                imageUrl = nil
                                                                imageUrl = saveQRCodeImage(uiImage)
                                                                if imageUrl != nil {
                                                                        isImageActivityViewPresented = true
                                                                }
                                                        }
                                                        .sheet(isPresented: $isImageActivityViewPresented) {
                                                                let url = imageUrl!
                                                                #if targetEnvironment(macCatalyst)
                                                                DocumentExporter(url: url)
                                                                #else
                                                                ActivityView(activityItems: [url]) {
                                                                        imageUrl = nil
                                                                        isImageActivityViewPresented = false
                                                                }
                                                                #endif
                                                        }
                                        }
                                        Spacer().frame(height: 50)
                                }
                        }
                        .navigationTitle("Account Detail")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                        Button(action: {
                                                isPresented = false
                                        }) {
                                                Text("Back")
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
        private func saveQRCodeImage(_ image: UIImage) -> URL? {
                let temporaryDirectoryUrl: URL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                let fileUrl: URL = temporaryDirectoryUrl.appendingPathComponent(imageName, isDirectory: false)
                do {
                        try image.pngData()?.write(to: fileUrl)
                } catch {
                        return nil
                }
                return fileUrl
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

private var imageUrl: URL? = nil


private struct MessageCardView: View {

        let heading: String
        let message: String
        let messageFont: Font

        var body: some View {
                VStack {
                        HStack {
                                Text(heading).font(.headline)
                                Spacer()
                        }
                        HStack {
                                Text(message).font(messageFont)
                                Spacer()
                        }
                        .padding(.top, 4)
                }
                .padding()
                .fillBackground()
                .contextMenu(menuItems: {
                        MenuCopyButton(content: message)
                })
        }
}
