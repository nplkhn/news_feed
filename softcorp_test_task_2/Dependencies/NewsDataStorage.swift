import Foundation
import CoreData
import Combine

protocol NewsDataStorage {
    func save(news: [News])
    func save()
    func fetchNews() -> AnyPublisher<[News], Error>
    func erase()
}

protocol HasNewsDataStorage {
    var newsDataStorage: NewsDataStorage { get }
}

final class CoreDataNewsDataStorage: NewsDataStorage {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    init(persistanceContainer: NSPersistentContainer) {
        self.container = persistanceContainer
        context = persistanceContainer.viewContext
    }
    
    func save(news: [News]) {
        container.performBackgroundTask { [weak self] context in
            guard let self else { return }
            
            var exisitingIds = Set(fetch(context: context).map(\.id))
            
            for item in news where !exisitingIds.contains(item.id) {
                autoreleasepool {
                    let entity = NewsEntity(context: context)
                    entity.id = Int64(item.title.hashValue)
                    entity.title = item.title
                    entity.pubDate = item.pubDate.timeIntervalSince1970
                    entity.imageURLString = item.imageURLString
                    entity.urlString = item.urlString
                    entity.source = item.source
                    
                    context.insert(entity)
                }
            }
            
        }
        
        save(context: context)
    }
    
    func save() {
        save(context: context)
    }
    
    private func save(context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func fetchNews() -> AnyPublisher<[News], Error> {
        return Just(fetch())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    private func fetch() -> [News] {
        fetch(context: context)
    }
    
    private func fetch(context: NSManagedObjectContext) -> [News] {
        let fetchRequest = NewsEntity.fetchRequest()
        let fetchResult = (try? context.fetch(fetchRequest)) ?? []
        let result = fetchResult.map {
            News(
                title: $0.title,
                imageURLString: $0.imageURLString,
                pubDate: Date(timeIntervalSince1970: $0.pubDate),
                urlString: $0.urlString,
                source: $0.source
            )
        }
        
        return result
    }
    
    func erase() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "NewsEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            let result = try context.execute(deleteRequest)
            print(result)
        } catch {
            print(error.localizedDescription)
        }
    }
}
