import SwiftUI

struct AboutView: View {

        @Binding var isPresented: Bool

        var body: some View {
                NavigationView {
                        ZStack {
                                GlobalBackgroundColor().ignoresSafeArea()
                                ScrollView {
                                        VersionLabel()
                                        LinkCardView(heading: "Source Code", message: "https://github.com/ososoio/authenticator")
                                                .padding(.horizontal)
                                        
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

        private let versionString: String = {
                let version: String = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "_error"
                let build: String = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "_error"
                return version + " (" + build + ")"
        }()

        var body: some View {
                HStack {
                        Text("Version")
                        Spacer()
                        Text(versionString)
                }
                .padding()
                .fillBackground()
                .contextMenu(menuItems: {
                        MenuCopyButton(content: versionString)
                })
                .padding()
        }
}
private struct LinkCardView: View {

        let heading: String
        let message: String

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
                .contextMenu(menuItems: {
                        MenuCopyButton(content: message)
                })
        }
}

struct MenuCopyButton: View {

        let content: String

        var body: some View {
                Button(action: {
                        UIPasteboard.general.string = content
                }) {
                        HStack {
                                Text("Copy")
                                Spacer()
                                Image(systemName: "doc.on.doc")
                        }
                }
        }
}
