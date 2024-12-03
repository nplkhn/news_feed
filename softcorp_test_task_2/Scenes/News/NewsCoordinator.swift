import UIKit
import SafariServices

protocol HasNewsCoordinator {
    var newsCoordinator: NewsCoordinator { get }
}

protocol NewsCoordinator: Coordinator, AnyObject {
    func open(url: URL)
}

final class BaseNewsCoordinator: NewsCoordinator {
    let root: UIViewController
    
    lazy var viewController: NewsViewController = {
        let viewModel = BaseNewsViewModel(dependencies: dependencies, coordinator: self)
        let viewController = NewsViewController(viewModel: viewModel)
        
        return viewController
    }()
    
    private let router: Router
    private let dependencies: BaseNewsViewModel.Dependecies
    
    init(dependencies: BaseNewsViewModel.Dependecies) {
        self.dependencies = dependencies
        let navigationController = UINavigationController()
        navigationController.setNavigationBarHidden(true, animated: false)
        self.router = Router.forPhone(navigationController)
        root = navigationController
        navigationController.setViewControllers([viewController], animated: false)
    }
    
    func open(url: URL) {
        let configuration = SFSafariViewController.Configuration()
        configuration.barCollapsingEnabled = true
        configuration.activityButton = .none
        let viewController = SFSafariViewController(url: url, configuration: configuration)
        viewController.dismissButtonStyle = .close
        
        router.present(
            PresentParameters(
                controller: viewController,
                animated: true,
                completion: nil
            )
        )
    }
}
