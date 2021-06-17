import SwiftUI

struct ManualEntryView: View {
        
        @Binding var isPresented: Bool
        let completion: (Token) -> Void
        
        @State private var selection: Int = 0
        @State private var keyUri: String = ""
        @State private var issuer: String = ""
        @State private var accountName: String = ""
        @State private var secretKey: String = ""
        
        @State private var isAlertPresented: Bool = false
        
        var body: some View {
                NavigationView {
                        ZStack {
                                GlobalBackgroundColor().ignoresSafeArea()
                                ScrollView {
                                        Picker("Method", selection: $selection) {
                                                Text("By Key URI").tag(0)
                                                Text("By Secret Key").tag(1)
                                        }
                                        .pickerStyle(SegmentedPickerStyle())
                                        .padding()
                                        
                                        if selection == 0 {
                                                VStack {
                                                        HStack {
                                                                Text("Key URI")
                                                                Spacer()
                                                        }
                                                        TextField("otpauth://totp/...", text: $keyUri)
                                                                .keyboardType(.URL)
                                                                .autocapitalization(.none)
                                                                .disableAutocorrection(true)
                                                                .font(.system(.footnote, design: .monospaced))
                                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                                }.padding()
                                        } else {
                                                VStack {
                                                        VStack {
                                                                HStack {
                                                                        Text("Issuer")
                                                                        Spacer()
                                                                }
                                                                EnhancedTextField(placeholder: NSLocalizedString("Service Provider (Optional)", comment: ""),
                                                                                  text: $issuer,
                                                                                  autocorrection: .no,
                                                                                  autocapitalization: .words)
                                                                        .padding(8)
                                                                        .fillBackground()
                                                        }
                                                        .padding()
                                                        VStack {
                                                                HStack {
                                                                        Text("Account Name")
                                                                        Spacer()
                                                                }
                                                                EnhancedTextField(placeholder: NSLocalizedString("email@example.com (Optional)", comment: ""),
                                                                                  text: $accountName,
                                                                                  keyboardType: .emailAddress,
                                                                                  autocorrection: .no,
                                                                                  autocapitalization: UITextAutocapitalizationType.none)
                                                                        .padding(8)
                                                                        .fillBackground()
                                                        }
                                                        .padding(.horizontal)
                                                        VStack {
                                                                HStack {
                                                                        Text("Secret Key")
                                                                        Spacer()
                                                                }
                                                                EnhancedTextField(placeholder: NSLocalizedString("SECRET (Required)", comment: ""),
                                                                                  text: $secretKey,
                                                                                  font: .monospacedSystemFont(ofSize: 17, weight: .regular),
                                                                                  keyboardType: .alphabet,
                                                                                  autocorrection: .no,
                                                                                  autocapitalization: UITextAutocapitalizationType.none)
                                                                        .padding(8)
                                                                        .fillBackground()
                                                        }
                                                        .padding()
                                                }
                                        }
                                }
                        }.alert(isPresented: $isAlertPresented) {
                                Alert(title: Text("Error"), message: Text("Invalid Key"), dismissButton: .cancel(Text("OK")))
                        }
                        .navigationTitle("Add account")
                        .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                        Button(action: {
                                                isPresented = false
                                        }) {
                                                Text("Cancel")
                                        }
                                }
                                ToolbarItem(placement: .navigationBarTrailing) {
                                        Button(action: handleAdding) { Text("Add") }
                                }
                        }
                }
        }
        
        private func handleAdding() {
                var feedbackGenerator: UINotificationFeedbackGenerator? = UINotificationFeedbackGenerator()
                if let token: Token = self.newToken {
                        feedbackGenerator?.notificationOccurred(.success)
                        feedbackGenerator = nil
                        completion(token)
                        isPresented = false
                } else {
                        feedbackGenerator?.notificationOccurred(.error)
                        feedbackGenerator = nil
                        isAlertPresented = true
                }
        }
        
        private var newToken: Token? {
                if selection == 0 {
                        guard !keyUri.isEmpty else { return nil }
                        guard let token: Token = Token(uri: keyUri.trimming()) else { return nil }
                        return token
                } else {
                        guard !secretKey.isEmpty else { return nil }
                        guard let token: Token = Token(issuerPrefix: issuer.trimming(),
                                                       accountName: accountName.trimming(),
                                                       secret: secretKey.trimming(),
                                                       issuer: issuer.trimming()) else { return nil }
                        return token
                }
        }
}
