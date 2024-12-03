import Foundation

enum NewsSource: Decodable {
    case vedomostiAll
    case rbc
}

extension NewsSource {
    var url: URL {
        switch self {
        case .rbc:
            return URL(string: "http://static.feed.rbc.ru/rbc/internal/rss.rbc.ru/rbc.ru/news.rss")!
        case .vedomostiAll:
            return URL(string: "https://www.vedomosti.ru/rss/news.xml")!
        }
    }
    
    var sourceString: String {
        switch self {
        case .rbc: return "РБК"
        case .vedomostiAll: return "Ведомости"
        }
    }
}

extension NewsSource {
    static var sources: [NewsSource] {
        [.rbc, .vedomostiAll]
    }
}
