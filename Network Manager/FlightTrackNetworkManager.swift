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
            
            // ENHANCED: Provide user-friendly error messages for airport searches
            switch httpResponse.statusCode {
            case 400:
                throw FlightTrackNetworkError.badRequest("Invalid search query. Please try a different airport name or code.")
            case 500:
                throw FlightTrackNetworkError.serverError("Airport search service is experiencing issues. Please try again later.")
            case 503:
                throw FlightTrackNetworkError.serviceUnavailable("Airport search is temporarily unavailable. Please try again later.")
            default:
                throw FlightTrackNetworkError.serverErrorCode(httpResponse.statusCode)
            }
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
            
            // ENHANCED: Provide user-friendly error messages for airline searches
            switch httpResponse.statusCode {
            case 400:
                throw FlightTrackNetworkError.badRequest("Invalid airline search query. Please try a different airline name or code.")
            case 500:
                throw FlightTrackNetworkError.serverError("Airline search service is experiencing issues. Please try again later.")
            case 503:
                throw FlightTrackNetworkError.serviceUnavailable("Airline search is temporarily unavailable. Please try again later.")
            default:
                throw FlightTrackNetworkError.serverErrorCode(httpResponse.statusCode)
            }
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
            
            // ENHANCED: Provide user-friendly error messages for schedule searches too
            switch httpResponse.statusCode {
            case 400:
                throw FlightTrackNetworkError.badRequest("Invalid airport or date selection. Please check your input.")
            case 404:
                throw FlightTrackNetworkError.flightNotFound("No flights found for the selected airport and date.")
            case 500:
                throw FlightTrackNetworkError.serverError("Flight schedule service is experiencing issues. Please try again later.")
            case 503:
                throw FlightTrackNetworkError.serviceUnavailable("Schedule data service is temporarily unavailable. Please try again later.")
            default:
                throw FlightTrackNetworkError.serverErrorCode(httpResponse.statusCode)
            }
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
    
    func fetchFlightDetail(flightNumber: String, date: String) async throws -> FlightDetailResponse {
        // Parse flight number to separate airline code and flight number
        let (airlineId, cleanFlightNumber) = parseFlightNumber(flightNumber)
        
        // Validate parsed components
        guard !airlineId.isEmpty && !cleanFlightNumber.isEmpty else {
            print("❌ Failed to parse flight number: \(flightNumber)")
            throw FlightTrackNetworkError.invalidURL
        }
        
        var urlComponents = URLComponents(string: "\(baseURL)/v2/flight/")!
        urlComponents.queryItems = [
            URLQueryItem(name: "airline_id", value: airlineId),
            URLQueryItem(name: "flight_number", value: cleanFlightNumber),
            URLQueryItem(name: "date", value: date)
        ]
        
        guard let url = urlComponents.url else {
            throw FlightTrackNetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.addValue("v3Yue9c38cnNCoD19M9mWxOdXHWoAyofjsRmKOzzMq0rZ2cp4yH2irOOdjG4SMqs", forHTTPHeaderField: "X-CSRFToken")
        request.addValue(authorization, forHTTPHeaderField: "Authorization")
        
        print("🌐 Flight Detail API URL: \(url)")
        print("📋 Original: '\(flightNumber)' → Airline: '\(airlineId)', Flight: '\(cleanFlightNumber)', Date: \(date)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FlightTrackNetworkError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            print("❌ Flight detail fetch failed with status: \(httpResponse.statusCode)")
            
            // Log response body for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("💥 Error response: \(responseString)")
            }
            
            // ENHANCED: Provide user-friendly error messages based on status code
            switch httpResponse.statusCode {
            case 400:
                throw FlightTrackNetworkError.badRequest("Invalid flight number or date. Please check your input.")
            case 404:
                throw FlightTrackNetworkError.flightNotFound("Flight \(flightNumber) not found for the selected date.")
            case 500:
                throw FlightTrackNetworkError.serverError("Server is experiencing issues. This might be due to external data provider problems. Please try again later.")
            case 503:
                throw FlightTrackNetworkError.serviceUnavailable("Flight data service is temporarily unavailable. Please try again later.")
            default:
                throw FlightTrackNetworkError.serverErrorCode(httpResponse.statusCode)  // FIXED: Use serverErrorCode for Int
            }
        }
        
        // ENHANCED: Better JSON decoding with detailed error handling
        do {
            // Create a JSON decoder with better error handling
            let decoder = JSONDecoder()
            
            // Log the raw JSON for debugging (only if decoding fails)
            let jsonString = String(data: data, encoding: .utf8) ?? "Unable to convert data to string"
            
            let flightDetailResponse = try decoder.decode(FlightDetailResponse.self, from: data)
            print("✅ Successfully decoded flight detail for \(flightNumber)")
            return flightDetailResponse
            
        } catch let DecodingError.typeMismatch(type, context) {
            print("❌ Type mismatch error:")
            print("   Expected type: \(type)")
            print("   Coding path: \(context.codingPath)")
            print("   Description: \(context.debugDescription)")
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw JSON response:")
                print(jsonString)
            }
            
            throw FlightTrackNetworkError.decodingError(DecodingError.typeMismatch(type, context))
            
        } catch let DecodingError.keyNotFound(key, context) {
            print("❌ Key not found error:")
            print("   Missing key: \(key)")
            print("   Coding path: \(context.codingPath)")
            print("   Description: \(context.debugDescription)")
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw JSON response:")
                print(jsonString)
            }
            
            throw FlightTrackNetworkError.decodingError(DecodingError.keyNotFound(key, context))
            
        } catch let DecodingError.valueNotFound(value, context) {
            print("❌ Value not found error:")
            print("   Expected value: \(value)")
            print("   Coding path: \(context.codingPath)")
            print("   Description: \(context.debugDescription)")
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw JSON response:")
                print(jsonString)
            }
            
            throw FlightTrackNetworkError.decodingError(DecodingError.valueNotFound(value, context))
            
        } catch let DecodingError.dataCorrupted(context) {
            print("❌ Data corrupted error:")
            print("   Coding path: \(context.codingPath)")
            print("   Description: \(context.debugDescription)")
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw JSON response:")
                print(jsonString)
            }
            
            throw FlightTrackNetworkError.decodingError(DecodingError.dataCorrupted(context))
            
        } catch {
            print("❌ General decoding error: \(error)")
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw JSON response:")
                print(jsonString)
            }
            
            throw FlightTrackNetworkError.decodingError(error)
        }
    }
    
    // COMPLETELY NEW PARSING METHOD - NO OLD CODE
    private func parseFlightNumber(_ flightNumber: String) -> (airlineId: String, flightNumber: String) {
        let input = flightNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        print("🔍 PARSING: '\(input)'")
        
        // STEP 1: Handle space-separated format (e.g., "6E 703")
        if input.contains(" ") {
            let components = input.components(separatedBy: " ")
            if components.count >= 2 && components[0].count == 2 {
                print("✅ SPACE FORMAT: '\(components[0])' + '\(components[1])'")
                return (airlineId: components[0], flightNumber: components[1])
            }
        }
        
        // STEP 2: Handle no-space format - ALWAYS split at position 2
        if input.count >= 3 {
            let airline = String(input.prefix(2))
            let flight = String(input.dropFirst(2))
            
            // Validate: airline must have at least 1 letter, flight must be all digits
            let airlineValid = airline.contains { $0.isLetter }
            let flightValid = flight.allSatisfy { $0.isNumber }
            
            if airlineValid && flightValid {
                print("✅ FIXED SPLIT: '\(airline)' + '\(flight)'")
                return (airlineId: airline, flightNumber: flight)
            } else {
                print("❌ VALIDATION FAILED: airline='\(airline)' (valid: \(airlineValid)), flight='\(flight)' (valid: \(flightValid))")
            }
        }
        
        // STEP 3: Cannot parse
        print("❌ CANNOT PARSE: '\(input)'")
        return (airlineId: "", flightNumber: input)
    }
    
    // MARK: - Test Method (Remove after testing)
    public func testFlightNumberParsing() {
        let testCases = [
            "6E 703",   // ✅ Should be: 6E, 703
            "6E703",    // ✅ Should be: 6E, 703
            "6E674",    // ✅ Should be: 6E, 674 (NOT 6E6, 74)
            "9I508",    // ✅ Should be: 9I, 508 (NOT 9I5, 08)
            "6E171",    // ✅ Should be: 6E, 171 (NOT 6E1, 71)
            "G9427",    // ✅ Should be: G9, 427 (NOT G, 9427)
            "3L126",    // ✅ Should be: 3L, 126 (NOT 3L1, 26)
            "UL 168",   // ✅ Should be: UL, 168
            "AI 131",   // ✅ Should be: AI, 131
            "IX493",    // ✅ Should be: IX, 493
        ]
        
        let separator = String(repeating: "=", count: 50)
        print("\n" + separator)
        print("🧪 FLIGHT NUMBER PARSING TEST")
        print(separator)
        
        for testCase in testCases {
            let (airline, flight) = parseFlightNumber(testCase)
            let status = airline.count == 2 ? "✅ PASS" : "❌ FAIL"
            print("\(status) '\(testCase)' → '\(airline)' + '\(flight)'")
        }
        
        print(separator + "\n")
    }
}

// MARK: - Network Errors
enum FlightTrackNetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverErrorCode(Int)          // ADDED: Renamed for clarity
    case serverError(String)           // ADDED: User-friendly server error
    case badRequest(String)            // ADDED: 400 Bad Request with message
    case flightNotFound(String)        // ADDED: 404 Flight not found
    case serviceUnavailable(String)    // ADDED: 503 Service unavailable
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .serverErrorCode(let code):
            return "Server error with code: \(code)"
        case .serverError(let message):
            return message
        case .badRequest(let message):
            return message
        case .flightNotFound(let message):
            return message
        case .serviceUnavailable(let message):
            return message
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}
