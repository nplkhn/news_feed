import Foundation
import Combine

protocol NewsRepository {
    func fetchNews(refresh: Bool) -> AnyPublisher<[News], Error>
    func save()
    func erase()
}

protocol HasNewsRepository {
    var newsRepository: NewsRepository { get }
}

struct BaseNewsRepository: NewsRepository {
    let sources: [NewsSource]
    let storage: NewsDataStorage
    let remoteSource: NewsDataSource
    
    func fetchNews(refresh: Bool) -> AnyPublisher<[News], Error> {
        guard refresh else {
            return storage.fetchNews()
                .merge(with: fetchRemote())
                .map { (news: [News]) in
                    var exisitingIds = Set<Int>()
                    var result = [News]()
                    for item in news {
                        if !exisitingIds.contains(item.id) {
                            result.append(item)
                            exisitingIds.insert(item.id)
                        }
                    }
                    
                    return result
                }
                .eraseToAnyPublisher()
        }
        
        return fetchRemote()
    }
    
    func fetchRemote() -> AnyPublisher<[News], Error> {
        Publishers.MergeMany(sources.map { remoteSource.fetchNews(from: $0) })
            .collect()
            .map { $0.flatMap { $0 } }
            .handleEvents(receiveOutput: { storage.save(news: $0) })
            .eraseToAnyPublisher()
    }
    
    func save() {
        storage.save()
    }
    
    func erase() {
        storage.erase()
    }
}
