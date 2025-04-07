import SwiftUI

struct MenuCopyButton: View {

        init(_ text: String) {
                self.text = text
        }

        private let text: String

        var body: some View {
                Button("Copy", systemImage: "doc.on.doc") {
                        UIPasteboard.general.string = text
                }
        }
}
