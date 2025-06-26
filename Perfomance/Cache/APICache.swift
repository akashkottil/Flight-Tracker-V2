//
//  APICache.swift
//  AllFlights
//
//  Created by Akash Kottil on 26/06/25.
//


// Create new file: Cache/APICache.swift
import Foundation

class APICache {
    static let shared = APICache()
    private let cache = NSCache<NSString, NSData>()
    private let requestCache = NSCache<NSString, AnyObject>()
    
    init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    func cacheResponse(_ data: Data, for key: String, ttl: TimeInterval = 300) {
        let cacheItem = CacheItem(data: data, expiry: Date().addingTimeInterval(ttl))
        if let encoded = try? JSONEncoder().encode(cacheItem) {
            cache.setObject(encoded as NSData, forKey: key as NSString)
        }
    }
    
    func getCachedResponse(for key: String) -> Data? {
        guard let data = cache.object(forKey: key as NSString) as Data?,
              let item = try? JSONDecoder().decode(CacheItem.self, from: data),
              item.expiry > Date() else {
            cache.removeObject(forKey: key as NSString)
            return nil
        }
        return item.data
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}

private struct CacheItem: Codable {
    let data: Data
    let expiry: Date
}