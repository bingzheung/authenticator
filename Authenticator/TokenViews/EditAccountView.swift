import SwiftUI

struct EditAccountView: View {
        
        @Binding var isPresented: Bool
        @Binding var token: Token
        let completion: () -> Void
        
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
                                                TextField("Issuer", text: $token.displayIssuer)
                                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        }.padding()
                                        
                                        VStack {
                                                HStack {
                                                        Text("Account Name").font(.headline)
                                                        Spacer()
                                                }
                                                TextField("Account Name", text: $token.displayAccountName)
                                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                                        .keyboardType(.emailAddress)
                                                        .disableAutocorrection(true)
                                                        .autocapitalization(.none)
                                        }.padding(.horizontal)
                                        
                                        HStack {
                                                Text("NOTE: Changes would not apply to the Key URI")
                                                        .font(.footnote)
                                                        .foregroundColor(Color.secondary)
                                                Spacer()
                                        }.padding()
                                }
                        }
                        .navigationTitle("Edit account")
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
                                                token.displayIssuer = token.displayIssuer.trimmingSpaces
                                                token.displayAccountName = token.displayAccountName.trimmingSpaces
                                                completion()
                                                isPresented = false
                                        }) {
                                                Text("Done")
                                        }
                                }
                        }
                }
        }
}
