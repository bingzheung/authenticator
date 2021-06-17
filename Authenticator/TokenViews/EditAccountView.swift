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
                                                EnhancedTextField(placeholder: NSLocalizedString("Issuer", comment: ""),
                                                                  text: $displayIssuer,
                                                                  autocorrection: .no,
                                                                  autocapitalization: .words)
                                                        .padding(8)
                                                        .fillBackground()
                                        }
                                        .padding()
                                        
                                        VStack {
                                                HStack {
                                                        Text("Account Name").font(.headline)
                                                        Spacer()
                                                }
                                                EnhancedTextField(placeholder: NSLocalizedString("Account Name", comment: ""),
                                                                  text: $displayAccountName,
                                                                  keyboardType: .emailAddress,
                                                                  autocorrection: .no,
                                                                  autocapitalization: UITextAutocapitalizationType.none)
                                                        .padding(8)
                                                        .fillBackground()
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
                                                displayIssuer = displayIssuer.trimming()
                                                displayAccountName = displayAccountName.trimming()
                                                completion(tokenIndex, displayIssuer, displayAccountName)
                                                isPresented = false
                                        }) {
                                                Text("Done")
                                        }
                                }
                        }
                }.onAppear {
                        displayIssuer = token.displayIssuer
                        displayAccountName = token.displayAccountName
                }
        }
}
