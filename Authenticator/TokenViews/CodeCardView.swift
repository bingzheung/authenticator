import SwiftUI

struct CodeCardView: View {

        let token: Token
        @Binding var totp: String
        @Binding var timeRemaining: Int

        @State private var isBannerPresented: Bool = false

        var body: some View {
                VStack {
                        HStack {
                                issuerImage.resizable().scaledToFit().frame(width: 24, height: 24)
                                Spacer().frame(width: 16)
                                Text(token.displayIssuer).font(.headline)
                                Spacer(minLength: 16)
                                Menu {
                                        Button(action: {
                                                UIPasteboard.general.string = totp
                                                isBannerPresented = true
                                        }) {
                                                MenuLabel(text: "Copy code", image: "doc.on.doc")
                                        }
                                } label: {
                                        Image(systemName: "ellipsis.circle")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 24, height: 24)
                                                .foregroundColor(.primary)
                                                .padding(.leading, 8)
                                                .contentShape(Rectangle())
                                }
                        }
                        VStack(spacing: 8) {
                                HStack {
                                        Text(formattedTotp).font(.largeTitle)
                                        Spacer()
                                }
                                HStack {
                                        Text(token.displayAccountName).font(.footnote)
                                        Spacer()
                                        ZStack {
                                                Circle().stroke(Color.primary.opacity(0.2), lineWidth: 2)
                                                        .frame(width: 24, height: 24)
                                                Arc(startAngle: .degrees(-90), endAngle: .degrees(endAngle), clockwise: true)
                                                        .stroke(lineWidth: 2)
                                                        .frame(width: 24, height: 24)
                                                Text(timeRemaining.description).font(.footnote)
                                        }
                                }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                                UIPasteboard.general.string = totp
                                isBannerPresented = true
                        }
                }
                .padding()
                .fillBackground()
                .modifier(BannerModifier(isPresented: $isBannerPresented))
        }

        private var formattedTotp: String {
                var code: String = totp
                switch code.count {
                case 6:
                        code.insert(" ", at: code.index(code.startIndex, offsetBy: 3))
                case 8:
                        code.insert(" ", at: code.index(code.startIndex, offsetBy: 4))
                default: break
                }
                return code
        }

        private var issuerImage: Image {
                let imageName: String = token.displayIssuer.lowercased()
                guard !imageName.isEmpty else { return Image(systemName: "person.circle") }
                guard let uiImage: UIImage = UIImage(named: imageName) else { return Image(systemName: "person.circle") }
                return Image(uiImage: uiImage)
        }

        private var endAngle: Double { Double((30 - timeRemaining) * 12 - 89) }
}

private struct Arc: Shape {
        let startAngle: Angle
        let endAngle: Angle
        let clockwise: Bool
        func path(in rect: CGRect) -> Path {
                var path = Path()
                path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2, startAngle: startAngle, endAngle: endAngle, clockwise: clockwise)
                return path
        }
}

private struct BannerModifier: ViewModifier {

        @Binding var isPresented: Bool

        func body(content: Content) -> some View {
                ZStack {
                        content
                        if isPresented {
                                Text("Copied")
                                        .animation(.default)
                                        .transition(AnyTransition.move(edge: .top).combined(with: .opacity))
                                        .onAppear {
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                                        withAnimation {
                                                                isPresented = false
                                                        }
                                                }
                                        }
                        }
                }
        }
}
