//
//  TempFlightPriceModels.swift
//  AllFlights
//
//  TEMPORARY FILE FOR DEVELOPMENT ONLY - REMOVE AFTER DEVELOPMENT
//

import Foundation

// MARK: - Temporary Price API Models
struct TempPriceResponse: Codable {
    let price_stats: TempPriceStats
    let results: [TempFlightResult]
}

struct TempPriceStats: Codable {
    let mean: Double
    let std_dev: Double
    let lower_threshold: Double
    let upper_threshold: Double
}

struct TempFlightResult: Codable {
    let date: Int
    let price: Double
    let currency: String
    let outbound: TempFlightSegment
    let inbound: TempFlightSegment
    let price_category: String
}

struct TempFlightSegment: Codable {
    let origin: TempAirport
    let destination: TempAirport
    let airline: TempAirline
    let departure: Int?
    let departure_datetime: String?
    let direct: Bool
}

struct TempAirport: Codable {
    let iata: String
    let name: String
    let country: String
}

struct TempAirline: Codable {
    let iata: String
    let name: String
    let logo: String
}

// MARK: - Temporary Network Service
class TempFlightPriceService {
    static let shared = TempFlightPriceService()
    private let baseURL = "https://staging.plane.lascade.com"
    private let csrfToken = "guiPex9fmT6ACSAeRgKZdfROC1nHP3ZgIGyiCWpEP3GsRgi1rF170zaCGOZAfPWc"
    
    private init() {}
    
    func fetchTempFlightPrice(origin: String, destination: String) async throws -> TempPriceResponse {
        guard let url = URL(string: "\(baseURL)/api/price/?currency=INR&country=IN") else {
            throw TempAPIError.invalidURL
        }
        
        let requestBody = TempPriceRequest(
            origin: origin,
            destination: destination,
            departure: "17-07-2025",
            round_trip: false
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(csrfToken, forHTTPHeaderField: "X-CSRFTOKEN")
        
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(requestBody)
            request.httpBody = jsonData
            
            print("🔧 [TEMP DEV] Making temporary price API call for \(origin) → \(destination)")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TempAPIError.invalidResponse
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw TempAPIError.serverError("Status: \(httpResponse.statusCode)")
            }
            
            let decoder = JSONDecoder()
            let tempResponse = try decoder.decode(TempPriceResponse.self, from: data)
            
            print("✅ [TEMP DEV] Received temporary price data: \(tempResponse.results.count) results")
            return tempResponse
            
        } catch {
            print("❌ [TEMP DEV] Temporary API call failed: \(error)")
            throw error
        }
    }
    
    // Convert temp response to CheapestFlight for compatibility
    func convertToCheapestFlight(_ tempResult: TempFlightResult) -> CheapestFlight {
        return CheapestFlight(
            id: Int.random(in: 10000...99999), // Random ID for temp data
            price: tempResult.price,
            price_category: tempResult.price_category,
            outbound_departure_timestamp: tempResult.date,
            outbound_departure_datetime: tempResult.outbound.departure_datetime,
            outbound_is_direct: tempResult.outbound.direct,
            inbound_departure_timestamp: nil,
            inbound_departure_datetime: nil,
            inbound_is_direct: nil,
            created_at: ISO8601DateFormatter().string(from: Date()),
            updated_at: ISO8601DateFormatter().string(from: Date()),
            route: 999 // Dummy route ID
        )
    }
}

struct TempPriceRequest: Codable {
    let origin: String
    let destination: String
    let departure: String
    let round_trip: Bool
}

enum TempAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .serverError(let message):
            return message
        }
    }
}
