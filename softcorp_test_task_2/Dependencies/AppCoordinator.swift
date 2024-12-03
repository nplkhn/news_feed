import UIKit

protocol Coordinator {
    var root: UIViewController { get }
}

protocol HasAppCoordinator {
    var appCoordinator: AppCoordinator { get }
}

struct AppCoordinator {
    private let dependencies: Dependecies
    
    let rootViewController: UIViewController
    private let newsCoordinator: Coordinator
    private let settingsCoordinator: Coordinator
    
    init() {
        let dependencies = DependencyContainer()
        self.dependencies = dependencies
        let viewController = UITabBarController()
        self.newsCoordinator = BaseNewsCoordinator(dependencies: dependencies)
        settingsCoordinator = SettingsCoordinator(dependencies: dependencies)
        viewController.viewControllers = [
            newsCoordinator.root,
            settingsCoordinator.root
        ]
        
        rootViewController = viewController
    }
}
