import UIKit
import Combine
import SnapKit

final class NewsViewController: UIViewController {
    private let reuseIdentifier = String(describing: NewsCollectionViewCell.self)
    
    private lazy var collectionView: UICollectionView = {
        let configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )
        
        collectionView.register(NewsCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.showsVerticalScrollIndicator = false
        
        let refreshControl = UIRefreshControl(frame: .zero, primaryAction: UIAction(handler: { [weak self] _ in
            self?.viewModel.refresh()
        }))
        
        collectionView.refreshControl = UIRefreshControl()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        return collectionView
    }()
    
    private let viewModel: NewsViewModel
    
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: NewsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        
        tabBarItem.image = UIImage(systemName: "newspaper")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        
        viewModel.onViewDidLoad()
        
        viewModel.needsRelaod
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.collectionView.reloadData()
                self?.collectionView.refreshControl?.endRefreshing()
            }
            .store(in: &cancellables)
    }
}

extension NewsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.didSelectItem(at: indexPath)
        collectionView.reloadItems(at: [indexPath])
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        viewModel.willDisplayItem(at: indexPath)
    }
}

extension NewsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        
        if let cell = cell as? NewsCollectionViewCell {
            cell.configure(with: viewModel.viewModelForCell(at: indexPath))
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.numberOfItems
    }
}

