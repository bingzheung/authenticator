import Foundation

struct Token: Hashable, Identifiable {
        
        let id: String
        let uri: String
        let type: TokenType
        let issuerPrefix: String?
        let accountName: String?
        let secret: String
        let issuer: String?
        let algorithm: Algorithm
        let digits: Int
        let period: Int
        
        var displayIssuer: String
        var displayAccountName: String
        
        init?(uri: String) {
                guard let url: URL = URL(string: uri) else { return nil }
                guard let components: URLComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
                guard components.scheme == "otpauth" else { return nil }
                guard components.host == "totp" else { return nil }
                guard let queryItems: [URLQueryItem] = components.queryItems else { return nil }
                
                guard let secretParameter: URLQueryItem = queryItems.filter({ $0.name.lowercased() == "secret" }).first else { return nil }
                guard let secretValue: String = secretParameter.value else { return nil }
                guard OTPGenerator.totp(secret: secretValue) != nil else { return nil }
                self.secret = secretValue
                
                if let issuerParameter: URLQueryItem = queryItems.filter({ $0.name.lowercased() == "issuer" }).first {
                        self.issuer = issuerParameter.value
                } else {
                        self.issuer = nil
                }
                
                if let algorithmParameter: URLQueryItem = queryItems.filter( { $0.name.lowercased() == "algorithm" }).first {
                        switch (algorithmParameter.value ?? "SHA1").uppercased() {
                        case "SHA1":
                                self.algorithm = .sha1
                        case "SHA256":
                                self.algorithm = .sha256
                        case "SHA512":
                                self.algorithm = .sha512
                        default:
                                self.algorithm = .sha1
                        }
                } else {
                        self.algorithm = .sha1
                }
                
                if let digitsParameter: URLQueryItem = queryItems.filter( { $0.name.lowercased() == "digits" }).first {
                        switch digitsParameter.value ?? "6" {
                        case "7":
                                self.digits = 7
                        case "8":
                                self.digits = 8
                        default:
                                self.digits = 6
                        }
                } else {
                        self.digits = 6
                }
                
                if let periodValue: String = queryItems.filter( { $0.name.lowercased() == "period" }).first?.value {
                        if let periodNumber = Int(periodValue) {
                                self.period = periodNumber > 0 ? periodNumber : 30
                        } else {
                                self.period = 30
                        }
                } else {
                        self.period = 30
                }
                
                var path: String = components.path
                while path.hasPrefix("/") {
                        path = String(path[path.index(path.startIndex, offsetBy: 1)...])
                }
                let pathcomponents: [String] = path.components(separatedBy: ":")
                switch pathcomponents.count {
                case 0:
                        issuerPrefix = nil
                        accountName = nil
                case 1:
                        issuerPrefix = nil
                        accountName = pathcomponents[0]
                case 2:
                        issuerPrefix = pathcomponents[0]
                        accountName = pathcomponents[1]
                default:
                        issuerPrefix = nil
                        accountName = nil
                }
                self.uri = uri
                self.type = .totp
                self.displayIssuer = self.issuerPrefix ?? .empty
                self.displayAccountName = self.accountName ?? .empty
                self.id = self.secret + Date().timeIntervalSince1970.description
                
                if self.displayIssuer.isEmpty && self.issuer.hasContent {
                        self.displayIssuer = issuer!
                }
        }
        
        init?(type: TokenType = .totp,
             issuerPrefix: String?,
             accountName: String?,
             secret: String,
             issuer: String?,
             algorithm: Algorithm = .sha1,
             digits: Int = 6,
             period: Int = 30) {
                
                guard OTPGenerator.totp(secret: secret) != nil else { return nil }
                
                let label: String = {
                        if issuerPrefix.hasContent && accountName.hasContent {
                                let text: String = "/" + issuerPrefix! + ":" + accountName!
                                let path: String = text.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? .empty
                                return path
                        } else if issuerPrefix.hasContent && !accountName.hasContent {
                                let text: String = "/" + issuerPrefix!
                                let path: String = text.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? .empty
                                return path
                        } else if !issuerPrefix.hasContent && accountName.hasContent {
                                let text: String = "/:" + accountName!
                                let path: String = text.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? .empty
                                return path
                        } else {
                                return .empty
                        }
                }()
                let issuerParameter: String = {
                        guard issuer.hasContent else { return .empty }
                        let query = issuer!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                        guard query.hasContent else { return .empty }
                        return "&issuer=\(query!)"
                }()
                let algorithmParameter: String = "&algorithm=\(algorithm)"
                let digitsParameter: String = "&digits=\(digits)"
                let periodParameter: String = "&period=\(period)"
                
                let uriString: String = "otpauth://\(type)\(label)?secret=\(secret)\(issuerParameter)\(algorithmParameter)\(digitsParameter)\(periodParameter)"
                guard let _ = URL(string: uriString) else { return nil }
                self.uri = uriString
                
                self.type = type
                self.issuerPrefix = issuerPrefix
                self.accountName = accountName
                self.secret = secret
                self.issuer = issuer
                self.algorithm = algorithm
                self.digits = digits
                self.period = period
                self.id = secret + Date().timeIntervalSince1970.description
                self.displayIssuer = issuerPrefix ?? issuer ?? .empty
                self.displayAccountName = accountName ?? .empty
        }
        
        /// Create Token with TokenData
        /// - Parameters:
        ///   - id: TokenData id
        ///   - uri: TokenData uri
        ///   - displayIssuer: TokenData displayIssuer
        ///   - displayAccountName: TokenData displayAccountName
        init?(id: String, uri: String, displayIssuer: String, displayAccountName: String) {
                guard let temp: Token = Token(uri: uri) else { return nil }
                self.id = id
                self.uri = uri
                self.type = temp.type
                self.issuerPrefix = temp.issuerPrefix
                self.accountName = temp.accountName
                self.secret = temp.secret
                self.issuer = temp.issuer
                self.algorithm = temp.algorithm
                self.digits = temp.digits
                self.period = temp.period
                self.displayIssuer = displayIssuer
                self.displayAccountName = displayAccountName
        }
        
        enum TokenType {
                case totp
        }

        enum Algorithm: String {
                case sha1 = "SHA1"
                case sha256 = "SHA256"
                case sha512 = "SHA512"
        }
}

extension Token {
        init() {
                self.init(uri: "otpauth://totp/Error:null?algorithm=SHA1&digits=6&issuer=Error&period=30&secret=LLKRKYOT7UCHSHPR")!
        }
}
