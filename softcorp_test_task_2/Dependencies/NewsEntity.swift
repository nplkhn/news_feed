import Foundation
import CoreData

@objc(NewsEntity)
public class NewsEntity: NSManagedObject {

}

extension NewsEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NewsEntity> {
        return NSFetchRequest<NewsEntity>(entityName: "NewsEntity")
    }

    @NSManaged public var id: Int64
    @NSManaged public var title: String
    @NSManaged public var pubDate: Double
    @NSManaged public var imageURLString: String
    @NSManaged public var urlString: String
    @NSManaged public var source: String

}

extension NewsEntity : Identifiable {

}
