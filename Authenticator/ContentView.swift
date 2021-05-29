import SwiftUI
import CoreData

struct ContentView: View {

        @Environment(\.managedObjectContext) var context

        @State private var editMode: EditMode = .inactive

        @State private var tokens: [Token] = []
        @State private var selectedTokens = Set<Token>()
        @State private var tokenIndex: Int = 0

        private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        @State private var timeRemaining: Int = 30 - (Int(Date().timeIntervalSince1970) % 30)
        @State var codes: [String] = ["000000"]

        @State private var isDeletionAlertPresented: Bool = false
        @State private var indexSetOnDelete: IndexSet = IndexSet()

        @State private var isSheetPresented: Bool = false

        var body: some View {
                NavigationView {
                        List(selection: $selectedTokens) {
                                ForEach(tokens, id: \.self) { token in
                                        if editMode == .active {
                                                CodeCardView(token: token,
                                                         totp: $codes[tokens.firstIndex(of: token) ?? 0],
                                                         timeRemaining: $timeRemaining)
                                        } else {
                                                ZStack {
                                                        GlobalBackgroundColor()
                                                        CodeCardView(token: token,
                                                                 totp: $codes[tokens.firstIndex(of: token) ?? 0],
                                                                 timeRemaining: $timeRemaining)
                                                                .contextMenu(menuItems: {
                                                                        Button(action: {
                                                                                UIPasteboard.general.string = codes[tokens.firstIndex(of: token) ?? 0]
                                                                        }) {
                                                                                MenuLabel(text: "Copy code", image: "doc.on.doc")
                                                                        }
                                                                        Button(action: {
                                                                                tokenIndex = tokens.firstIndex(of: token) ?? 0
                                                                                presentingSheet = .cardViewDetail
                                                                                isSheetPresented = true
                                                                        }) {
                                                                                MenuLabel(text: "View detail", image: "text.justifyleft")
                                                                        }
                                                                        Button(action: {
                                                                                tokenIndex = tokens.firstIndex(of: token) ?? 0
                                                                                presentingSheet = .cardEditing
                                                                                isSheetPresented = true
                                                                        }) {
                                                                                MenuLabel(text: "Edit account", image: "square.and.pencil")
                                                                        }
                                                                        Button(action: {
                                                                                tokenIndex = tokens.firstIndex(of: token) ?? 0
                                                                                isDeletionAlertPresented = true
                                                                        }) {
                                                                                MenuLabel(text: "Delete", image: "trash")
                                                                        }
                                                                })
                                                                .padding(.vertical, 4)
                                                }
                                                .listRowInsets(EdgeInsets())
                                        }
                                }
                                .onDelete(perform: delete(at:))
                                .onMove(perform: move(from:to:))
                        }
                        .listStyle(InsetGroupedListStyle())
                        .onAppear(perform: setupTokens)
                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                                codes = generateCodes()
                                clearTemporaryDirectory()
                        }
                        .onReceive(timer) { _ in
                                timeRemaining = 30 - (Int(Date().timeIntervalSince1970) % 30)
                                if timeRemaining == 30 {
                                        codes = generateCodes()
                                }
                        }
                        .alert(isPresented: $isDeletionAlertPresented) {
                                deletionAlert
                        }
                        .navigationTitle("2FA Auth")
                        .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                        if self.editMode == .active {
                                                Button(action: {
                                                        self.editMode = .inactive
                                                        self.selectedTokens.removeAll()
                                                }) {
                                                        Text("Done")
                                                }
                                        } else {
                                                Menu {
                                                        Button(action: {
                                                                self.editMode = .active
                                                        }) {
                                                                HStack {
                                                                        Text("Edit")
                                                                        Spacer()
                                                                        Image(systemName: "list.bullet")
                                                                }
                                                        }
                                                        Button(action: {
                                                                presentingSheet = .moreExport
                                                                isSheetPresented = true
                                                        }) {
                                                                HStack {
                                                                        Text("Export")
                                                                        Spacer()
                                                                        Image(systemName: "square.and.arrow.up")
                                                                }
                                                        }
                                                        Button(action: {
                                                                presentingSheet = .moreAbout
                                                                isSheetPresented = true
                                                        }) {
                                                                HStack {
                                                                        Text("About")
                                                                        Spacer()
                                                                        Image(systemName: "info.circle")
                                                                }
                                                        }
                                                } label: {
                                                        Image(systemName: "ellipsis.circle")
                                                                .resizable()
                                                                .scaledToFit()
                                                                .frame(width: 22, height: 22)
                                                }
                                        }
                                }
                                ToolbarItemGroup(placement: .navigationBarTrailing) {
                                        if self.editMode == .active {
                                                Button(action: {
                                                        isDeletionAlertPresented = true
                                                        self.editMode = .inactive
                                                }){
                                                        Image(systemName: "trash").opacity(selectedTokens.isEmpty ? 0.2 : 1)
                                                }
                                        } else {
                                                Button(action: {
                                                        presentingSheet = .addByScanner
                                                        isSheetPresented = true
                                                }) {
                                                        Image(systemName: "qrcode.viewfinder")
                                                }
                                                Menu {
                                                        Button(action: {
                                                                presentingSheet = .addByScanner
                                                                isSheetPresented = true
                                                        }) {
                                                                HStack {
                                                                        Text("Scan QR Code")
                                                                        Spacer()
                                                                        Image(systemName: "qrcode.viewfinder")
                                                                }
                                                        }
                                                        Button(action: {
                                                                presentingSheet = .addByQRCodeImage
                                                                isSheetPresented = true
                                                        }) {
                                                                HStack {
                                                                        Text("Read QR Code image")
                                                                        Spacer()
                                                                        Image(systemName: "photo")
                                                                }
                                                        }
                                                        Button(action: {
                                                                presentingSheet = .addByURIFile
                                                                isSheetPresented = true
                                                        }) {
                                                                HStack {
                                                                        Text("Import from file")
                                                                        Spacer()
                                                                        Image(systemName: "doc.badge.plus")
                                                                }
                                                        }
                                                        Button(action: {
                                                                presentingSheet = .addByManually
                                                                isSheetPresented = true
                                                        }) {
                                                                HStack {
                                                                        Text("Enter manually")
                                                                        Spacer()
                                                                        Image(systemName: "text.cursor")
                                                                }
                                                        }
                                                } label: {
                                                        Image(systemName: "plus")
                                                                .resizable()
                                                                .scaledToFit()
                                                                .frame(width: 20, height: 20)
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
                                        PhotoPicker(completion: handleImagePick(uri:))
                                case .addByURIFile:
                                        DocumentPickerView(isPresented: $isSheetPresented, completion: handleImportFromFile(url:))
                                case .addByManually:
                                        ManualEntryView(isPresented: $isSheetPresented, completion: handleManualEntry(token:))
                                case .cardViewDetail:
                                        TokenDetailView(isPresented: $isSheetPresented, token: tokens[tokenIndex])
                                case .cardEditing:
                                        EditAccountView(isPresented: $isSheetPresented, token: $tokens[tokenIndex], completion: updateTokenData)
                                }
                        }
                        .environment(\.editMode, $editMode)
                }
                .navigationViewStyle(StackNavigationViewStyle())
        }

        private func generateCodes() -> [String] {
                // prevent crash while deleting
                let placeholder: [String] = Array(repeating: "000000", count: 30)
                
                guard !tokens.isEmpty else { return placeholder }
                let generated: [String?] = tokens.map {
                        OTPGenerator.totp(secret: $0.secret)
                }
                let codes: [String] = generated.compactMap { $0 }
                return codes + placeholder
        }

        // MARK: - Handlers

        private func delete(at offsets: IndexSet) {
                indexSetOnDelete = offsets
                isDeletionAlertPresented = true
        }
        private func move(from source: IndexSet, to destination: Int) {
                tokens.move(fromOffsets: source, toOffset: destination)
                codes = generateCodes()
                updateTokenData()
        }

        private func handleScan(result: Result<String, ScannerView.ScanError>) {
                isSheetPresented = false
                switch result {
                case .success(let code):
                        let uri: String = code.trimmingSpaces()
                        guard !uri.isEmpty else { return }
                        guard let newToken: Token = Token(uri: uri) else { return }
                        tokens.append(newToken)
                        codes = generateCodes()
                        updateTokenData()
                case .failure(let error):
                        debugLog("Scanning failed")
                        debugLog(error.localizedDescription)
                }
        }
        private func handleImagePick(uri: String) {
                let qrCodeUri: String = uri.trimmingSpaces()
                guard !qrCodeUri.isEmpty else { return }
                guard let newToken: Token = Token(uri: qrCodeUri) else { return }
                tokens.append(newToken)
                codes = generateCodes()
                updateTokenData()
        }
        private func handleImportFromFile(url: URL?) {
                guard let url: URL = url else { return }
                guard let content: String = url.readText() else { return }
                let lines: [String] = content.components(separatedBy: .newlines)
                var shouldUpdateTokenData: Bool = false
                _ = lines.map {
                        if let newToken: Token = Token(uri: $0.trimmingSpaces()) {
                                tokens.append(newToken)
                                shouldUpdateTokenData = true
                        }
                }
                if shouldUpdateTokenData {
                        codes = generateCodes()
                        updateTokenData()
                }
        }
        private func handleManualEntry(token: Token) {
                tokens.append(token)
                codes = generateCodes()
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
                indexSetOnDelete.removeAll()
                selectedTokens.removeAll()
        }
        private func performDeletion() {
                if !indexSetOnDelete.isEmpty {
                        tokens.remove(atOffsets: indexSetOnDelete)
                } else if !selectedTokens.isEmpty {
                        tokens.removeAll { selectedTokens.contains($0) }
                } else {
                        tokens.removeAll { $0.id == tokens[tokenIndex].id }
                }
                codes = generateCodes()
                updateTokenData()
                indexSetOnDelete.removeAll()
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
                codes = generateCodes()
        }
        private func updateTokenData() {
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "TokenData")
                let deleteRequest: NSBatchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                do {
                        try context.execute(deleteRequest)
                } catch {
                        debugLog(error.localizedDescription)
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
                        debugLog(error.localizedDescription)
                }
        }

        private func clearTemporaryDirectory() {
                let tmpDirUrl: URL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                guard let urls: [URL] = try? FileManager.default.contentsOfDirectory(at: tmpDirUrl, includingPropertiesForKeys: nil) else { return }
                _ = urls.map { try? FileManager.default.removeItem(at: $0) }
        }

        private func debugLog(_ text: String) {
                #if DEBUG
                print(text)
                #endif
        }
}

private var presentingSheet: SheetSet = .moreAbout

private enum SheetSet {
        case moreExport
        case moreAbout
        case addByScanner
        case addByQRCodeImage
        case addByURIFile
        case addByManually
        case cardViewDetail
        case cardEditing
}
