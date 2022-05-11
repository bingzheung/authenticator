import Foundation

extension String {

        /// Returns a new string made by removing `.whitespacesAndNewlines` & `.controlCharacters` from both ends of the String.
        /// - Returns: A new string made by removing `.whitespacesAndNewlines` & `.controlCharacters` from both ends of the String.
        func trimmed() -> String {
                return trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: .controlCharacters)
        }

        /// aka. `String.init()`
        static let empty: String = ""

        /// Six zeros
        static let zeros: String = "000000"
}

extension Optional where Wrapped == String {

        /// Not nil && not empty
        var hasContent: Bool {
                switch self {
                case .none:
                        return false
                case .some(let value):
                        return !value.isEmpty
                }
        }
}
