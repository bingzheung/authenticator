import SwiftUI

struct MenuCopyButton: View {

        init(_ text: String) {
                self.text = text
        }

        private let text: String

        var body: some View {
                Button {
                        UIPasteboard.general.string = text
                } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                }
        }
}
