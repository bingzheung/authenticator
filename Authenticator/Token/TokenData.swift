import Foundation
import CoreData

@objc(TokenData)
public class TokenData: NSManagedObject { }

extension TokenData: Identifiable {
        
        @nonobjc public class func fetchRequest() -> NSFetchRequest<TokenData> {
                return NSFetchRequest<TokenData>(entityName: "TokenData")
        }
        
        @NSManaged public var indexNumber: Int64
        @NSManaged public var id: String
        @NSManaged public var uri: String
        @NSManaged public var displayIssuer: String
        @NSManaged public var displayAccountName: String
}
