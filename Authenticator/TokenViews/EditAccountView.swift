import SwiftUI

struct EditAccountView: View {

        @Binding var isPresented: Bool
        let token: Token
        let tokenIndex: Int
        let completion: (Int, String, String) -> Void

        @State private var displayIssuer: String = ""
        @State private var displayAccountName: String = ""

        var body: some View {
                NavigationView {
                        ZStack {
                                GlobalBackgroundColor().ignoresSafeArea()
                                ScrollView {
                                        VStack {
                                                HStack {
                                                        Text("Issuer").font(.headline)
                                                        Spacer()
                                                }
                                                TextField(token.displayIssuer, text: $displayIssuer)
                                                        .disableAutocorrection(true)
                                                        .autocapitalization(.words)
                                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        }
                                        .padding(.horizontal)

                                        VStack {
                                                HStack {
                                                        Text("Account Name").font(.headline)
                                                        Spacer()
                                                }
                                                TextField(token.displayAccountName, text: $displayAccountName)
                                                        .keyboardType(.emailAddress)
                                                        .disableAutocorrection(true)
                                                        .autocapitalization(.none)
                                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        }
                                        .padding()

                                        HStack {
                                                Text("**NOTE**: Changes would not apply to the Key URI").font(.footnote)
                                                Spacer()
                                        }
                                        .padding()
                                }
                        }
                        .onAppear {
                                displayIssuer = token.displayIssuer
                                displayAccountName = token.displayAccountName
                        }
                        .navigationTitle("title.edit_account")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                        Button("Cancel", role: .cancel, action: { isPresented = false })
                                }
                                ToolbarItem(placement: .confirmationAction) {
                                        Button("Done") {
                                                let issuer: String = displayIssuer.trimming()
                                                let accountName: String = displayAccountName.trimming()
                                                let checkedIssuer: String = issuer.isEmpty ? token.displayIssuer : issuer
                                                let checkedAccountName: String = accountName.isEmpty ? token.displayAccountName : accountName
                                                completion(tokenIndex, checkedIssuer, checkedAccountName)
                                                isPresented = false
                                        }
                                }
                        }
                }
        }
}
