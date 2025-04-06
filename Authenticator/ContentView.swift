import SwiftUI
import CoreData

struct ContentView: View {

        @Environment(\.managedObjectContext) private var viewContext

        @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \TokenData.indexNumber, ascending: true)], animation: .default)
        private var fetchedTokens: FetchedResults<TokenData>

        private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        @State private var timeRemaining: Int = 30 - (Int(Date().timeIntervalSince1970) % 30)
        @State private var codes: [String] = Array(repeating: String.zeros, count: 50)
        @State private var animationTrigger: Bool = false

        @State private var isSheetPresented: Bool = false
        @State private var isFileImporterPresented: Bool = false

        @State private var editMode: EditMode = .inactive
        @State private var selectedTokens = Set<TokenData>()
        @State private var indexSetOnDelete: IndexSet = IndexSet()
        @State private var isDeletionAlertPresented: Bool = false

        init() {
                UITableView.appearance().sectionFooterHeight = 0
                UITextField.appearance().clearButtonMode = .always
        }

        var body: some View {
                NavigationView {
                        List(selection: $selectedTokens) {
                                ForEach(0..<fetchedTokens.count, id: \.self) { index in
                                        let item = fetchedTokens[index]
                                        Section {
                                                CodeCardView(index: index, token: token(of: item), totp: $codes[index], timeRemaining: $timeRemaining)
                                                        .contextMenu {
                                                                Button("Copy Code", systemImage: "doc.on.doc") {
                                                                        UIPasteboard.general.string = codes[index]
                                                                }
                                                                Button("View Detail", systemImage: "text.justifyleft") {
                                                                        tokenIndex = index
                                                                        presentingSheet = .viewAccountDetail
                                                                        isSheetPresented = true
                                                                }
                                                                Button("Edit Account", systemImage: "square.and.pencil") {
                                                                        tokenIndex = index
                                                                        presentingSheet = .editAccount
                                                                        isSheetPresented = true
                                                                }
                                                                Button("Delete", systemImage: "trash", role: .destructive) {
                                                                        tokenIndex = index
                                                                        selectedTokens.removeAll()
                                                                        indexSetOnDelete.removeAll()
                                                                        isDeletionAlertPresented = true
                                                                }
                                                        }
                                        }
                                }
                                .onMove(perform: move(from:to:))
                                .onDelete(perform: deleteItems)
                        }
                        .animation(.default, value: animationTrigger)
                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                                generateCodes()
                                clearTemporaryDirectory()
                        }
                        .onReceive(timer) { _ in
                                timeRemaining = 30 - (Int(Date().timeIntervalSince1970) % 30)
                                if timeRemaining == 30 || codes.first == String.zeros {
                                        generateCodes()
                                }
                        }
                        .onReceive(NotificationCenter.default.publisher(for: .viewCardAccountDetail)) { notification in
                                guard let dict = notification.userInfo as? [String : Int] else { return }
                                guard let index = dict[NotificationKey.viewCardAccountDetail] else { return }
                                tokenIndex = index
                                presentingSheet = .viewAccountDetail
                                isSheetPresented = true
                        }
                        .onReceive(NotificationCenter.default.publisher(for: .editCardAccount)) { notification in
                                guard let dict = notification.userInfo as? [String : Int] else { return }
                                guard let index = dict[NotificationKey.editCardAccount] else { return }
                                tokenIndex = index
                                presentingSheet = .editAccount
                                isSheetPresented = true
                        }
                        .onReceive(NotificationCenter.default.publisher(for: .deleteCardAccount)) { notification in
                                guard let dict = notification.userInfo as? [String : Int] else { return }
                                guard let index = dict[NotificationKey.deleteCardAccount] else { return }
                                tokenIndex = index
                                selectedTokens.removeAll()
                                indexSetOnDelete.removeAll()
                                isDeletionAlertPresented = true
                        }
                        .fileImporter(isPresented: $isFileImporterPresented, allowedContentTypes: [.text, .image], allowsMultipleSelection: false) { result in
                                switch result {
                                case .failure(let error):
                                        logger.debug(".fileImporter() failure: \(error.localizedDescription)")
                                case .success(let urls):
                                        guard let pickedUrl: URL = urls.first else { return }
                                        guard pickedUrl.startAccessingSecurityScopedResource() else { return }
                                        let cachePathComponent = Date.currentDateText + pickedUrl.lastPathComponent
                                        let cacheUrl: URL = .tmpDirectoryUrl.appendingPathComponent(cachePathComponent)
                                        try? FileManager.default.copyItem(at: pickedUrl, to: cacheUrl)
                                        pickedUrl.stopAccessingSecurityScopedResource()
                                        handlePickedFile(url: cacheUrl)
                                }
                        }
                        .alert(isPresented: $isDeletionAlertPresented) {
                                deletionAlert
                        }
                        .navigationTitle("Authenticator")
                        .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                        if editMode == .active {
                                                Button("Done") {
                                                        selectedTokens.removeAll()
                                                        indexSetOnDelete.removeAll()
                                                        editMode = .inactive
                                                }
                                        } else {
                                                Menu {
                                                        Button("Edit", systemImage: "list.bullet") {
                                                                selectedTokens.removeAll()
                                                                indexSetOnDelete.removeAll()
                                                                editMode = .active
                                                        }
                                                        Button("Export", systemImage: "square.and.arrow.up") {
                                                                presentingSheet = .export
                                                                isSheetPresented = true
                                                        }
                                                        Button("About", systemImage: "info.circle") {
                                                                presentingSheet = .about
                                                                isSheetPresented = true
                                                        }
                                                } label: {
                                                        Image(systemName: "ellipsis.circle")
                                                                .resizable()
                                                                .scaledToFit()
                                                                .frame(width: 26)
                                                                .padding(.trailing, 8)
                                                                .contentShape(Rectangle())
                                                }
                                        }
                                }
                                ToolbarItemGroup(placement: .navigationBarTrailing) {
                                        if editMode == .active {
                                                Button(role: .destructive) {
                                                        if selectedTokens.isNotEmpty {
                                                                isDeletionAlertPresented = true
                                                        }
                                                } label: {
                                                        Image(systemName: "trash")
                                                }
                                        } else {
                                                #if !targetEnvironment(macCatalyst)
                                                Button {
                                                        presentingSheet = .scanQRCode
                                                        isSheetPresented = true
                                                } label: {
                                                        Image(systemName: "qrcode.viewfinder")
                                                                .resizable()
                                                                .scaledToFit()
                                                                .frame(width: 24)
                                                                .padding(.horizontal, 2)
                                                                .contentShape(Rectangle())
                                                }
                                                #endif
                                                Menu {
                                                        #if !targetEnvironment(macCatalyst)
                                                        Button("Scan QR Code", systemImage: "qrcode.viewfinder") {
                                                                presentingSheet = .scanQRCode
                                                                isSheetPresented = true
                                                        }
                                                        #endif
                                                        Button("Import from Photos", systemImage: "photo") {
                                                                presentingSheet = .readQRCodeImage
                                                                isSheetPresented = true
                                                        }
                                                        Button {
                                                                isFileImporterPresented = true
                                                        } label: {
                                                                #if targetEnvironment(macCatalyst)
                                                                Label("Import from Finder", systemImage: "text.below.photo")
                                                                #else
                                                                Label("Import from Files", systemImage: "doc.badge.plus")
                                                                #endif
                                                        }
                                                        Button("Enter Manually", systemImage: "text.cursor") {
                                                                presentingSheet = .enterManually
                                                                isSheetPresented = true
                                                        }
                                                } label: {
                                                        Image(systemName: "plus")
                                                                .resizable()
                                                                .scaledToFit()
                                                                .frame(width: 25)
                                                                .padding(.leading, 8)
                                                                .contentShape(Rectangle())
                                                }
                                        }
                                }
                        }
                        .sheet(isPresented: $isSheetPresented) {
                                switch presentingSheet {
                                case .about:
                                        AboutView(isPresented: $isSheetPresented)
                                case .export:
                                        ExportView(isPresented: $isSheetPresented, tokens: tokensToExport)
                                case .scanQRCode:
                                        Scanner(isPresented: $isSheetPresented, codeTypes: [.qr], completion: handleScanned(_:))
                                case .readQRCodeImage:
                                        PhotoPicker(completion: handlePickedImage(uri:))
                                case .enterManually:
                                        ManualEntryView(isPresented: $isSheetPresented, completion: addItem(_:))
                                case .viewAccountDetail:
                                        TokenDetailView(isPresented: $isSheetPresented, token: token(of: fetchedTokens[tokenIndex]))
                                case .editAccount:
                                        EditAccountView(isPresented: $isSheetPresented, token: token(of: fetchedTokens[tokenIndex]), tokenIndex: tokenIndex) { index, issuer, account in
                                                handleAccountEditing(index: index, issuer: issuer, account: account)
                                        }
                                }
                        }
                        .environment(\.editMode, $editMode)
                }
                .navigationViewStyle(.stack)
        }


        // MARK: - Modification

        private func addItem(_ token: Token) {
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
                        logger.debug("\(nsError)")
                }
                generateCodes()
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
                if selectedTokens.isNotEmpty {
                        _ = selectedTokens.map { oneSelection in
                                _ = fetchedTokens.filter({ $0.id == oneSelection.id }).map(viewContext.delete)
                        }
                } else if indexSetOnDelete.isNotEmpty {
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
                return Alert(title: Text("Delete Account?"),
                             message: Text("Account Deletion Warning"),
                             primaryButton: .cancel(cancelDeletion),
                             secondaryButton: .destructive(Text("Delete"), action: performDeletion))
        }


        // MARK: - Account Adding

        private func handleScanned(_ result: Result<String, ScannerView.ScanError>) {
                isSheetPresented = false
                switch result {
                case .success(let code):
                        let uri: String = code.trimmed()
                        guard uri.isNotEmpty else { return }
                        guard let newToken: Token = Token(uri: uri) else { return }
                        addItem(newToken)
                case .failure(let error):
                        logger.debug("\(error.localizedDescription)")
                }
        }
        private func handlePickedImage(uri: String) {
                let qrCodeUri: String = uri.trimmed()
                guard qrCodeUri.isNotEmpty else { return }
                guard let newToken: Token = Token(uri: qrCodeUri) else { return }
                addItem(newToken)
        }
        private func handlePickedFile(url: URL) {
                guard let content: String = url.readText() else { return }
                let lines: [String] = content.components(separatedBy: .newlines)
                _ = lines.map {
                        if let newToken: Token = Token(uri: $0.trimmed()) {
                                addItem(newToken)
                        }
                }
        }


        // MARK: - Methods

        private func token(of tokenData: TokenData) -> Token {
                guard let id: String = tokenData.id,
                      let uri: String = tokenData.uri,
                      let displayIssuer: String = tokenData.displayIssuer,
                      let displayAccountName: String = tokenData.displayAccountName
                else { return Token() }
                guard let token = Token(id: id, uri: uri, displayIssuer: displayIssuer, displayAccountName: displayAccountName) else { return Token() }
                return token
        }
        private func generateCodes() {
                let placeholder: [String] = Array(repeating: String.zeros, count: 30)
                guard fetchedTokens.isNotEmpty else {
                        codes = placeholder
                        return
                }
                let generated: [String] = fetchedTokens.map { code(of: $0) }
                codes = generated + placeholder
                animationTrigger.toggle()
        }
        private func code(of tokenData: TokenData) -> String {
                guard let uri: String = tokenData.uri else { return String.zeros }
                guard let token: Token = Token(uri: uri) else { return String.zeros }
                guard let code: String = OTPGenerator.totp(secret: token.secret, algorithm: token.algorithm, digits: token.digits, period: token.period) else { return String.zeros }
                return code
        }

        private func handleAccountEditing(index: Int, issuer: String, account: String) {
                let item: TokenData = fetchedTokens[index]
                if item.displayIssuer != issuer {
                        fetchedTokens[index].displayIssuer = issuer
                }
                if item.displayAccountName != account {
                        fetchedTokens[index].displayAccountName = account
                }
                do {
                        try viewContext.save()
                } catch {
                        let nsError = error as NSError
                        logger.debug("Unresolved error \(nsError), \(nsError.userInfo)")
                }
                isSheetPresented = false
        }

        private var tokensToExport: [Token] {
                return fetchedTokens.map({ token(of: $0) })
        }

        private func clearTemporaryDirectory() {
                guard let urls: [URL] = try? FileManager.default.contentsOfDirectory(at: .tmpDirectoryUrl, includingPropertiesForKeys: nil) else { return }
                _ = urls.map { try? FileManager.default.removeItem(at: $0) }
        }
}

private var presentingSheet: SheetSet = .about
private var tokenIndex: Int = 0

private enum SheetSet: Int {
        case about
        case export

        case scanQRCode
        case readQRCodeImage
        case enterManually

        case viewAccountDetail
        case editAccount
}
