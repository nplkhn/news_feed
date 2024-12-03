import Foundation

final class NewsParserDelegate: NSObject, XMLParserDelegate {
    enum Environment {
        case out
        case outsideIn(OutEnvironment)
        case item
        case insideItem(ItemEnvironment)
        
        func inside(_ environment: ItemEnvironment) -> Environment {
            switch self {
            case .item, .insideItem:
                return .insideItem(environment)
            case .out, .outsideIn:
                return .out
            }
        }
        
        func outside(_ environment: OutEnvironment) -> Environment {
            switch self {
            case .out, .outsideIn:
                return .outsideIn(environment)
            case .item, .insideItem:
                return .out
            }
        }
    }
    
    enum OutEnvironment {
        case url
    }
    
    enum ItemEnvironment {
        case title
        case pubDate
        case desc
        case link
    }
    
    private(set) var entries = [Entry]()
    private var currentTitle: String?
    private var currentPubDate: Date?
    private var currentImageURLString: String?
    private var currentDesc: String?
    private var currentUrlString: String?
    private var placeholderImageURLString: String?
    
    private var currentlyProcessing: Environment = .out
    
    private lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
        
        return formatter
    }()
    
    struct Entry {
        let title: String
        let pubDate: Date
        let imageURLString: String
        let desc: String
        let urlString: String
        let source: String
    }
    
    private let source: String
    private let completion: ([News]) -> Void
    
    private var strongSelf: XMLParserDelegate?
    
    init(source: String, completion: @escaping ([News]) -> Void) {
        self.source = source
        self.completion = completion
        super.init()
        strongSelf = self
    }
    
    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String : String] = [:]
    ) {
        switch elementName {
        case "item": currentlyProcessing = .item
        case "title": currentlyProcessing = currentlyProcessing.inside(.title)
        case "pubDate": currentlyProcessing = currentlyProcessing.inside(.pubDate)
        case "description": currentlyProcessing = currentlyProcessing.inside(.desc)
        case "link": currentlyProcessing = currentlyProcessing.inside(.link)
        case "enclosure":
            currentImageURLString = attributeDict["url"]
        case "url": currentlyProcessing = currentlyProcessing.outside(.url)
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch currentlyProcessing {
        case .insideItem(.title):
            currentTitle = (currentTitle ?? "") + string.trimmingCharacters(in: .whitespacesAndNewlines)
            
        case .insideItem(.pubDate):
            currentPubDate = formatter.date(from: string)
        case .insideItem(.desc):
            currentDesc = (currentDesc ?? "") + string.trimmingCharacters(in: .whitespacesAndNewlines)
        case .insideItem(.link):
            currentUrlString = string
        case .outsideIn(.url):
            placeholderImageURLString = string
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch currentlyProcessing {
        case .out:
            break
        case .outsideIn:
            currentlyProcessing = .out
        case .item, .insideItem:
            currentlyProcessing = .item
        }
        
        if elementName == "item" {
            currentlyProcessing = .out
            
            saveEntry()
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        completion(
            entries.map {
                News(
                    title: $0.title,
                    imageURLString: $0.imageURLString,
                    pubDate: $0.pubDate,
                    urlString: $0.urlString,
                    source: $0.source
                )
            }
        )
        
        strongSelf = nil
    }
    
    func saveEntry() {
        defer {
            currentTitle = nil
            currentPubDate = nil
            currentImageURLString = nil
            currentDesc = nil
            currentUrlString = nil
        }
        
        guard let currentTitle,
              let currentPubDate,
              let currentUrlString else {
            return
        }
        
        entries.append(
            Entry(
                title: currentTitle,
                pubDate: currentPubDate,
                imageURLString: (currentImageURLString ?? placeholderImageURLString) ?? "",
                desc: currentDesc ?? "", 
                urlString: currentUrlString,
                source: source
            )
        )
    }
}
