import Foundation
import SwiftOTP

struct OTPGenerator {
        static func totp(secret: String, algorithm: Token.Algorithm = .sha1, digits: Int = 6, period: Int = 30) -> String? {
                guard let data = SwiftOTP.base32DecodeToData(secret) else { return nil }
                let algo: OTPAlgorithm = {
                        switch algorithm {
                        case .sha1:
                                return .sha1
                        case .sha256:
                                return .sha256
                        case .sha512:
                                return .sha512
                        }
                }()
                guard let totp: SwiftOTP.TOTP = SwiftOTP.TOTP(secret: data, digits: digits, timeInterval: period, algorithm: algo) else { return nil }
                guard let totpText: String = totp.generate(time: Date()) else { return nil }
                return totpText
        }
}
