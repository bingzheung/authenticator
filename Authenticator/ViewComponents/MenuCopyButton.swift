import SwiftUI

struct MenuCopyButton: View {
        let content: String
        var body: some View {
                Button {
                        UIPasteboard.general.string = content
                } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                }
        }
}
