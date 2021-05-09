import Foundation

extension String {

        /// Returns a new string made by removing spaces from both ends of the String.
        /// - Returns: A new string made by removing spaces from both ends of the String.
        func trimmingSpaces() -> String {
                trimmingCharacters(in: CharacterSet(charactersIn: " "))
        }
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
