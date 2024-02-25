import SwiftUI

private struct CopiedBannerModifier: ViewModifier {
        @Binding var isPresented: Bool
        func body(content: Content) -> some View {
                ZStack {
                        content
                        if isPresented {
                                Text("Copied")
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 40)
                                        .background(.ultraThinMaterial)
                                        .clipShape(.capsule)
                                        .transition(.move(edge: .top).combined(with: .opacity))
                        }
                }
        }
}

extension View {
        func copiedBanner(isPresented: Binding<Bool>) -> some View {
                self.modifier(CopiedBannerModifier(isPresented: isPresented))
        }
}
