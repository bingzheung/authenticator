import SwiftUI
import CoreData

struct ContentView: View {

        @Environment(\.managedObjectContext) private var viewContext

        @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \TokenData.indexNumber, ascending: true)], animation: .default)
        private var fetchedTokens: FetchedResults<TokenData>

        private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        @State private var timeRemaining: Int = 30 - (Int(Date().timeIntervalSince1970) % 30)
        @State private var codes: [String] = Array(repeating: "000000", count: 50)

        @State private var isSheetPresented: Bool = false

        @State private var editMode: EditMode = .inactive
        @State private var selectedTokens = Set<TokenData>()
        @State private var indexSetOnDelete: IndexSet = IndexSet()
        @State private var isDeletionAlertPresented: Bool = false

        var body: some View {
                NavigationView {
                        List(selection: $selectedTokens) {
                                ForEach(fetchedTokens, id: \.self) { item in
                                        let index: Int = Int(fetchedTokens.firstIndex(of: item) ?? 0)
                                        if editMode == .active {
                                                CodeCardView(token: token(of: item),
                                                             totp: $codes[index],
                                                             timeRemaining: $timeRemaining)
                                        } else {
                                                ZStack {
                                                        GlobalBackgroundColor()
                                                        CodeCardView(token: token(of: item),
                                                                     totp: $codes[index],
                                                                     timeRemaining: $timeRemaining)
                                                                .contextMenu {
                                                                        Button(action: {
                                                                                UIPasteboard.general.string = codes[index]
                                                                        }) {
                                                                                MenuLabel(text: "Copy code", image: "doc.on.doc")
                                                                        }
                                                                        Button(action: {
                                                                                tokenIndex = index
                                                                                presentingSheet = .cardDetailView
                                                                                isSheetPresented = true
                                                                        }) {
                                                                                MenuLabel(text: "View detail", image: "text.justifyleft")
                                                                        }
                                                                        Button(action: {
                                                                                tokenIndex = index
                                                                                presentingSheet = .cardEditing
                                                                                isSheetPresented = true
                                                                        }) {
                                                                                MenuLabel(text: "Edit account", image: "square.and.pencil")
                                                                        }
                                                                        Button(action: {
                                                                                tokenIndex = index
                                                                                selectedTokens.removeAll()
                                                                                indexSetOnDelete.removeAll()
                                                                                isDeletionAlertPresented = true
                                                                        }) {
                                                                                MenuLabel(text: "Delete", image: "trash")
                                                                        }
                                                                }
                                                                .padding(.vertical, 4)
                                                }
                                                .listRowInsets(EdgeInsets())
                                        }
                                }
                                .onMove(perform: move(from:to:))
                                .onDelete(perform: deleteItems)
                        }
                        .listStyle(InsetGroupedListStyle())
                        .onAppear {
                                generateCodes()
                        }
                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                                generateCodes()
                                clearTemporaryDirectory()
                        }
                        .onReceive(timer) { _ in
                                timeRemaining = 30 - (Int(Date().timeIntervalSince1970) % 30)
                                if timeRemaining == 30 {
                                        generateCodes()
                                }
                        }
                        .alert(isPresented: $isDeletionAlertPresented) {
                                deletionAlert
                        }
                        .navigationTitle("2FA Auth")
                        .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                        if editMode == .active {
                                                Button(action: {
                                                        editMode = .inactive
                                                        selectedTokens.removeAll()
                                                        indexSetOnDelete.removeAll()
                                                }) {
                                                        Text("Done")
                                                }
                                        } else {
                                                Menu {
                                                        Button(action: {
                                                                selectedTokens.removeAll()
                                                                indexSetOnDelete.removeAll()
                                                                editMode = .active
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
                                                                .frame(width: 24, height: 24)
                                                                .padding(.trailing, 8)
                                                                .contentShape(Rectangle())
                                                }
                                        }
                                }
                                ToolbarItemGroup(placement: .navigationBarTrailing) {
                                        if editMode == .active {
                                                Button(action: {
                                                        if !selectedTokens.isEmpty {
                                                                isDeletionAlertPresented = true
                                                        }
                                                }) {
                                                        Image(systemName: "trash")
                                                }
                                        } else {
                                                #if !targetEnvironment(macCatalyst)
                                                Button(action: {
                                                        presentingSheet = .addByScanning
                                                        isSheetPresented = true
                                                }) {
                                                        Image(systemName: "qrcode.viewfinder")
                                                                .resizable()
                                                                .scaledToFit()
                                                                .frame(width: 23, height: 23)
                                                                .contentShape(Rectangle())
                                                }
                                                #endif
                                                Menu {
                                                        #if !targetEnvironment(macCatalyst)
                                                        Button(action: {
                                                                presentingSheet = .addByScanning
                                                                isSheetPresented = true
                                                        }) {
                                                                HStack {
                                                                        Text("Scan QR Code")
                                                                        Spacer()
                                                                        Image(systemName: "qrcode.viewfinder")
                                                                }
                                                        }
                                                        #endif
                                                        Button(action: {
                                                                presentingSheet = .addByQRCodeImage
                                                                isSheetPresented = true
                                                        }) {
                                                                HStack {
                                                                        Text(readQRCodeImage)
                                                                        Spacer()
                                                                        Image(systemName: "photo")
                                                                }
                                                        }
                                                        Button(action: {
                                                                presentingSheet = .addByPickingFile
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
                                                                .frame(width: 22, height: 22)
                                                                .padding(.leading, 4)
                                                                .contentShape(Rectangle())
                                                }
                                        }
                                }
                        }
                        .sheet(isPresented: $isSheetPresented) {
                                switch presentingSheet {
                                case .moreExport:
                                        ExportView(isPresented: $isSheetPresented, tokens: tokensToExport)
                                case .moreAbout:
                                        AboutView(isPresented: $isSheetPresented)
                                case .addByScanning:
                                        Scanner(isPresented: $isSheetPresented, codeTypes: [.qr], completion: handleScanning(result:))
                                case .addByQRCodeImage:
                                        PhotoPicker(completion: handlePickedImage(uri:))
                                case .addByPickingFile:
                                        DocumentPicker(isPresented: $isSheetPresented, completion: handlePickedFile(url:))
                                case .addByManually:
                                        ManualEntryView(isPresented: $isSheetPresented, completion: handleManualEntry(token:))
                                case .cardDetailView:
                                        TokenDetailView(isPresented: $isSheetPresented, token: token(of: fetchedTokens[tokenIndex]))
                                case .cardEditing:
                                        EditAccountView(isPresented: $isSheetPresented, token: token(of: fetchedTokens[tokenIndex]), tokenIndex: tokenIndex) { index, issuer, account in
                                                handleAccountEditing(index: index, issuer: issuer, account: account)
                                        }
                                }
                        }
                        .environment(\.editMode, $editMode)
                }
                .navigationViewStyle(StackNavigationViewStyle())
        }


        // MARK: - Modification

        private func addItem(_ token: Token) {
                withAnimation {
                        let newTokenData = TokenData(context: viewContext)
                        newTokenData.id = token.id
                        newTokenData.uri = token.uri
                        newTokenData.displayIssuer = token.displayIssuer
                        newTokenData.displayAccountName = token.displayAccountName
                        let lastIndexNumber: Int64 = fetchedTokens.last?.indexNumber ?? Int64(fetchedTokens.count)
                        newTokenData.indexNumber = lastIndexNumber + 1
                        do {
                                try viewContext.save()
                        } catch {
                                let nsError = error as NSError
                                logger.debug("Unresolved error \(nsError), \(nsError.userInfo)")
                        }
                        generateCodes()
                }
        }
        private func move(from source: IndexSet, to destination: Int) {
                var idArray: [String] = fetchedTokens.map({ $0.id ?? Token().id })
                idArray.move(fromOffsets: source, toOffset: destination)
                for number in 0..<fetchedTokens.count {
                        let item = fetchedTokens[number]
                        if let index = idArray.firstIndex(where: { $0 == item.id }) {
                                if Int64(index) != item.indexNumber {
                                        fetchedTokens[number].indexNumber = Int64(index)
                                }
                        }
                }
                do {
                        try viewContext.save()
                } catch {
                        let nsError = error as NSError
                        logger.debug("Unresolved error \(nsError), \(nsError.userInfo)")
                }
        }
        private func deleteItems(offsets: IndexSet) {
                selectedTokens.removeAll()
                indexSetOnDelete = offsets
                isDeletionAlertPresented = true
        }
        private func cancelDeletion() {
                indexSetOnDelete.removeAll()
                selectedTokens.removeAll()
                isDeletionAlertPresented = false
        }
        private func performDeletion() {
                withAnimation {
                        delete()
                }
        }
        private func delete() {
                if !selectedTokens.isEmpty {
                        _ = selectedTokens.map { oneSelection in
                                _ = fetchedTokens.filter({ $0.id == oneSelection.id }).map(viewContext.delete)
                        }
                } else if !indexSetOnDelete.isEmpty {
                        _ = indexSetOnDelete.map({ fetchedTokens[$0] }).map(viewContext.delete)
                } else {
                        viewContext.delete(fetchedTokens[tokenIndex])
                }
                do {
                        try viewContext.save()
                } catch {
                        let nsError = error as NSError
                        logger.debug("Unresolved error \(nsError), \(nsError.userInfo)")
                }
                indexSetOnDelete.removeAll()
                selectedTokens.removeAll()
                isDeletionAlertPresented = false
                generateCodes()
        }
        private var deletionAlert: Alert {
                let message: String = "Removing account will NOT turn off Two-Factor Authentication.\n\nMake sure you have alternate ways to sign into your service."
                return Alert(title: Text("Delete Account?"),
                             message: Text(NSLocalizedString(message, comment: "")),
                             primaryButton: .cancel(cancelDeletion),
                             secondaryButton: .destructive(Text("Delete"), action: performDeletion))
        }


        // MARK: - Account Adding

        private func handleScanning(result: Result<String, ScannerView.ScanError>) {
                isSheetPresented = false
                switch result {
                case .success(let code):
                        let uri: String = code.trimming()
                        guard !uri.isEmpty else { return }
                        guard let newToken: Token = Token(uri: uri) else { return }
                        addItem(newToken)
                case .failure(let error):
                        logger.debug("\(error.localizedDescription)")
                }
        }
        private func handlePickedImage(uri: String) {
                let qrCodeUri: String = uri.trimming()
                guard !qrCodeUri.isEmpty else { return }
                guard let newToken: Token = Token(uri: qrCodeUri) else { return }
                addItem(newToken)
        }
        private func handlePickedFile(url: URL?) {
                guard let url: URL = url else { return }
                guard let content: String = url.readText() else { return }
                let lines: [String] = content.components(separatedBy: .newlines)
                _ = lines.map {
                        if let newToken: Token = Token(uri: $0.trimming()) {
                                addItem(newToken)
                        }
                }
        }
        private func handleManualEntry(token: Token) {
                addItem(token)
        }


        // MARK: - Methods

        private func token(of tokenData: TokenData) -> Token {
                guard let id = tokenData.id,
                        let uri = tokenData.uri,
                        let displayIssuer = tokenData.displayIssuer,
                        let displayAccountName = tokenData.displayAccountName
                else { return Token() }
                guard let token = Token(id: id, uri: uri, displayIssuer: displayIssuer, displayAccountName: displayAccountName) else { return Token() }
                return token
        }
        private func generateCodes() {
                let placeholder: [String] = Array(repeating: "000000", count: 30)
                guard !fetchedTokens.isEmpty else {
                        codes = placeholder
                        return
                }
                let generated: [String] = fetchedTokens.map { code(of: $0) }
                codes = generated + placeholder
        }
        private func code(of tokenData: TokenData) -> String {
                guard let uri = tokenData.uri else { return "000000" }
                guard let token = Token(uri: uri) else { return "000000" }
                guard let code = OTPGenerator.totp(secret: token.secret, algorithm: token.algorithm, period: token.period) else { return "000000" }
                return code
        }

        private func handleAccountEditing(index: Int, issuer: String, account: String) {
                let item = fetchedTokens[index]
                if item.displayIssuer != issuer {
                        fetchedTokens[index].displayIssuer = issuer
                }
                if item.displayAccountName != account {
                        fetchedTokens[index].displayAccountName = account
                }
        }

        private var tokensToExport: [Token] {
                return fetchedTokens.map({ token(of: $0) })
        }

        private func clearTemporaryDirectory() {
                let temporaryDirectoryUrl: URL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                guard let urls: [URL] = try? FileManager.default.contentsOfDirectory(at: temporaryDirectoryUrl, includingPropertiesForKeys: nil) else { return }
                _ = urls.map { try? FileManager.default.removeItem(at: $0) }
        }

        private let readQRCodeImage: String = {
                #if targetEnvironment(macCatalyst)
                return NSLocalizedString("Read from QR Code picture", comment: "")
                #else
                return NSLocalizedString("Read QR Code image", comment: "")
                #endif
        }()
}

private var presentingSheet: SheetSet = .moreAbout
private var tokenIndex: Int = 0

private enum SheetSet {
        case moreExport
        case moreAbout
        case addByScanning
        case addByQRCodeImage
        case addByPickingFile
        case addByManually
        case cardDetailView
        case cardEditing
}
