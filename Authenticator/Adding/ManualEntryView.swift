import SwiftUI

private enum EntryMethod: Int {
        case keyURI
        case secretKey
}

struct ManualEntryView: View {

        @Binding var isPresented: Bool
        let completion: (Token) -> Void

        @State private var entryMethod: EntryMethod = .keyURI
        @State private var keyUri: String = .empty
        @State private var issuer: String = .empty
        @State private var accountName: String = .empty
        @State private var secretKey: String = .empty

        @State private var isAlertPresented: Bool = false

        var body: some View {
                NavigationView {
                        List {
                                Section {
                                        Picker("Method", selection: $entryMethod) {
                                                Text("By Key URI").tag(EntryMethod.keyURI)
                                                Text("By Secret Key").tag(EntryMethod.secretKey)
                                        }
                                        .pickerStyle(.segmented)
                                }
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)

                                if entryMethod == EntryMethod.keyURI {
                                        Section {
                                                TextField("otpauth://totp/...", text: $keyUri)
                                                        .keyboardType(.URL)
                                                        .submitLabel(.done)
                                                        .autocorrectionDisabled()
                                                        .textInputAutocapitalization(.never)
                                                        .font(.footnote.monospaced())
                                        } header: {
                                                Text(verbatim: "Key URI")
                                        }
                                } else {
                                        Section {
                                                TextField("Service Provider (Optional)", text: $issuer)
                                                        .submitLabel(.done)
                                                        .autocorrectionDisabled()
                                                        .textInputAutocapitalization(.words)
                                        } header: {
                                                Text(verbatim: "Issuer")
                                        }

                                        Section {
                                                TextField("Email or Username (Optional)", text: $accountName)
                                                        .keyboardType(.asciiCapable)
                                                        .submitLabel(.done)
                                                        .autocorrectionDisabled()
                                                        .textInputAutocapitalization(.never)
                                        } header: {
                                                Text(verbatim: "Account Name")
                                        }

                                        Section {
                                                TextField("SECRET (Required)", text: $secretKey)
                                                        .keyboardType(.asciiCapable)
                                                        .submitLabel(.done)
                                                        .autocorrectionDisabled()
                                                        .textInputAutocapitalization(.never)
                                                        .font(.callout.monospaced())
                                        } header: {
                                                Text(verbatim: "Secret Key")
                                        }
                                }
                        }
                        .alert("Error", isPresented: $isAlertPresented) {
                                Button("OK", role: .cancel, action: { isAlertPresented.toggle() })
                        } message: {
                                Text("Invalid Key")
                        }
                        .navigationTitle("Add Account")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                        Button("Cancel") {
                                                isPresented = false
                                        }
                                }
                                ToolbarItem(placement: .confirmationAction) {
                                        Button("Add") {
                                                handleAdding()
                                        }
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
                switch entryMethod {
                case .keyURI:
                        let uri = keyUri.trimmed()
                        guard !(uri.isEmpty) else { return nil }
                        guard let token: Token = Token(uri: uri) else { return nil }
                        return token
                case .secretKey:
                        let secret = secretKey.trimmed()
                        guard !(secret.isEmpty) else { return nil }
                        let issuerText = issuer.trimmed()
                        let account = accountName.trimmed()
                        guard let token: Token = Token(issuerPrefix: issuerText, accountName: account, secret: secret, issuer: issuerText) else { return nil }
                        return token
                }
        }
}
