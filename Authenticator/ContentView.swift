import SwiftUI
import CoreData

struct ContentView: View {
        
        @Environment(\.managedObjectContext) var context
        
        
        // MARK: - @State instances
        
        @State private var editMode: EditMode = .inactive
        
        @State private var tokens: [Token] = []
        @State private var selectedTokens = Set<Token>()
        @State var tokenID: String = "id"
        private var tokenIndex: Int { (tokens.firstIndex { $0.id == tokenID }) ?? 0 }
        
        private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        @State private var timeRemaining: Int = 30 - (Int(Date().timeIntervalSince1970) % 30)
        @State var codes: [String] = ["000000"]
        
        @State private var isDeletionAlertPresented: Bool = false
        @State private var indexSetOnDelete: IndexSet = IndexSet()
        
        @State private var isActionSheetPresented: Bool = false
        
        /// 0: None.
        /// 1: More Action.
        /// 2: Adding token.
        /// 3: Code Card action.
        @State private var actionSheetState: Int = 0
        
        enum SheetSet {
                case moreExport
                case moreAbout
                case addByScanner
                case addByQRCodeImage
                case addByURIFile
                case addByManualy
                case cardViewDetail
                case cardEditing
        }
        @State private var presentingSheet: SheetSet = .addByScanner
        @State private var isSheetPresented: Bool = false
        
        // MARK: - Body
        
        var body: some View {
                NavigationView {
                        List(selection: $selectedTokens) {
                                ForEach(tokens, id: \.self) { token in
                                        if editMode == .active {
                                                CodeCard(token: token,
                                                         totp: $codes[tokens.firstIndex(of: token) ?? 0],
                                                         timeRemaining: $timeRemaining,
                                                         isActionSheetPresented: $isActionSheetPresented,
                                                         actionSheetState: $actionSheetState,
                                                         tokenID: $tokenID)
                                        } else {
                                                ZStack {
                                                        GlobalBackgroundColor()
                                                        CodeCard(token: token,
                                                                 totp: $codes[tokens.firstIndex(of: token) ?? 0],
                                                                 timeRemaining: $timeRemaining,
                                                                 isActionSheetPresented: $isActionSheetPresented,
                                                                 actionSheetState: $actionSheetState,
                                                                 tokenID: $tokenID)
                                                                .padding(.vertical, 8)
                                                }
                                                .listRowInsets(EdgeInsets())
                                        }
                                        
                                }
                                .onDelete(perform: delete(at:))
                                .onMove(perform: move(from:to:))
                        }
                        .listStyle(InsetGroupedListStyle())
                        .onAppear(perform: setupTokens)
                        .onReceive(timer) { _ in
                                timeRemaining = 30 - (Int(Date().timeIntervalSince1970) % 30)
                                if timeRemaining == 30 {
                                        codes = genCodes()
                                }
                        }
                        .alert(isPresented: $isDeletionAlertPresented) {
                                deletionAlert
                        }
                        .navigationTitle("2FA Auth")
                        .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                        Button(action: {
                                                if self.editMode == .inactive {
                                                        actionSheetState = 1
                                                        isActionSheetPresented = true
                                                }
                                                if self.editMode == .active {
                                                        self.editMode = .inactive
                                                        self.selectedTokens.removeAll()
                                                        self.updateTokenData()
                                                }
                                        }) {
                                                if editMode == .active {
                                                        Text("Done")
                                                } else {
                                                        Image(systemName: "ellipsis.circle")
                                                }
                                        }
                                }
                                ToolbarItemGroup(placement: .navigationBarTrailing) {
                                        if editMode != .active {
                                                Button(action: {
                                                        presentingSheet = .addByScanner
                                                        isSheetPresented = true
                                                }) {
                                                        Image(systemName: "qrcode.viewfinder")
                                                }
                                        }
                                        Button(action: {
                                                if self.editMode == .inactive {
                                                        actionSheetState = 2
                                                        isActionSheetPresented = true
                                                }
                                                if self.editMode == .active {
                                                        triggerDeletion()
                                                        self.editMode = .inactive
                                                }
                                        }) {
                                                if editMode == .active {
                                                        Image(systemName: "trash").opacity(selectedTokens.isEmpty ? 0.2 : 1)
                                                } else {
                                                        Image(systemName: "plus")
                                                }
                                        }
                                }
                        }
                        .sheet(isPresented: $isSheetPresented) {
                                switch presentingSheet {
                                case .moreExport:
                                        ExportView(isPresented: $isSheetPresented, tokens: tokens)
                                case .moreAbout:
                                        AboutView(isPresented: $isSheetPresented)
                                case .addByScanner:
                                        Scanner(isPresented: $isSheetPresented, codeTypes: [.qr], completion: handleScan(result:))
                                case .addByQRCodeImage:
                                        ImagePickerView(isPresented: $isSheetPresented, completion: handleImagePick(uri:))
                                case .addByURIFile:
                                        DocumentPickerView(isPresented: $isSheetPresented, completion: handleImportFromFile(url:))
                                case .addByManualy:
                                        ManualEntryView(isPresented: $isSheetPresented, completion: handleManualEntry(token:))
                                case .cardViewDetail:
                                        TokenDetailView(isPresented: $isSheetPresented, token: tokens[tokenIndex])
                                case .cardEditing:
                                        EditAccountView(isPresented: $isSheetPresented, token: $tokens[tokenIndex], completion: updateTokenData)
                                }
                        }
                        .actionSheet(isPresented: $isActionSheetPresented) {
                                switch actionSheetState {
                                case 1:
                                        return ActionSheet(title: Text("2FA Auth"), buttons: [
                                                .default(Text("Edit")) {
                                                        self.editMode = .active
                                                },
                                                .default(Text("Export")) {
                                                        presentingSheet = .moreExport
                                                        isSheetPresented = true
                                                },
                                                .default(Text("About")) {
                                                        presentingSheet = .moreAbout
                                                        isSheetPresented = true
                                                },
                                                .cancel()
                                        ])
                                case 2:
                                        return ActionSheet(title: Text("Add accounts"), buttons: [
                                                .default(Text("Scan QR Code"), action: {
                                                        presentingSheet = .addByScanner
                                                        isSheetPresented = true
                                                }),
                                                .default(Text("Read QR Code image"), action: {
                                                        presentingSheet = .addByQRCodeImage
                                                        isSheetPresented = true
                                                }),
                                                .default(Text("Import from file"), action: {
                                                        presentingSheet = .addByURIFile
                                                        isSheetPresented = true
                                                }),
                                                .default(Text("Enter manually"), action: {
                                                        presentingSheet = .addByManualy
                                                        isSheetPresented = true
                                                }),
                                                .cancel()
                                        ])
                                default:
                                        let token: Token = tokens[tokenIndex]
                                        let title: String = token.displayIssuer
                                        let message: String = token.displayAccountName
                                        return ActionSheet(title: Text(title), message: Text(message), buttons: [
                                                .default(Text("Copy code")) {
                                                        UIPasteboard.general.string = codes[tokenIndex]
                                                },
                                                .default(Text("View detail")) {
                                                        presentingSheet = .cardViewDetail
                                                        isSheetPresented = true
                                                },
                                                .default(Text("Edit account")) {
                                                        presentingSheet = .cardEditing
                                                        isSheetPresented = true
                                                },
                                                .destructive(Text("Delete")) {
                                                        triggerDeletion()
                                                },
                                                .cancel()
                                        ])
                                }
                        }
                        .environment(\.editMode, $editMode)
                }
                .navigationViewStyle(StackNavigationViewStyle())
        }
        
        private func genCodes() -> [String] {
                // prevent crash while delete
                let placeholder: [String] = Array(repeating: "000000", count: 30)
                
                guard !tokens.isEmpty else { return placeholder }
                let gens: [String?] = tokens.map {
                        OTPGenerator.totp(secret: $0.secret)
                }
                var gened: [String] = gens.compactMap { $0 }
                gened += placeholder
                return gened
        }
        
        // MARK: - Handlers
        
        private func delete(at offsets: IndexSet) {
                indexSetOnDelete = offsets
                triggerDeletion()
        }
        private func move(from source: IndexSet, to destination: Int) {
                tokens.move(fromOffsets: source, toOffset: destination)
                codes = genCodes()
                updateTokenData()
        }
        private func triggerDeletion() {
                isDeletionAlertPresented = true
        }
        
        private func handleScan(result: Result<String, ScannerView.ScanError>) {
                isSheetPresented = false
                switch result {
                case .success(let code):
                        guard let newToken: Token = Token(uri: code.trimmingSpaces) else { return }
                        tokens.append(newToken)
                        codes = genCodes()
                        updateTokenData()
                case .failure(let error):
                        logger.debug("Scanning failed")
                        logger.debug("\(error.localizedDescription)")
                }
        }
        private func handleImagePick(uri: String?) {
                guard let qrCodeString: String = uri else { return }
                guard let newToken: Token = Token(uri: qrCodeString.trimmingSpaces) else { return }
                tokens.append(newToken)
                codes = genCodes()
                updateTokenData()
        }
        private func handleImportFromFile(url: URL?) {
                guard url != nil else { return }
                guard let content: String = try? String(contentsOf: url!) else { return }
                let lines: [String] = content.components(separatedBy: .newlines)
                var shouldUpdateTokenData: Bool = false
                _ = lines.map {
                        if let newToken: Token = Token(uri: $0.trimmingSpaces) {
                                tokens.append(newToken)
                                shouldUpdateTokenData = true
                        }
                }
                if shouldUpdateTokenData {
                        codes = genCodes()
                        updateTokenData()
                }
        }
        private func handleManualEntry(token: Token) {
                tokens.append(token)
                codes = genCodes()
                updateTokenData()
        }
        
        private var deletionAlert: Alert {
                let message: String = """
                Removing account will NOT turn off Two-Factor Authentication.
                
                Make sure you have alternate ways to sign into your service.
                """
                return Alert(title: Text("Delete Account?"),
                             message: Text(message),
                             primaryButton: .cancel(cancelDeletion),
                             secondaryButton: .destructive(Text("Delete"), action: performDeletion)
                )
        }
        private func cancelDeletion() {
                indexSetOnDelete = IndexSet()
                selectedTokens.removeAll()
        }
        private func performDeletion() {
                if !indexSetOnDelete.isEmpty {
                        tokens.remove(atOffsets: indexSetOnDelete)
                } else if !selectedTokens.isEmpty {
                        tokens.removeAll { selectedTokens.contains($0) }
                } else {
                        tokens.removeAll { $0.id == self.tokenID }
                }
                codes = genCodes()
                updateTokenData()
                indexSetOnDelete = IndexSet()
                selectedTokens.removeAll()
        }
        
        
        // MARK: - Core Data
        
        @FetchRequest(entity: TokenData.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \TokenData.indexNumber, ascending: false).reversedSortDescriptor as! NSSortDescriptor])
        private var fetchedTokens: FetchedResults<TokenData>
        
        private func setupTokens() {
                if tokens.isEmpty {
                        _ = fetchedTokens.map {
                                if let token: Token = Token(id: $0.id, uri: $0.uri, displayIssuer: $0.displayIssuer, displayAccountName: $0.displayAccountName) {
                                        tokens.append(token)
                                }
                        }
                }
                codes = genCodes()
        }
        private func updateTokenData() {
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "TokenData")
                let deleteRequest: NSBatchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                do {
                        try context.execute(deleteRequest)
                } catch {
                        logger.debug("\(error.localizedDescription)")
                }
                _ = tokens.map { saveTokenData(token: $0) }
        }
        private func saveTokenData(token: Token) {
                let tokenData: TokenData = TokenData(context: context)
                tokenData.id = token.id
                tokenData.uri = token.uri
                tokenData.displayIssuer = token.displayIssuer
                tokenData.displayAccountName = token.displayAccountName
                tokenData.indexNumber = Int64(tokens.firstIndex(of: token) ?? 0)
                do {
                        try context.save()
                } catch {
                        logger.debug("\(error.localizedDescription)")
                }
        }
}
