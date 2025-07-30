//
//  AlertRequest.swift
//  AllFlights
//
//  Created by Akash Kottil on 30/06/25.
//

// Models/AlertModels.swift
import Foundation

// MARK: - Alert Request Models
struct AlertRequest: Codable {
    let user: AlertUser
    let route: AlertRoute
}

struct AlertUser: Codable {
    let id: String
    let push_token: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case push_token
    }
}

struct AlertRoute: Codable {
    let origin: String
    let destination: String
    let currency: String
    let origin_name: String
    let destination_name: String
    
    enum CodingKeys: String, CodingKey {
        case origin
        case destination
        case currency
        case origin_name
        case destination_name
    }
}

// MARK: - Alert Response Models
struct AlertResponse: Codable, Identifiable {
    let id: String
    let user: AlertUserResponse
    let route: AlertRouteResponse
    let cheapest_flight: CheapestFlight?
    let image_url: String?
    let target_price: Double?
    let last_notified_price: Double?
    let created_at: String
    let updated_at: String
    
    
    let stored_adults_count: Int?
    let stored_children_count: Int?
    let stored_cabin_class: String?
    
    enum CodingKeys: String, CodingKey {
        case id, user, route
        case cheapest_flight
        case image_url
        case target_price
        case last_notified_price
        case created_at
        case updated_at
        case stored_adults_count    // ADD THIS
        case stored_children_count  // ADD THIS
        case stored_cabin_class     // ADD THIS
    }
}

struct AlertUserResponse: Codable {
    let id: String
    let push_token: String
    let created_at: String
    let updated_at: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case push_token
        case created_at
        case updated_at
    }
}

struct AlertRouteResponse: Codable {
    let id: Int
    let origin: String
    let destination: String
    let currency: String
    let origin_name: String
    let destination_name: String
    let created_at: String
    let updated_at: String
    
    enum CodingKeys: String, CodingKey {
        case id, origin, destination, currency
        case origin_name
        case destination_name
        case created_at
        case updated_at
    }
}

struct CheapestFlight: Codable {
    let id: Int
    let price: Double
    let price_category: String
    let outbound_departure_timestamp: Int?
    let outbound_departure_datetime: String?
    let outbound_is_direct: Bool?
    let inbound_departure_timestamp: Int?
    let inbound_departure_datetime: String?
    let inbound_is_direct: Bool?
    let created_at: String
    let updated_at: String
    let route: Int
    
    enum CodingKeys: String, CodingKey {
        case id, price
        case price_category
        case outbound_departure_timestamp
        case outbound_departure_datetime
        case outbound_is_direct
        case inbound_departure_timestamp
        case inbound_departure_datetime
        case inbound_is_direct
        case created_at
        case updated_at
        case route
    }
}

// MARK: - API Response Wrapper (for paginated responses)
struct FlightAlertsWrapper: Codable {
    let results: [AlertResponse]
    let count: Int?
    let next: String?
    let previous: String?
}

// MARK: - Alert Network Error
enum AlertNetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(String)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .serverError(let message):
            return message
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}
