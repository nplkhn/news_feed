import UIKit
import Combine

protocol NewsViewModel {
    var numberOfItems: Int { get }
    var needsRelaod: AnyPublisher<Void, Never> { get }
    
    func onViewDidLoad()
    func refresh()
    func didSelectItem(at indexPath: IndexPath)
    func willDisplayItem(at indexPath: IndexPath)
    func viewModelForCell(at indexPath: IndexPath) -> NewsCellViewModel
}

final class BaseNewsViewModel: NewsViewModel {
    typealias Dependecies = HasNewsRepository & HasImageRepository & HasRefreshTimer
    
    var numberOfItems: Int { news.count }
    var needsRelaod: AnyPublisher<Void, Never> {
        $news.map { _ in () }.eraseToAnyPublisher()
    }
    
    @Published
    private var news = [NewsCellViewModel]()
    private var newsIds = Set<Int>()
    
    private var loadNewsCancellable: AnyCancellable?
    private var refreshNewsWithTimerCancellable: AnyCancellable?
    
    private let dependencies: Dependecies
    private weak var coordinator: NewsCoordinator?
    
    init(
        dependencies: Dependecies,
        coordinator: NewsCoordinator?
    ) {
        self.dependencies = dependencies
        self.coordinator = coordinator
    }
    
    func onViewDidLoad() {
        loadNewsCancellable = fetchNewsPublisher(refresh: false)
            .sink { completion in
            } receiveValue: { [weak self] news in
                guard let self else { return }
                
                store(news: news)
            }
        
        refreshNewsWithTimerCancellable = dependencies.refreshTimer
            .refreshSignalPublisher
            .flatMap { [unowned self] in
                self.fetchNewsPublisher(refresh: true)
            }
            .sink { completion in
            } receiveValue: { [weak self] news in
                guard let self else { return }
                
                store(news: news)
            }

    }
    
    func refresh() {
        loadNewsCancellable = fetchNewsPublisher(refresh: true)
            .sink { completion in
                
            } receiveValue: { [weak self] news in
                guard let self else { return }
                
                store(news: news)
            }
    }
    
    func didSelectItem(at indexPath: IndexPath) {
        let item = news[indexPath.item]
        guard let url = URL(string: item.urlString) else { return }
        
        item.selected = true
        coordinator?.open(url: url)
    }
    
    func willDisplayItem(at indexPath: IndexPath) {
        news[indexPath.item].loadImage()
    }
    
    func viewModelForCell(at indexPath: IndexPath) -> NewsCellViewModel {
        news[indexPath.item]
    }
}

private extension BaseNewsViewModel {
    func fetchNewsPublisher(refresh: Bool) -> AnyPublisher<[News], Error> {
        dependencies.newsRepository
            .fetchNews(refresh: refresh)
    }
    
    func store(news: [News]) {
        var mutableNews = self.news
        var newNews = news.filter { !newsIds.contains($0.id) }
        newsIds = newsIds.union(Set(newNews.map(\.id)))
        var cellVMs = newNews
            .sorted { $0.pubDate > $1.pubDate }
            .map {
                NewsCellViewModel(
                    news: $0,
                    dependencies: dependencies
                )
            }
        mutableNews.insert(contentsOf: cellVMs, at: 0)
        
        self.news = mutableNews
        
    }
}
