import SwiftUI

struct AboutView: View {
        
        @Binding var isPresented: Bool
        
        var body: some View {
                NavigationView {
                        ZStack {
                                GlobalBackgroundColor().ignoresSafeArea()
                                ScrollView {
                                        VersionLabel()
                                                .padding()
                                        
                                        LinkCardView(heading: "Source Code", message: "https://github.com/ososoio/authenticator")
                                                .padding()
                                        
                                        LinkCardView(heading: "Privacy Policy", message: "https://ososo.io/authenticator/privacy-policy")
                                                .padding()
                                }
                        }
                        .navigationTitle("About")
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
}

private struct VersionLabel: View {
        
        @State private var isBannerPresented: Bool = false
        
        private let version: String = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "__ERROR__"
        private let build: String = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "__ERROR__"
        private var versionString: String { version + " (" + build + ")" }
        
        var body: some View {
                HStack {
                        Text("Version")
                        Spacer()
                        Text(versionString)
                }
                .padding()
                .fillBackground()
                .onTapGesture {
                        UIPasteboard.general.string = versionString
                        isBannerPresented = true
                }
                .onLongPressGesture {
                        UIPasteboard.general.string = versionString
                        isBannerPresented = true
                }
                .banner(isPresented: $isBannerPresented)
        }
}
private struct LinkCardView: View {
        
        let heading: String
        let message: String
        
        @State private var isBannerPresented: Bool = false
        
        var body: some View {
                VStack {
                        HStack {
                                Text(heading).font(.headline)
                                Spacer()
                        }
                        HStack {
                                Text(message).font(.system(.footnote, design: .monospaced))
                                Spacer()
                        }.padding(.top, 4)
                }
                .padding()
                .fillBackground()
                .onTapGesture {
                        UIPasteboard.general.string = message
                        isBannerPresented = true
                }
                .onLongPressGesture {
                        UIPasteboard.general.string = message
                        isBannerPresented = true
                }
                .banner(isPresented: $isBannerPresented)
        }
}
