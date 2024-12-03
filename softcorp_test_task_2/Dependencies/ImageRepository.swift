import UIKit
import Combine

protocol ImageRepository {
    func image(for source: String) -> AnyPublisher<UIImage, Never>
}

protocol HasImageRepository {
    var imageRepository: ImageRepository { get }
}

struct BaseImageRepository: ImageRepository {
    private let remoteDataSource: ImageDataSource
    private let localDataSource: ImageDataStorage
    
    init(
        remoteDataSource: ImageDataSource = RemoteImageDataSource(),
        localDataSource: ImageDataStorage = LocalImageDataSource()
    ) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
    }
    
    func image(for source: String) -> AnyPublisher<UIImage, Never> {
        guard let url = URL(string: source) else {
            return Just(UIImage()).eraseToAnyPublisher()
        }
        
        return localDataSource
            .image(for: url)
            .catch { _ in
                remoteDataSource
                    .image(for: url)
                    .handleEvents(receiveOutput: { image in
                        localDataSource.saveImage(image, for: url)
                    })
            }
            .replaceError(with: UIImage())
            .eraseToAnyPublisher()
    }
}

protocol ImageDataSource {
    func image(for url: URL) -> AnyPublisher<UIImage, Error>
}

protocol ImageDataStorage: ImageDataSource {
    func saveImage(_ image: UIImage, for source: URL)
}

private struct RemoteImageDataSource: ImageDataSource {
    
    func image(for url: URL) -> AnyPublisher<UIImage, Error> {
        URLSession.shared
            .dataTaskPublisher(for: url)
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .mapError { $0 as Error }
            .compactMap { data, _ in UIImage(data: data)?.resize(360, 360) }
            .eraseToAnyPublisher()
    }
}

private class LocalImageDataSource: ImageDataStorage {
    let cache: NSCache<NSNumber, UIImage> = {
        let cache: NSCache<NSNumber, UIImage>  = NSCache()
        cache.totalCostLimit = 50 * 1024 * 1024
        
        return cache
    }()
    
    private let lock = NSLock()
    
    func saveImage(
        _ image: UIImage,
        for source: URL
    ) {
        lock.lock()
        cache.setObject(image, forKey: source.hashValue as NSNumber)
        lock.unlock()
    }
    
    func image(for url: URL) -> AnyPublisher<UIImage, Error> {
        guard let image = cache.object(forKey: url.hashValue as NSNumber) else {
            return Fail(error: NSError(domain: "Could not find image", code: -1))
                .eraseToAnyPublisher()
        }
        
        return Just(image)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

import AVFoundation
private extension UIImage {
    func resize(_ width: Int, _ height: Int) -> UIImage {
            // Keep aspect ratio
            let maxSize = CGSize(width: width, height: height)

            let availableRect = AVFoundation.AVMakeRect(
                aspectRatio: size,
                insideRect: .init(origin: .zero, size: maxSize)
            )
            let targetSize = availableRect.size

            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)

            let resized = renderer.image { _ in
                self.draw(in: CGRect(origin: .zero, size: targetSize))
            }

            return resized
        }
}
