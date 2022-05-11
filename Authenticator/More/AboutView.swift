import SwiftUI

struct AboutView: View {

        @Binding var isPresented: Bool

        var body: some View {
                NavigationView {
                        List {
                                Section {
                                        VersionLabel()
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
                                ToolbarItem(placement: .cancellationAction) {
                                        Button("Back") {
                                                isPresented = false
                                        }
                                }
                        }
                }
        }
}


private struct VersionLabel: View {

        @State private var isBannerPresented: Bool = false

        var body: some View {
                HStack {
                        Text("Version")
                        Spacer()
                        Text(verbatim: version)
                                #if targetEnvironment(macCatalyst)
                                .textSelection(.enabled)
                                #endif
                }
                .padding(.vertical)
                .contextMenu {
                        MenuCopyButton(version)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                        UIPasteboard.general.string = version
                        guard !isBannerPresented else { return }
                        isBannerPresented = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                isBannerPresented = false
                        }
                }
                .copiedBanner(isPresented: $isBannerPresented)
                .animation(.default, value: isBannerPresented)
        }

        private let version: String = {
                let versionString: String = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "_error"
                let buildString: String = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "_error"
                return versionString + " (" + buildString + ")"
        }()
}


private struct LinkCardView: View {

        let heading: LocalizedStringKey
        let message: String

        @State private var isBannerPresented: Bool = false

        var body: some View {
                VStack(spacing: 16) {
                        HStack {
                                Text(heading)
                                Spacer()
                        }
                        HStack {
                                Text(verbatim: message).font(.footnote.monospaced()).lineLimit(1).minimumScaleFactor(0.5)
                                Spacer()
                        }
                        .padding(.bottom, 4)
                        #if targetEnvironment(macCatalyst)
                        .textSelection(.enabled)
                        #endif
                }
                .padding(.vertical, 8)
                .contextMenu {
                        MenuCopyButton(message)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                        UIPasteboard.general.string = message
                        guard !isBannerPresented else { return }
                        isBannerPresented = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                isBannerPresented = false
                        }
                }
                .copiedBanner(isPresented: $isBannerPresented)
                .animation(.default, value: isBannerPresented)
        }
}
