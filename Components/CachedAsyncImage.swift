import SwiftUI
import Combine

// Renamed to avoid conflict with other implementations
struct GenericCachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let scale: CGFloat
    private let transaction: Transaction
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    
    @State private var loadedImage: UIImage? = nil
    @State private var isLoading: Bool = false
    
    init(
        url: URL?,
        scale: CGFloat = 1.0,
        transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.scale = scale
        self.transaction = transaction
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = loadedImage {
                content(Image(uiImage: image))
            } else {
                placeholder()
            }
        }
        .onAppear {
            loadImageIfNeeded()
        }
        .onChange(of: url) { _ in
            loadImageIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .memoryPressure)) { _ in
            // Clear memory cache on memory pressure
            if loadedImage != nil && url != nil {
                loadedImage = nil
            }
        }
    }
    
    private func loadImageIfNeeded() {
        guard let url = url, loadedImage == nil, !isLoading else { return }
        
        // Check cache first
        let cacheKey = url.absoluteString
        if let cachedImage = ImageCache.shared.image(forKey: cacheKey) {
            loadedImage = cachedImage
            return
        }
        
        isLoading = true
        
        // Load image asynchronously
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil,
                  let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            // Cache the image
            ImageCache.shared.setImage(image, forKey: cacheKey)
            
            DispatchQueue.main.async {
                withAnimation(transaction.animation) {
                    self.loadedImage = image
                    self.isLoading = false
                }
            }
        }.resume()
    }
}

// Convenience initializer with optional URL
extension GenericCachedAsyncImage where Placeholder == AnyView {
    init(
        url: URL?,
        scale: CGFloat = 1.0,
        transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.init(
            url: url,
            scale: scale,
            transaction: transaction,
            content: content,
            placeholder: { AnyView(ProgressView()) }
        )
    }
}