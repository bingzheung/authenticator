import SwiftUI

struct CodeCard: View {
        
        let token: Token
        @Binding var totp: String
        @Binding var timeRemaining: Int
        
        @Binding var isActionSheetPresented: Bool
        @Binding var actionSheetState: Int
        @Binding var tokenID: String
        
        @State private var isBannerPresented: Bool = false
        
        var body: some View {
                VStack {
                        HStack {
                                issuerImage.resizable().scaledToFit().frame(width: 20, height: 20)
                                Spacer().frame(width: 16)
                                Text(token.displayIssuer).font(.headline)
                                Spacer(minLength: 16)
                                Image(systemName: "ellipsis.circle")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .padding(.trailing, 4)
                                        .onTapGesture {
                                                tokenID = token.id
                                                actionSheetState = 3
                                                isActionSheetPresented = true
                                        }
                        }
                        
                        HStack {
                                Text(formattedTotp).font(.largeTitle)
                                Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                                UIPasteboard.general.string = totp
                                isBannerPresented = true
                        }
                        .onLongPressGesture {
                                UIPasteboard.general.string = totp
                                isBannerPresented = true
                        }
                        .banner(isPresented: $isBannerPresented)
                        
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
                .padding()
                .fillBackground()
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
                guard let _ = UIImage(named: imageName) else { return Image(systemName: "person.circle") }
                return Image(imageName)
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
