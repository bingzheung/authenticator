import SwiftUI

struct AboutView: View {

        @Binding var isPresented: Bool
        @State private var isActivityViewPresented: Bool = false

        var body: some View {
                NavigationView {
                        List {
                                Section {
                                        HStack {
                                                Text("Version")
                                                Spacer()
                                                Text(verbatim: versionString)
                                        }
                                        .contextMenu {
                                                MenuCopyButton(content: versionString)
                                        }
                                }
                                Section {
                                        LinkCardView(heading: "Source Code", message: "https://github.com/ososoio/authenticator")
                                }
                                Section {
                                        LinkCardView(heading: "Privacy Policy", message: "https://ososo.io/authenticator/privacy")
                                }
                                Section {
                                        HStack {
                                                Text("Share this App")
                                                Spacer()
                                                Image(systemName: "square.and.arrow.up")
                                        }
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                                isActivityViewPresented = true
                                        }
                                        .onLongPressGesture {
                                                isActivityViewPresented = true
                                        }
                                }
                        }
                        .navigationTitle("About")
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
                        .sheet(isPresented: $isActivityViewPresented) {
                                ActivityView(activityItems: [URL(string: "https://apps.apple.com/app/id1511791282")!], completion: { isActivityViewPresented = false })
                        }
                }
        }

        private let versionString: String = {
                let version: String = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "_error"
                let build: String = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "_error"
                return version + " (" + build + ")"
        }()
}

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
                .contextMenu {
                        MenuCopyButton(content: message)
                }
        }
}
