import SwiftUI
import Zip
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
                                                UIPasteboard.general.string = self.tokensText
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
                                                self.isPlainTextActivityPresented = true
                                        }) {
                                                HStack {
                                                        Text("Export all Key URIs as plain ") +
                                                                Text("text").font(.system(.body, design: .monospaced)).foregroundColor(.primary)
                                                        Spacer()
                                                }
                                                .padding()
                                                .fillBackground()
                                                .padding()
                                        }.sheet(isPresented: self.$isPlainTextActivityPresented) {
                                                ActivityView(activityItems: [self.tokensText]) {
                                                        self.isPlainTextActivityPresented = false
                                                }
                                        }
                                        
                                        Button(action: {
                                                self.isTXTFileActivityPresented = true
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
                                        }.sheet(isPresented: self.$isTXTFileActivityPresented) {
                                                ActivityView(activityItems: [self.exportTXTFile()]) {
                                                        self.isTXTFileActivityPresented = false
                                                }
                                        }
                                        
                                        Button(action: {
                                                self.isZIPFileActivityPresented = true
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
                                        }.sheet(isPresented: self.$isZIPFileActivityPresented) {
                                                ActivityView(activityItems: [self.exportZIPFile()]) {
                                                        self.isZIPFileActivityPresented = false
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
        
        var tokensText: String {
                tokens.reduce("") { $0 + $1.uri + "\n" }
        }
        
        private func exportTXTFile() -> URL {
                let temporaryDirectoryUrl: URL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                
                
                let temporaryFileName: String = "2FAAuth-accounts-" + currentDate + ".txt"
                let temporaryFileUrl: URL = temporaryDirectoryUrl.appendingPathComponent(temporaryFileName, isDirectory: false)
                do {
                        try tokensText.write(to: temporaryFileUrl, atomically: false, encoding: .utf8)
                } catch {
                        debugPrint(error.localizedDescription)
                }
                return temporaryFileUrl
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
        
        private func exportZIPFile() -> URL {
                
                let temporaryDirectoryUrl: URL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                
                var imageURLs: [URL] = []
                _ = tokens.map { (token) -> Void in
                        let url: URL? = saveQRCodeImages(for: token)
                        if url != nil {
                                imageURLs.append(url!)
                        }
                }
                
                let temporaryZipFileName: String = "2FAAuth-accounts-" + currentDate + ".zip"
                let temporaryZipFileUrl: URL = temporaryDirectoryUrl.appendingPathComponent(temporaryZipFileName, isDirectory: false)
                do {
                        try Zip.zipFiles(paths: imageURLs, zipFilePath: temporaryZipFileUrl, password: nil) {_ in }
                } catch {
                        debugPrint(error.localizedDescription)
                }
                return temporaryZipFileUrl
        }
        
        private func saveQRCodeImages(for token: Token) -> URL? {
                var imageFileUrl: URL?
                let temporaryDirectoryUrl: URL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                let imageObject = generateQRCodeImage(from: token)
                if imageObject.name.hasContent && imageObject.image != nil {
                        let imageUrl: URL = temporaryDirectoryUrl.appendingPathComponent(imageObject.name!, isDirectory: false)
                        do {
                                try imageObject.image?.pngData()?.write(to: imageUrl)
                                imageFileUrl = imageUrl
                        } catch {
                                debugPrint(error.localizedDescription)
                        }
                }
                return imageFileUrl
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
                
                if token.accountName.hasContent {
                        imageName.insert(contentsOf: "-", at: imageName.startIndex)
                        imageName.insert(contentsOf: token.accountName!, at: imageName.startIndex)
                }
                if token.issuer.hasContent {
                        imageName.insert(contentsOf: "-", at: imageName.startIndex)
                        imageName.insert(contentsOf: token.issuer!, at: imageName.startIndex)
                }
                return imageName
        }
}
