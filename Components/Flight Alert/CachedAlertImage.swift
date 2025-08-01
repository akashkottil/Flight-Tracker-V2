import SwiftUI
import Combine

struct CachedAlertImage<Content: View, Placeholder: View>: View {
    private let alertData: AlertResponse?
    private let scale: CGFloat
    private let transaction: Transaction
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    
    @State private var loadedImage: UIImage? = nil
    @State private var isLoading: Bool = false
    
    init(
        alertData: AlertResponse?,
        scale: CGFloat = 1.0,
        transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.alertData = alertData
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
        .onChange(of: alertData?.id) { _ in
            loadImageIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .memoryPressure)) { _ in
            // Don't clear on memory pressure - we want to keep these images
            // as they're critical to the UI and relatively few in number
        }
    }
    
    private func loadImageIfNeeded() {
        guard let alertData = alertData, let imageUrl = alertData.image_url, let url = URL(string: imageUrl), !isLoading else { return }
        
        // First check if the alert has a cached image
        if let cachedAlertImage = alertData.getCachedImage() {
            loadedImage = cachedAlertImage
            return
        }
        
        // Then check the global image cache
        let cacheKey = url.absoluteString
        if let cachedImage = ImageCache.shared.image(forKey: cacheKey) {
            loadedImage = cachedImage
            // Also store in the alert-specific cache
            alertData.cacheImage(cachedImage)
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
            
            // Cache the image in both caches
            ImageCache.shared.setImage(image, forKey: cacheKey)
            alertData.cacheImage(image)
            
            DispatchQueue.main.async {
                withAnimation(transaction.animation) {
                    self.loadedImage = image
                    self.isLoading = false
                }
            }
        }.resume()
    }
}

// Convenience initializer with default placeholder
extension CachedAlertImage where Placeholder == AnyView {
    init(
        alertData: AlertResponse?,
        scale: CGFloat = 1.0,
        transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.init(
            alertData: alertData,
            scale: scale,
            transaction: transaction,
            content: content,
            placeholder: { 
                AnyView(
                    ZStack {
                        Color.gray.opacity(0.15)
                        ProgressView()
                    }
                )
            }
        )
    }
}