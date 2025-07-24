//
//  DevelopmentConfig.swift
//  AllFlights
//
//  Created by Akash Kottil on 17/07/25.
//


//
//  DevelopmentConfig.swift
//  AllFlights
//
//  TEMPORARY FILE FOR DEVELOPMENT ONLY - REMOVE AFTER DEVELOPMENT
//

import Foundation

struct DevelopmentConfig {
    
    // MARK: - 🚧 TEMPORARY DEVELOPMENT FLAGS 🚧
    // TODO: REMOVE THESE AFTER DEVELOPMENT IS COMPLETE
    
    /// Enable temporary flight price API when cheapest_flight is null
    /// Set to `false` in production or when real API is ready
    static let useTempFlightPriceAPI = true
    
    /// Enable debug logging for temporary features
    static let enableTempDebugLogging = true
    
    /// Mock price drop amount for development
    static let mockPriceDrop: Double = 1500.0
    
    // MARK: - Helper Methods
    
    static func logTempFeature(_ message: String) {
        if enableTempDebugLogging {
            print("🔧 [TEMP DEV] \(message)")
        }
    }
    
    static func shouldUseTempAPI() -> Bool {
        return useTempFlightPriceAPI
    }
}