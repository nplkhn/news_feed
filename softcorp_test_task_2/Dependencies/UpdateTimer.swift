import Foundation
import Combine

protocol RefreshTimer {
    var refreshSignalPublisher: AnyPublisher<Void, Never> { get }
    
    func setRefreshRate(to rate: RefreshRate)
}

protocol HasRefreshTimer {
    var refreshTimer: RefreshTimer { get }
}

final class BaseRefreshTimer: RefreshTimer {
    @Published
    private var timerPublisher: Timer.TimerPublisher
    
    var refreshSignalPublisher: AnyPublisher<Void, Never> {
        $timerPublisher
            .map { $0.autoconnect() }
            .switchToLatest()
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    init() {
        timerPublisher = Timer.publish(every: RefreshRate.current.rateInSeconds, on: .main, in: .common)
    }
    
    func setRefreshRate(to rate: RefreshRate) {
        RefreshRate.saveRate(rate)
        timerPublisher = Timer.publish(every: rate.rateInSeconds, on: .main, in: .common)
    }
}

private extension BaseRefreshTimer {
    
}

enum RefreshRate {
    case seconds(Int)
    case minutes(Int)
    
    static var current: RefreshRate {
        guard let rate = UserDefaults.standard.value(forKey: refreshRateKey) as? Double else {
            UserDefaults.standard.set(15, forKey: refreshRateKey)
            return .seconds(15)
        }
        
        return rate > 60 ? .minutes(Int(rate / 60)) : .seconds(Int(rate))
    }
    
    fileprivate static func saveRate(_ rate: RefreshRate) {
        UserDefaults.standard.setValue(rate.rateInSeconds, forKey: refreshRateKey)
    }
    
    private static var refreshRateKey: String { "refresh-rate" }
    
    static var defaultRates: [RefreshRate] {
        [
            .seconds(15),
            .seconds(30),
            .minutes(1),
            .minutes(5)
        ]
    }
}

private extension RefreshRate {
    var rateInSeconds: Double {
        switch self {
        case let .seconds(seconds): return Double(seconds)
        case let .minutes(minutes): return 60 * Double(minutes)
        }
    }
}
