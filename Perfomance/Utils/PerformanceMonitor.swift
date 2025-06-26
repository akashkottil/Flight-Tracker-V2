//
//  PerformanceMonitor.swift
//  AllFlights
//
//  Created by Akash Kottil on 26/06/25.
//


// Create new file: Utils/PerformanceMonitor.swift
import UIKit
import Foundation

class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()
    
    init() {
        setupMemoryWarning()
    }
    
    private func setupMemoryWarning() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.handleMemoryWarning()
        }
    }
    
    private func handleMemoryWarning() {
        print("⚠️ Memory warning received - clearing caches")
        APICache.shared.clearCache()
        ImageCache.shared.clearCache()
        
        // Notify views to reduce memory usage
        NotificationCenter.default.post(name: .memoryPressure, object: nil)
    }
}

extension Notification.Name {
    static let memoryPressure = Notification.Name("memoryPressure")
}