import Foundation
import Combine

protocol SettingsViewModel {
    var rates: [RefreshRate] { get }
    var currentRefreshRateString: AnyPublisher<String, Never> { get }
    
    func updateRefreshRate(_ rate: RefreshRate)
    func eraseStorage()
}

final class BaseSettingsViewModel: SettingsViewModel {
    typealias Dependencies = HasRefreshTimer & HasNewsRepository
    
    private let dependencies: Dependencies
    
    @Published
    private var currentRefreshRate: RefreshRate = RefreshRate.current
    var currentRefreshRateString: AnyPublisher<String, Never> {
        $currentRefreshRate
            .map(\.title)
            .eraseToAnyPublisher()
    }
    
    let rates: [RefreshRate] = RefreshRate.defaultRates
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    func updateRefreshRate(_ rate: RefreshRate) {
        dependencies.refreshTimer.setRefreshRate(to: rate)
        currentRefreshRate = rate
    }
    
    func eraseStorage() {
        dependencies.newsRepository.erase()
    }
}

extension RefreshRate {
    var title: String {
        switch self {
        case let .seconds(seconds): return "\(seconds) сек"
        case let .minutes(minutes): return "\(minutes) мин"
        }
    }
}
