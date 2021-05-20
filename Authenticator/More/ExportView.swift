import SwiftUI
import CoreImage.CIFilterBuiltins

struct ExportView: View {

        @Binding var isPresented: Bool
        let tokens: [Token]

        @State private var isPlainTextActivityPresented: Bool = false
        @State private var isTXTFileActivityPresented: Bool = false
        @State private var isZIPFileActivityPresented: Bool = false

        var body: some View {
                NavigationView {
                        ZStack {
                                GlobalBackgroundColor().ignoresSafeArea()
                                ScrollView {
                                        Button(action: {
                                                UIPasteboard.general.string = tokensText
                                        }) {
                                                HStack {
                                                        Text("Copy all Key URIs to Clipboard")
                                                        Spacer()
                                                }
                                                .padding()
                                                .fillBackground()
                                                .padding()
                                        }

                                        Button(action: {
                                                isPlainTextActivityPresented = true
                                        }) {
                                                HStack {
                                                        Text("Export all Key URIs as plain ") +
                                                                Text("text").font(.system(.body, design: .monospaced)).foregroundColor(.primary)
                                                        Spacer()
                                                }
                                                .padding()
                                                .fillBackground()
                                                .padding()
                                        }
                                        .sheet(isPresented: $isPlainTextActivityPresented) {
                                                ActivityView(activityItems: [tokensText]) {
                                                        isPlainTextActivityPresented = false
                                                }
                                        }

                                        Button(action: {
                                                isTXTFileActivityPresented = true
                                        }) {
                                                HStack {
                                                        Text("Export all Key URIs as a ") +
                                                                Text(".txt").font(.system(.body, design: .monospaced)).foregroundColor(.primary) +
                                                                Text(" file")
                                                        Spacer()
                                                }
                                                .padding()
                                                .fillBackground()
                                                .padding()
                                        }
                                        .sheet(isPresented: $isTXTFileActivityPresented) {
                                                ActivityView(activityItems: [txtFile()]) {
                                                        isTXTFileActivityPresented = false
                                                }
                                        }

                                        Button(action: {
                                                isZIPFileActivityPresented = true
                                        }) {
                                                HStack {
                                                        Text("Export all Key URIs as QR Code images combined as a ") +
                                                                Text(".zip").font(.system(.body, design: .monospaced)).foregroundColor(.primary) +
                                                                Text(" file")
                                                        Spacer()
                                                }
                                                .padding()
                                                .fillBackground()
                                                .padding()
                                        }
                                        .sheet(isPresented: $isZIPFileActivityPresented) {
                                                ActivityView(activityItems: [zipFile()]) {
                                                        isZIPFileActivityPresented = false
                                                }
                                        }
                                }
                        }
                        .navigationTitle("Export accounts")
                        .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                        Button(action: {
                                                isPresented  = false
                                        }) {
                                                Text("Back")
                                        }
                                }
                        }
                }
        }

        private var currentDate: String {
                let now: Date = Date()
                let calendar: Calendar = Calendar.current
                let month: Int = calendar.component(.month, from: now)
                let day: Int = calendar.component(.day, from: now)
                let hour: Int = calendar.component(.hour, from: now)
                let minute: Int = calendar.component(.minute, from: now)
                let second: Int = calendar.component(.second, from: now)
                return String(format: "%02d%02d%02d%02d%02d", month, day, hour, minute, second)
        }

        private var tokensText: String {
                return tokens.reduce("") { $0 + $1.uri + "\n" }
        }

        private func txtFile() -> URL {
                let temporaryDirectoryUrl: URL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                let txtFileName: String = "2FAAuth-accounts-" + currentDate + ".txt"
                let txtFileUrl: URL = temporaryDirectoryUrl.appendingPathComponent(txtFileName, isDirectory: false)
                do {
                        try tokensText.write(to: txtFileUrl, atomically: true, encoding: .utf8)
                } catch {
                        debugLog(error.localizedDescription)
                }
                return txtFileUrl
        }

        // https://recoursive.com/2021/02/25/create_zip_archive_using_only_foundation
        private func zipFile() -> URL {
                let temporaryDirectoryUrl: URL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                let imagesDirectoryName: String = "2FAAuth-accounts-" + currentDate
                let imagesDirectoryUrl: URL = temporaryDirectoryUrl.appendingPathComponent(imagesDirectoryName, isDirectory: true)
                if !(FileManager.default.fileExists(atPath: imagesDirectoryUrl.path)) {
                        try? FileManager.default.createDirectory(at: imagesDirectoryUrl, withIntermediateDirectories: false)
                }
                _ = tokens.map { oneToken in
                        _ = saveQRCodeImage(for: oneToken, parent: imagesDirectoryUrl)
                }
                let zipFileUrl: URL = temporaryDirectoryUrl.appendingPathComponent("\(imagesDirectoryName).zip", isDirectory: false)
                let coordinator = NSFileCoordinator()
                var err: NSError?
                coordinator.coordinate(readingItemAt: imagesDirectoryUrl, options: .forUploading, error: &err) { url in
                        try? FileManager.default.moveItem(at: url, to: zipFileUrl)
                }
                return zipFileUrl
        }
        private func saveQRCodeImage(for token: Token, parent parentDirectoryUrl: URL) -> URL? {
                let imageObject = generateQRCodeImage(from: token)
                guard let name: String = imageObject.name, !name.isEmpty, let image: UIImage = imageObject.image else { return nil }
                let fileUrl: URL = parentDirectoryUrl.appendingPathComponent(name, isDirectory: false)
                do {
                        try image.pngData()?.write(to: fileUrl)
                } catch {
                        debugLog(error.localizedDescription)
                }
                return fileUrl
        }
        private func generateQRCodeImage(from token: Token) -> (name: String?, image: UIImage?) {
                let filter = CIFilter.qrCodeGenerator()
                let data: Data = Data(token.uri.utf8)
                filter.setValue(data, forKey: "inputMessage")
                filter.setValue("H", forKey: "inputCorrectionLevel")
                let transform: CGAffineTransform = CGAffineTransform(scaleX: 5, y: 5)
                guard let ciImage: CIImage = filter.outputImage?.transformed(by: transform) else { return (nil, nil) }
                let uiImage: UIImage = UIImage(ciImage: ciImage)
                return (imageName(for: token), uiImage)
        }
        private func imageName(for token: Token) -> String {
                var imageName: String = token.id + "-" + currentDate + ".png"
                imageName.insert("-", at: imageName.index(imageName.startIndex, offsetBy: token.secret.count))

                if let accountName: String = token.accountName, !accountName.isEmpty {
                        let prefix: String = accountName + "-"
                        imageName.insert(contentsOf: prefix, at: imageName.startIndex)
                }
                if let issuer: String = token.issuer, !issuer.isEmpty {
                        let prefix: String = issuer + "-"
                        imageName.insert(contentsOf: prefix, at: imageName.startIndex)
                }
                return imageName
        }

        private func debugLog(_ text: String) {
                #if DEBUG
                print(text)
                #endif
        }
}
