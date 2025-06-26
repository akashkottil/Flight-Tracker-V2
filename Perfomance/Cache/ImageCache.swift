//
//  ImageCache.swift
//  AllFlights
//
//  Created by Akash Kottil on 26/06/25.
//


// Create new file: Cache/ImageCache.swift
import UIKit
import Foundation

class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private lazy var cacheDirectory: URL = {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheURL = urls[0].appendingPathComponent("AirlineLogos")
        try? fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true)
        return cacheURL
    }()
    
    init() {
        cache.countLimit = 200
        cache.totalCostLimit = 30 * 1024 * 1024 // 30MB
        
        // Setup memory warning observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        cache.removeAllObjects()
    }
    
    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
        
        // Save to disk asynchronously
        DispatchQueue.global(qos: .background).async {
            let url = self.cacheDirectory.appendingPathComponent("\(key).png")
            if let data = image.pngData() {
                try? data.write(to: url)
            }
        }
    }
    
    func image(forKey key: String) -> UIImage? {
        // Check memory cache first
        if let image = cache.object(forKey: key as NSString) {
            return image
        }
        
        // Try loading from disk
        let url = cacheDirectory.appendingPathComponent("\(key).png")
        if let image = UIImage(contentsOfFile: url.path) {
            cache.setObject(image, forKey: key as NSString)
            return image
        }
        
        return nil
    }
    
    func clearCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}