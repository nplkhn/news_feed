import UIKit

struct PushParameters {
    var controller: UIViewController
    var animated: Bool
}

struct PresentParameters {
    var controller: UIViewController
    var animated: Bool
    var completion: (() -> Void)?
}

struct Router {
    var push: (PushParameters) -> Void
    var present: (PresentParameters) -> Void
}

extension Router {
    static func forPhone(_ navigationController: UINavigationController) -> Router {
        Router { [weak navigationController] parameters in
            navigationController?.pushViewController(
                parameters.controller,
                animated: parameters.animated
            )
        } present: { [weak navigationController] parameters in
            navigationController?.present(
                parameters.controller,
                animated: parameters.animated,
                completion: parameters.completion
            )
        }

    }
}

protocol HasRouter {
    var router: Router { get }
}
