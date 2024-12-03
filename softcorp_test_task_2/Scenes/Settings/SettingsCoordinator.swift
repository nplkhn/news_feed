import UIKit

struct SettingsCoordinator: Coordinator {
    let root: UIViewController
    
    init(dependencies: BaseSettingsViewModel.Dependencies) {
        let viewModel = BaseSettingsViewModel(dependencies: dependencies)
        root = SettingsViewController(viewModel: viewModel)
    }
}
