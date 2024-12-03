import UIKit
import Combine

final class NewsCellViewModel {
    typealias Dependecies = HasImageRepository
    
    enum ImageState {
        case image(UIImage)
        case loading
        case notRequested
    }
    
    @Published
    private(set) var imageState: ImageState = .notRequested
    var selected = false
    let title: String
    let source: String
    
    let urlString: String
    private let imageURLString: String
    
    private let dependencies: Dependecies
    
    private var imageLoadCancellable: AnyCancellable?
    
    init(
        news: News,
        dependencies: Dependecies
    ) {
        self.title = news.title
        self.source = news.source
        self.imageURLString = news.imageURLString
        self.urlString = news.urlString
        self.dependencies = dependencies
    }
    
    func loadImage() {
        switch imageState {
        case .image:
            break
        case .notRequested, .loading:
            imageState = .loading
            
            imageLoadCancellable = dependencies.imageRepository
                .image(for: imageURLString)
                .sink { [weak self] image in
                    self?.imageState = .image(image)
                }
        }
    }
    
    func cancelLoad() {
        imageLoadCancellable?.cancel()
    }
}
