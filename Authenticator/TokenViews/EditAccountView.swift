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
                                                #if targetEnvironment(macCatalyst)
                                                TextField(token.displayIssuer, text: $displayIssuer)
                                                        .disableAutocorrection(true)
                                                        .autocapitalization(.words)
                                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                                #else
                                                EnhancedTextField(placeholder: token.displayIssuer,
                                                                  text: $displayIssuer,
                                                                  autocorrection: .no,
                                                                  autocapitalization: .words)
                                                        .padding(8)
                                                        .fillBackground(cornerRadius: 8)
                                                #endif
                                        }
                                        .padding()

                                        VStack {
                                                HStack {
                                                        Text("Account Name").font(.headline)
                                                        Spacer()
                                                }
                                                #if targetEnvironment(macCatalyst)
                                                TextField(token.displayAccountName, text: $displayAccountName)
                                                        .keyboardType(.emailAddress)
                                                        .disableAutocorrection(true)
                                                        .autocapitalization(.none)
                                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                                #else
                                                EnhancedTextField(placeholder: token.displayAccountName,
                                                                  text: $displayAccountName,
                                                                  keyboardType: .emailAddress,
                                                                  autocorrection: .no,
                                                                  autocapitalization: UITextAutocapitalizationType.none)
                                                        .padding(8)
                                                        .fillBackground(cornerRadius: 8)
                                                #endif
                                        }
                                        .padding(.horizontal)
                                        .padding(.bottom)

                                        HStack {
                                                Text("NOTE: Changes would not apply to the Key URI")
                                                        .font(.footnote)
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
                        .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                        Button(action: {
                                                isPresented = false
                                        }) {
                                                Text("Cancel")
                                        }
                                }
                                ToolbarItem(placement: .navigationBarTrailing) {
                                        Button(action: {
                                                let issuer: String = displayIssuer.trimming()
                                                let accountName: String = displayAccountName.trimming()
                                                let checkedIssuer: String = issuer.isEmpty ? token.displayIssuer : issuer
                                                let checkedAccountName: String = accountName.isEmpty ? token.displayAccountName : accountName
                                                completion(tokenIndex, checkedIssuer, checkedAccountName)
                                                isPresented = false
                                        }) {
                                                Text("Done")
                                        }
                                }
                        }
                }
        }
}
