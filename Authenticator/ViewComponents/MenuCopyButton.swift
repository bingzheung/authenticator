import SwiftUI

struct MenuCopyButton: View {
        let content: String
        var body: some View {
                Button(action: {
                        UIPasteboard.general.string = content
                }) {
                        Label("Copy", systemImage: "doc.on.doc")
                }
        }
}
