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
                                VStack {
                                        Picker("Method", selection: $selection) {
                                                Text("By Key URI").tag(0)
                                                Text("By Secret Key").tag(1)
                                        }
                                        .pickerStyle(.segmented)
                                        .padding(.horizontal)
                                        ScrollView {
                                                if selection == 0 {
                                                        HStack {
                                                                Text(verbatim: "Key URI")
                                                                Spacer()
                                                        }
                                                        .padding(.horizontal)
                                                        TextField("otpauth://totp/...", text: $keyUri)
                                                                .keyboardType(.URL)
                                                                .disableAutocorrection(true)
                                                                .autocapitalization(.none)
                                                                .font(.footnote.monospaced())
                                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                                                .padding(.horizontal)
                                                } else {
                                                        HStack {
                                                                Text("Issuer")
                                                                Spacer()
                                                        }
                                                        .padding(.horizontal)
                                                        TextField("Service Provider (Optional)", text: $issuer)
                                                                .disableAutocorrection(true)
                                                                .autocapitalization(.words)
                                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                                                .padding(.horizontal)
                                                        HStack {
                                                                Text("Account Name")
                                                                Spacer()
                                                        }
                                                        .padding(.horizontal)
                                                        TextField("email@example.com (Optional)", text: $accountName)
                                                                .keyboardType(.emailAddress)
                                                                .disableAutocorrection(true)
                                                                .autocapitalization(.none)
                                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                                                .padding(.horizontal)

                                                        HStack {
                                                                Text("Secret Key")
                                                                Spacer()
                                                        }
                                                        .padding(.horizontal)
                                                        TextField("SECRET (Required)", text: $secretKey)
                                                                .keyboardType(.alphabet)
                                                                .disableAutocorrection(true)
                                                                .autocapitalization(.none)
                                                                .font(.callout.monospaced())
                                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                                                .padding(.horizontal)
                                                }
                                        }
                                }
                        }
                        .alert(isPresented: $isAlertPresented) {
                                Alert(title: Text("Error"), message: Text("Invalid Key"), dismissButton: .cancel(Text("OK")))
                        }
                        .navigationTitle("Add Account")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                        Button("Cancel", action: { isPresented = false })
                                }
                                ToolbarItem(placement: .confirmationAction) {
                                        Button("Add", action: handleAdding)
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
