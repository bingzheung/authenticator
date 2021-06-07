import SwiftUI

struct AboutView: View {

        @Binding var isPresented: Bool
        @State private var isActivityViewPresented: Bool = false

        var body: some View {
                NavigationView {
                        ZStack {
                                GlobalBackgroundColor().ignoresSafeArea()
                                ScrollView {
                                        VersionLabel()

                                        LinkCardView(heading: "Source Code", message: "https://github.com/ososoio/authenticator")
                                                .padding()
                                        
                                        LinkCardView(heading: "Privacy Policy", message: "https://ososo.io/authenticator/privacy")
                                                .padding()

                                        HStack {
                                                Text("Share this App").font(.headline)
                                                Spacer()
                                                Image(systemName: "square.and.arrow.up")
                                        }
                                        .padding()
                                        .fillBackground()
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                                isActivityViewPresented = true
                                        }
                                        .onLongPressGesture {
                                                isActivityViewPresented = true
                                        }
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
                        .sheet(isPresented: $isActivityViewPresented) {
                                ActivityView(activityItems: [URL(string: "https://apps.apple.com/app/id1511791282")!], completion: { isActivityViewPresented = false })
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
                        Text("Version").font(.headline)
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
                                Text(NSLocalizedString(heading, comment: "")).font(.headline)
                                Spacer()
                        }
                        HStack {
                                Text(NSLocalizedString(message, comment: "")).font(.system(.footnote, design: .monospaced))
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
