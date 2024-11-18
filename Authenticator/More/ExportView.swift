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
                        List {
                                Section {
                                        Button {
                                                UIPasteboard.general.string = tokensText
                                        } label: {
                                                HStack(spacing: 12) {
                                                        Image(systemName: "doc.on.doc").foregroundStyle(Color.primary)
                                                        Text("Copy all Key URIs to Clipboard")
                                                        Spacer()
                                                }
                                        }
                                }
                                Section {
                                        Button {
                                                isPlainTextActivityPresented = true
                                        } label: {
                                                HStack(spacing: 12) {
                                                        Image(systemName: "text.alignleft").foregroundStyle(Color.primary)
                                                        Text("Export all Key URIs as plain text")
                                                        Spacer()
                                                }
                                        }
                                        .sheet(isPresented: $isPlainTextActivityPresented) {
                                                ActivityView(activityItems: [tokensText]) {
                                                        isPlainTextActivityPresented = false
                                                }
                                        }
                                }
                                Section {
                                        Button {
                                                isTXTFileActivityPresented = true
                                        } label: {
                                                HStack(spacing: 12) {
                                                        Image(systemName: "doc.text").foregroundStyle(Color.primary)
                                                        Text("Export all Key URIs as a \(Text(verbatim: ".txt").font(.footnote.monospaced()).foregroundColor(.primary)) file")
                                                        Spacer()
                                                }
                                        }
                                        .sheet(isPresented: $isTXTFileActivityPresented) {
                                                let url = txtFile()
                                                #if targetEnvironment(macCatalyst)
                                                DocumentExporter(url: url)
                                                #else
                                                ActivityView(activityItems: [url]) {
                                                        isTXTFileActivityPresented = false
                                                }
                                                #endif
                                        }
                                }
                                Section {
                                        Button {
                                                isZIPFileActivityPresented = true
                                        } label: {
                                                HStack(spacing: 12) {
                                                        Image(systemName: "doc.zipper").foregroundStyle(Color.primary)
                                                        Text("Export all Key URIs as QR Code images combined as a \(Text(verbatim: ".zip").font(.footnote.monospaced()).foregroundColor(.primary)) file")
                                                        Spacer()
                                                }
                                        }
                                        .sheet(isPresented: $isZIPFileActivityPresented) {
                                                let url: URL = zipFile()
                                                #if targetEnvironment(macCatalyst)
                                                DocumentExporter(url: url)
                                                #else
                                                ActivityView(activityItems: [url]) {
                                                        isZIPFileActivityPresented = false
                                                }
                                                #endif
                                        }
                                }
                        }
                        .navigationTitle("Export Accounts")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                        Button("Back") {
                                                isPresented = false
                                        }
                                }
                        }
                }
        }

        private var tokensText: String {
                return tokens.map(\.uri).joined(separator: "\n") + "\n"
        }

        private func txtFile() -> URL {
                let txtFileName: String = "2FA-" + Date.currentDateText + ".txt"
                let txtFileUrl: URL = URL.tmpDirectoryUrl.appendingPathComponent(txtFileName, isDirectory: false)
                try? tokensText.write(to: txtFileUrl, atomically: true, encoding: .utf8)
                return txtFileUrl
        }

        // https://recoursive.com/2021/02/25/create_zip_archive_using_only_foundation
        private func zipFile() -> URL {
                let imagesDirectoryName: String = "2FA-" + Date.currentDateText
                let imagesDirectoryUrl: URL = URL.tmpDirectoryUrl.appendingPathComponent(imagesDirectoryName, isDirectory: true)
                if FileManager.default.fileExists(atPath: imagesDirectoryUrl.path).negative {
                        try? FileManager.default.createDirectory(at: imagesDirectoryUrl, withIntermediateDirectories: false)
                }
                _ = tokens.map({ saveQRCodeImage(for: $0, parent: imagesDirectoryUrl) })
                let zipFileName: String = imagesDirectoryName + ".zip"
                let zipFileUrl: URL = URL.tmpDirectoryUrl.appendingPathComponent(zipFileName, isDirectory: false)
                let coordinator = NSFileCoordinator()
                var err: NSError?
                coordinator.coordinate(readingItemAt: imagesDirectoryUrl, options: .forUploading, error: &err) { url in
                        try? FileManager.default.moveItem(at: url, to: zipFileUrl)
                }
                return zipFileUrl
        }
        private func saveQRCodeImage(for token: Token, parent parentDirectoryUrl: URL) -> URL? {
                guard let image: UIImage = generateQRCodeImage(from: token) else { return nil }
                let name: String = imageName(for: token)
                let fileUrl: URL = parentDirectoryUrl.appendingPathComponent(name, isDirectory: false)
                do {
                        try image.pngData()?.write(to: fileUrl)
                } catch {
                        return nil
                }
                return fileUrl
        }
        private func generateQRCodeImage(from token: Token) -> UIImage? {
                let filter = CIFilter.qrCodeGenerator()
                let data: Data = Data(token.uri.utf8)
                filter.setValue(data, forKey: "inputMessage")
                filter.setValue("H", forKey: "inputCorrectionLevel")
                let transform: CGAffineTransform = CGAffineTransform(scaleX: 5, y: 5)
                guard let ciImage: CIImage = filter.outputImage?.transformed(by: transform) else { return nil }
                return UIImage(ciImage: ciImage)
        }
        private func imageName(for token: Token) -> String {
                var imageName: String = token.id + "-" + Date.currentDateText + ".png"
                imageName.insert("-", at: imageName.index(imageName.startIndex, offsetBy: token.secret.count))

                if let accountName: String = token.accountName, accountName.isNotEmpty {
                        let prefix: String = accountName + "-"
                        imageName.insert(contentsOf: prefix, at: imageName.startIndex)
                }
                if let issuer: String = token.issuer, issuer.isNotEmpty {
                        let prefix: String = issuer + "-"
                        imageName.insert(contentsOf: prefix, at: imageName.startIndex)
                }
                return imageName
        }
}
