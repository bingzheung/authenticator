import SwiftUI

struct CodeCardView: View {

        let token: Token
        @Binding var totp: String
        @Binding var timeRemaining: Int

        @State private var isBannerPresented: Bool = false

        private let diameter: CGFloat = 24

        var body: some View {
                VStack(spacing: 4) {
                        HStack(spacing: 16) {
                                issuerImage.resizable().scaledToFit().frame(width: diameter, height: diameter)
                                Text(verbatim: token.displayIssuer).font(.headline)
                                Spacer()
                                Menu {
                                        Button {
                                                UIPasteboard.general.string = totp
                                                guard !isBannerPresented else { return }
                                                isBannerPresented = true
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                        isBannerPresented = false
                                                }
                                        } label: {
                                                Label("Copy Code", systemImage: "doc.on.doc")
                                        }
                                } label: {
                                        Image(systemName: "ellipsis.circle")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: diameter, height: diameter)
                                                .foregroundStyle(Color.primary)
                                                .padding(.leading, 8)
                                                .contentShape(Rectangle())
                                }
                        }
                        VStack(alignment: .leading, spacing: 4) {
                                Text(verbatim: formattedTotp).font(.largeTitle.monospacedDigit())
                                HStack {
                                        Text(verbatim: token.displayAccountName).font(.footnote)
                                        Spacer()
                                        ZStack {
                                                Circle().stroke(Color.primary.opacity(0.2), lineWidth: 2)
                                                Arc(startAngle: .degrees(-90), endAngle: .degrees(endAngle), clockwise: true).stroke(lineWidth: 2)
                                                Text(verbatim: timeRemaining.description).font(.footnote.monospacedDigit())
                                        }
                                        .frame(width: diameter, height: diameter)
                                }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                                UIPasteboard.general.string = totp
                                guard !isBannerPresented else { return }
                                isBannerPresented = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        isBannerPresented = false
                                }
                        }
                }
                .copiedBanner(isPresented: $isBannerPresented)
                .animation(.default, value: isBannerPresented)
        }

        private var formattedTotp: String {
                var code: String = totp
                switch code.count {
                case 6:
                        code.insert(" ", at: code.index(code.startIndex, offsetBy: 3))
                case 8:
                        code.insert(" ", at: code.index(code.startIndex, offsetBy: 4))
                default:
                        break
                }
                return code
        }

        private var issuerImage: Image {
                let imageName: String = {
                        let issuer: String = token.displayIssuer.lowercased()
                        switch issuer {
                        case "jetbrains account", "jetbrains+account":
                                return "jetbrains"
                        case "wordpress.com":
                                return "wordpress"
                        case "gab.com":
                                return "gab"
                        case "crowdin.com":
                                return "crowdin"
                        case "truthsocial.com":
                                return "truthsocial"
                        case "open collective":
                                return "opencollective"
                        default:
                                return issuer
                        }
                }()
                guard !(imageName.isEmpty) else { return Image(systemName: "person.circle") }
                guard let uiImage: UIImage = UIImage(named: imageName) else { return Image(systemName: "person.circle") }
                return Image(uiImage: uiImage)
        }

        private var endAngle: Double {
                return Double((30 - timeRemaining) * 12 - 89)
        }
}

private struct Arc: Shape {
        let startAngle: Angle
        let endAngle: Angle
        let clockwise: Bool
        func path(in rect: CGRect) -> Path {
                var path = Path()
                path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2.0, startAngle: startAngle, endAngle: endAngle, clockwise: clockwise)
                return path
        }
}
