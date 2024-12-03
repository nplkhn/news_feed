import Foundation
import CoreData

typealias Dependecies = HasNewsDataSource & HasImageRepository & HasNewsDataStorage &
HasNewsRepository & HasRefreshTimer

class DependencyContainer: Dependecies {
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "softcorp_test_task_2")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    let newsDataSource: NewsDataSource = BaseNewsDataSource()
    
    let imageRepository: ImageRepository = BaseImageRepository()
    
    lazy var newsDataStorage: NewsDataStorage = CoreDataNewsDataStorage(persistanceContainer: persistentContainer)
    
    lazy var newsRepository: NewsRepository = BaseNewsRepository(
        sources: NewsSource.sources,
        storage: newsDataStorage,
        remoteSource: newsDataSource
    )
    
    lazy var refreshTimer: RefreshTimer = BaseRefreshTimer()
}
