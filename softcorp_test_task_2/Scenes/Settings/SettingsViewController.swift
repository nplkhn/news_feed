import UIKit
import Combine

class SettingsViewController: UIViewController {
    
    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        
        return view
    }()
    
    private let stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.distribution = .equalSpacing
        view.alignment = .fill
        view.spacing = Constants.spacing
        
        return view
    }()
    
    private let timerContainerView: UIButton = {
        let view = UIButton()
        view.backgroundColor = .gray.withAlphaComponent(0.3)
        view.layer.cornerRadius = Constants.cornerRadius
        view.showsMenuAsPrimaryAction = true
        
        return view
    }()
    
    private let timerDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.timerDescriptionText
        
        return label
    }()
    
    private let timerValueLabel = UILabel()
    
    private let eraseStorageButton: UIButton = {
        let button = UIButton()
        button.setTitle(Constants.eraseButtonTitle, for: .normal)
        button.layer.cornerRadius = Constants.cornerRadius
        button.backgroundColor = .gray.withAlphaComponent(0.3)
        
        return button
    }()
    
    let viewModel: SettingsViewModel
    
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        tabBarItem.image = Constants.tabBarItemImage
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        addSubviews()
        constrainSubviews()
        
        let action: (RefreshRate) -> Void = { [weak self] rate in
            self?.viewModel.updateRefreshRate(rate)
        }
        
        timerContainerView.menu = UIMenu(children: viewModel.rates.map { rate in
            UIAction(title: rate.title) { _ in
                action(rate)
            }
        })
        
        viewModel.currentRefreshRateString
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rate in
                self?.timerValueLabel.text = rate
            }
            .store(in: &cancellables)
        
        eraseStorageButton.addTarget(self, action: #selector(eraseStorage), for: .touchUpInside)
    }
}

private extension SettingsViewController {
    func addSubviews() {
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        
        timerContainerView.addSubview(timerDescriptionLabel)
        timerContainerView.addSubview(timerValueLabel)
        
        stackView.addArrangedSubview(timerContainerView)
        stackView.addArrangedSubview(eraseStorageButton)
    }
    
    func constrainSubviews() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        stackView.snp.makeConstraints { make in
            make.top.equalTo(scrollView.safeAreaLayoutGuide.snp.top).inset(Constants.halfInset)
            make.horizontalEdges.equalTo(scrollView.safeAreaLayoutGuide.snp.horizontalEdges).inset(Constants.halfInset)
            make.bottom.lessThanOrEqualTo(scrollView.safeAreaLayoutGuide.snp.bottom).inset(Constants.halfInset)
            make.width.equalToSuperview().inset(Constants.halfInset)
        }
        
        timerDescriptionLabel.snp.makeConstraints { make in
            make.leading.verticalEdges.equalToSuperview().inset(Constants.inset)
        }
        
        timerValueLabel.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualTo(timerDescriptionLabel.snp.trailing)
            make.verticalEdges.trailing.equalToSuperview().inset(Constants.inset)
        }
        
        eraseStorageButton.snp.makeConstraints { make in
            make.height.equalTo(timerContainerView.snp.height)
        }
    }
}

@objc
extension SettingsViewController {
    func eraseStorage() {
        viewModel.eraseStorage()
    }
}

private extension SettingsViewController {
    enum Constants {
        static var cornerRadius: CGFloat { 16 }
        static var inset: CGFloat { 16 }
        static var halfInset: CGFloat { 8 }
        static var spacing: CGFloat { 8 }
        
        static var eraseButtonTitle: String { "Очистить хранилище" }
        static var timerDescriptionText: String { "Обновлять новости через каждые:" }
        
        static var tabBarItemImage: UIImage? { UIImage(systemName: "gear") }
    }
}
