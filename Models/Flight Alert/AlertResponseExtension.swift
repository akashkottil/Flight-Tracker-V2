import SwiftUI

// Extension to AlertResponse to handle cached images
extension AlertResponse {
    // Use a static dictionary to store images by alert ID
    private static var imageCache = [String: UIImage]()
    
    // Store an image for this alert
    func cacheImage(_ image: UIImage) {
        AlertResponse.imageCache[id] = image
    }
    
    // Retrieve cached image for this alert
    func getCachedImage() -> UIImage? {
        return AlertResponse.imageCache[id]
    }
    
    // Clear cached image for this alert
    func clearCachedImage() {
        AlertResponse.imageCache.removeValue(forKey: id)
    }
    
    // Clear all cached images
    static func clearAllCachedImages() {
        AlertResponse.imageCache.removeAll()
    }
}