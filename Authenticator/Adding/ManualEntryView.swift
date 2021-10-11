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
                        List {
                                Section {
                                        Picker("Method", selection: $selection) {
                                                Text("By Key URI").tag(0)
                                                Text("By Secret Key").tag(1)
                                        }
                                        .pickerStyle(.segmented)
                                }
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)

                                if selection == 0 {
                                        Section {
                                                TextField("otpauth://totp/...", text: $keyUri)
                                                        .keyboardType(.URL)
                                                        .disableAutocorrection(true)
                                                        .autocapitalization(.none)
                                                        .font(.footnote.monospaced())
                                        } header: {
                                                Text(verbatim: "Key URI")
                                        }
                                } else {
                                        Section {
                                                TextField("Service Provider (Optional)", text: $issuer)
                                                        .disableAutocorrection(true)
                                                        .autocapitalization(.words)
                                        } header: {
                                                Text(verbatim: "Issuer")
                                        }

                                        Section {
                                                TextField("email@example.com (Optional)", text: $accountName)
                                                        .keyboardType(.emailAddress)
                                                        .disableAutocorrection(true)
                                                        .autocapitalization(.none)
                                        } header: {
                                                Text(verbatim: "Account Name")
                                        }

                                        Section {
                                                TextField("SECRET (Required)", text: $secretKey)
                                                        .keyboardType(.alphabet)
                                                        .disableAutocorrection(true)
                                                        .autocapitalization(.none)
                                                        .font(.callout.monospaced())
                                        } header: {
                                                Text(verbatim: "Secret Key")
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
                        guard let token: Token = Token(uri: keyUri.trimmed()) else { return nil }
                        return token
                } else {
                        guard !secretKey.isEmpty else { return nil }
                        guard let token: Token = Token(issuerPrefix: issuer.trimmed(),
                                                       accountName: accountName.trimmed(),
                                                       secret: secretKey.trimmed(),
                                                       issuer: issuer.trimmed()) else { return nil }
                        return token
                }
        }
}
