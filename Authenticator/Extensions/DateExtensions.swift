import Foundation

extension Date {
        private static let formatter: DateFormatter = {
                let formatter: DateFormatter = DateFormatter()
                formatter.dateFormat = "yyyyMMdd-HHmmss"
                return formatter
        }()
        static var currentDateText: String {
                return Date.formatter.string(from: Date())
        }
}
