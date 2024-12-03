import Foundation
import Combine

enum NewsDataSourceError: Error {
    case failedToFetch
    case failedToDecode
}

protocol NewsDataSource {
    func fetchNews(from source: NewsSource) -> AnyPublisher<[News], Error>
}

protocol HasNewsDataSource {
    var newsDataSource: NewsDataSource { get }
}

struct BaseNewsDataSource: NewsDataSource {
    func fetchNews(from source: NewsSource) -> AnyPublisher<[News], Error> {
        URLSession.shared.dataTaskPublisher(for: source.url)
            .mapError { _ in NewsDataSourceError.failedToFetch }
            .flatMap { data, response in
                let parser = XMLParser(data: data)
            
                return Future<[News], Error>() { promise in
                    parser.delegate = NewsParserDelegate(source: source.sourceString) { promise(.success($0)) }
                    parser.parse()
                }
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}

struct News {
    let title: String
    let imageURLString: String
    let pubDate: Date
    let urlString: String
    let source: String
    
    var id: Int {
        title.hashValue
    }
}
