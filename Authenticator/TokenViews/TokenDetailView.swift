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
                                                        messageFont: Font.system(.footnote, design: .monospaced))
                                                .padding()
                                        
                                        MessageCardView(heading: "Key URI",
                                                        message: token.uri,
                                                        messageFont: Font.system(.footnote, design: .monospaced))
                                                .padding(.horizontal)
                                                .padding(.bottom, 30)
                                        
                                        if let cgImage: CGImage = qrCodeImage {
                                                HStack {
                                                        Spacer()
                                                        Text("Key URI as QR Code")
                                                        Spacer()
                                                }
                                                .padding(.horizontal)
                                                
                                                Image(cgImage, scale: 1, label: Text("QR Code"))
                                                        .resizable()
                                                        .scaledToFit()
                                                        .padding()
                                                        .fillBackground()
                                                        .padding(.horizontal, 50)
                                                        .padding(.bottom, 50)
                                                        .onTapGesture {
                                                                isImageActivityViewPresented = true
                                                        }
                                                        .onLongPressGesture {
                                                                isImageActivityViewPresented = true
                                                        }
                                                        .sheet(isPresented: $isImageActivityViewPresented) {
                                                                let image: UIImage = UIImage(cgImage: cgImage)
                                                                ActivityView(activityItems: [image]) {
                                                                        isImageActivityViewPresented = false
                                                                }
                                                        }
                                        }
                                }
                        }
                        .navigationTitle("Account detail")
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
        
        private var qrCodeImage: CGImage? {
                let context: CIContext = CIContext()
                let filter = CIFilter.qrCodeGenerator()
                let data: Data = Data(token.uri.utf8)
                filter.setValue(data, forKey: "inputMessage")
                filter.setValue("H", forKey: "inputCorrectionLevel")
                let transform: CGAffineTransform = CGAffineTransform(scaleX: 5, y: 5)
                guard let ciImage: CIImage = filter.outputImage?.transformed(by: transform) else { return nil }
                return context.createCGImage(ciImage, from: ciImage.extent)
        }
}

private struct MessageCardView: View {
        
        let heading: String
        let message: String
        let messageFont: Font
        
        @State private var isBannerPresented: Bool = false
        
        var body: some View {
                VStack {
                        HStack {
                                Text(heading).font(.headline)
                                Spacer()
                        }
                        HStack {
                                Text(message).font(messageFont)
                                Spacer()
                        }.padding(.top, 4)
                }
                .padding()
                .fillBackground()
                .onTapGesture {
                        UIPasteboard.general.string = message
                        isBannerPresented = true
                }.onLongPressGesture {
                        UIPasteboard.general.string = message
                        isBannerPresented = true
                }
                .banner(isPresented: $isBannerPresented)
        }
}
