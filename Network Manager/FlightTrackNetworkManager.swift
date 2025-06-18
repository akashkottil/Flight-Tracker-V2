// NetworkManagers/FlightTrackNetworkManager.swift
import Foundation

class FlightTrackNetworkManager {
    static let shared = FlightTrackNetworkManager()
    private let baseURL = "https://staging.flight.lascade.com/api"
    private let authorization = "TheAllPowerfulKingOf7SeasAnd5LandsAkbarTheGreatCommandsTheAPIToWork"
    
    private init() {}
    
    func searchAirports(query: String) async throws -> FlightTrackAirportResponse {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/v1/airports/?search=\(encodedQuery)") else {
            throw FlightTrackNetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.addValue("v3Yue9c38cnNCoD19M9mWxOdXHWoAyofjsRmKOzzMq0rZ2cp4yH2irOOdjG4SMqs", forHTTPHeaderField: "X-CSRFToken")
        request.addValue(authorization, forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FlightTrackNetworkError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            print("Airport search failed with status: \(httpResponse.statusCode)")
            throw FlightTrackNetworkError.serverError(httpResponse.statusCode)
        }
        
        do {
            let airportResponse = try JSONDecoder().decode(FlightTrackAirportResponse.self, from: data)
            print("Successfully decoded \(airportResponse.results.count) airports")
            return airportResponse
        } catch {
            print("Airport decoding error: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON response: \(jsonString)")
            }
            throw FlightTrackNetworkError.decodingError(error)
        }
    }
    
    func searchAirlines(query: String) async throws -> AirlineResponse {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/v1/airlines/?search=\(encodedQuery)") else {
            throw FlightTrackNetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.addValue("v3Yue9c38cnNCoD19M9mWxOdXHWoAyofjsRmKOzzMq0rZ2cp4yH2irOOdjG4SMqs", forHTTPHeaderField: "X-CSRFToken")
        request.addValue(authorization, forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FlightTrackNetworkError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            print("Airline search failed with status: \(httpResponse.statusCode)")
            throw FlightTrackNetworkError.serverError(httpResponse.statusCode)
        }
        
        do {
            let airlineResponse = try JSONDecoder().decode(AirlineResponse.self, from: data)
            print("Successfully decoded \(airlineResponse.results.count) airlines")
            return airlineResponse
        } catch {
            print("Airline decoding error: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON response: \(jsonString)")
            }
            throw FlightTrackNetworkError.decodingError(error)
        }
    }
    
    func searchSchedules(departureId: String? = nil, arrivalId: String? = nil, date: String? = nil) async throws -> ScheduleResponse {
        var urlComponents = URLComponents(string: "\(baseURL)/v2/schedules/")!
        var queryItems: [URLQueryItem] = []
        
        if let departureId = departureId {
            queryItems.append(URLQueryItem(name: "dep_id", value: departureId))
        }
        
        if let arrivalId = arrivalId {
            queryItems.append(URLQueryItem(name: "arr_id", value: arrivalId))
        }
        
        if let date = date {
            queryItems.append(URLQueryItem(name: "date", value: date))
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw FlightTrackNetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.addValue("v3Yue9c38cnNCoD19M9mWxOdXHWoAyofjsRmKOzzMq0rZ2cp4yH2irOOdjG4SMqs", forHTTPHeaderField: "X-CSRFToken")
        request.addValue(authorization, forHTTPHeaderField: "Authorization")
        
        print("Schedule API URL: \(url)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FlightTrackNetworkError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            print("Schedule search failed with status: \(httpResponse.statusCode)")
            throw FlightTrackNetworkError.serverError(httpResponse.statusCode)
        }
        
        do {
            let scheduleResponse = try JSONDecoder().decode(ScheduleResponse.self, from: data)
            print("Successfully decoded \(scheduleResponse.results.count) schedule results")
            return scheduleResponse
        } catch {
            print("Schedule decoding error: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON response: \(jsonString)")
            }
            throw FlightTrackNetworkError.decodingError(error)
        }
    }
}

// MARK: - Network Errors
enum FlightTrackNetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .serverError(let code):
            return "Server error with code: \(code)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}
