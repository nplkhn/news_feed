import UIKit
import Combine

final class NewsCollectionViewCell: UICollectionViewCell {
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        return imageView
    }()
    
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        
        return label
    }()
    
    private let sourceLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
        label.textColor = .gray.withAlphaComponent(0.3)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        
        return label
    }()
    
    private var cancellables = Set<AnyCancellable>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews()
        constrainSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        titleLabel.text = nil
        cancellables.removeAll()
    }
    
    func configure(with viewModel: NewsCellViewModel) {
        titleLabel.text = viewModel.title
        titleLabel.textColor = viewModel.selected ? .gray : .black
        sourceLabel.text = viewModel.source
        
        viewModel.$imageState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .loading, .notRequested:
                    self?.activityIndicator.startAnimating()
                case let .image(image):
                    self?.activityIndicator.stopAnimating()
                    self?.imageView.image = image
                }
            }
            .store(in: &cancellables)
    }
}

private extension NewsCollectionViewCell {
    func addSubviews() {
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(sourceLabel)
        imageView.addSubview(activityIndicator)
    }
    
    func constrainSubviews() {
        imageView.snp.makeConstraints { make in
            make.verticalEdges.leading.equalToSuperview()
            make.width.equalTo(Constants.imageViewSideLenght).priority(.required)
            make.height.equalTo(Constants.imageViewSideLenght).priority(.required.advanced(by: -1))
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Constants.inset)
            make.bottom.lessThanOrEqualToSuperview().inset(Constants.inset)
            make.trailing.lessThanOrEqualToSuperview().inset(Constants.inset)
            make.leading.equalTo(imageView.snp.trailing).offset(Constants.inset)
            make.leading.greaterThanOrEqualToSuperview().offset(Constants.inset)
        }
        
        sourceLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.leading)
            make.top.equalTo(titleLabel.snp.bottom).offset(Constants.inset)
            make.trailing.lessThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview().inset(Constants.inset)
        }
    }
}

private extension NewsCollectionViewCell {
    enum Constants {
        static var inset: CGFloat { 8 }
        static var imageViewSideLenght: CGFloat { 90 }
    }
}
