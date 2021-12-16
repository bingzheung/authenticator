import SwiftUI

struct AboutView: View {

        @Binding var isPresented: Bool

        var body: some View {
                NavigationView {
                        List {
                                Section {
                                        HStack {
                                                Text("Version")
                                                Spacer()
                                                Text(verbatim: version)
                                        }
                                        .contextMenu {
                                                MenuCopyButton(content: version)
                                        }
                                }
                                Section {
                                        LinkCardView(heading: "Source Code", message: "https://github.com/ososoio/authenticator")
                                }
                                Section {
                                        LinkCardView(heading: "Privacy Policy", message: "https://ososo.io/authenticator/privacy")
                                }
                                Section {
                                        LinkCardView(heading: "Share this App", message: "https://apps.apple.com/app/id1511791282")
                                }
                        }
                        .navigationTitle("About")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                        Button("Back") {
                                                isPresented = false
                                        }
                                }
                        }
                }
        }

        private let version: String = {
                let versionString: String = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "_error"
                let buildString: String = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "_error"
                return versionString + " (" + buildString + ")"
        }()
}


// TODO: - Add copied banner

private struct LinkCardView: View {

        let heading: LocalizedStringKey
        let message: String

        var body: some View {
                VStack(spacing: 8) {
                        HStack {
                                Text(heading)
                                Spacer()
                        }
                        HStack {
                                Text(verbatim: message).font(.caption.monospaced())
                                Spacer()
                        }
                }
                #if targetEnvironment(macCatalyst)
                .textSelection(.enabled)
                #endif
                .contextMenu {
                        MenuCopyButton(content: message)
                }
        }
}
