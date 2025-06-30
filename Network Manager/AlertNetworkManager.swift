// Network Manager/AlertNetworkManager.swift
import Foundation

class AlertNetworkManager {
    static let shared = AlertNetworkManager()
    private let baseURL = "https://staging.plane.lascade.com"
    
    // Constants that can be changed for future updates
    private let userId = "testId"
    private let pushToken = "demoToken26"
    private let csrfToken = "g80IzPxrebHNaYKEviBKhFZ3vcTgWBPCIkgbXeNQHlhFpmsr5HSS4ZiRzZv9mnMy"
    
    private init() {}
    
    // MARK: - Fetch Existing Alerts (Multiple Strategies)
    
    func fetchAlerts() async throws -> [AlertResponse] {
        print("🔍 Trying multiple strategies to fetch alerts...")
        
        // Strategy 1: Try with user query parameter
        do {
            let alerts = try await fetchAlertsWithUserFilter()
            if !alerts.isEmpty {
                return alerts
            }
        } catch {
            print("⚠️ Strategy 1 (user filter) failed: \(error)")
        }
        
        // Strategy 2: Try different endpoint variations
        let endpointVariations = [
            "/api/alerts/list/",
            "/api/user/alerts/",
            "/api/alerts/user/\(userId)/",
            "/api/v1/alerts/",
            "/api/alerts/get/"
        ]
        
        for endpoint in endpointVariations {
            do {
                let alerts = try await fetchAlertsFromEndpoint(endpoint)
                if !alerts.isEmpty {
                    print("✅ Successfully fetched alerts from: \(endpoint)")
                    return alerts
                }
            } catch {
                print("⚠️ Endpoint \(endpoint) failed: \(error)")
            }
        }
        
        // Strategy 3: Try POST request to query alerts
        do {
            let alerts = try await fetchAlertsWithPOST()
            return alerts
        } catch {
            print("⚠️ POST query strategy failed: \(error)")
        }
        
        // If all strategies fail, return empty array
        print("❌ All fetch strategies failed, returning empty alerts")
        return []
    }
    
    // MARK: - Strategy 1: Fetch with User Filter
    
    private func fetchAlertsWithUserFilter() async throws -> [AlertResponse] {
        guard let url = URL(string: "\(baseURL)/api/alerts/?user_id=\(userId)") else {
            throw AlertNetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.addValue(csrfToken, forHTTPHeaderField: "X-CSRFToken")
        
        print("🔍 Strategy 1: Fetching alerts with user filter: \(url)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AlertNetworkError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            print("❌ User filter strategy failed with status: \(httpResponse.statusCode)")
            throw AlertNetworkError.serverError("Status: \(httpResponse.statusCode)")
        }
        
        return try parseAlertsResponse(data: data)
    }
    
    // MARK: - Strategy 2: Try Different Endpoints
    
    private func fetchAlertsFromEndpoint(_ endpoint: String) async throws -> [AlertResponse] {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw AlertNetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.addValue(csrfToken, forHTTPHeaderField: "X-CSRFToken")
        
        print("🔍 Trying endpoint: \(url)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AlertNetworkError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw AlertNetworkError.serverError("Status: \(httpResponse.statusCode)")
        }
        
        return try parseAlertsResponse(data: data)
    }
    
    // MARK: - Strategy 3: POST Request to Query Alerts
    
    private func fetchAlertsWithPOST() async throws -> [AlertResponse] {
        guard let url = URL(string: "\(baseURL)/api/alerts/") else {
            throw AlertNetworkError.invalidURL
        }
        
        // Create a query request body
        let queryRequest = [
            "action": "list",
            "user_id": userId
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(csrfToken, forHTTPHeaderField: "X-CSRFToken")
        
        let jsonData = try JSONSerialization.data(withJSONObject: queryRequest)
        request.httpBody = jsonData
        
        print("🔍 Strategy 3: POST query to /api/alerts/")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AlertNetworkError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw AlertNetworkError.serverError("Status: \(httpResponse.statusCode)")
        }
        
        return try parseAlertsResponse(data: data)
    }
    
    // MARK: - Helper: Parse Alerts Response
    
    private func parseAlertsResponse(data: Data) throws -> [AlertResponse] {
        let decoder = JSONDecoder()
        
        // Debug: Print raw response
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 Raw API Response: \(responseString)")
        }
        
        // Try different response formats
        if let alertsArray = try? decoder.decode([AlertResponse].self, from: data) {
            print("✅ Parsed as direct array: \(alertsArray.count) alerts")
            return alertsArray
        } else if let alertsWrapper = try? decoder.decode(AlertsWrapper.self, from: data) {
            print("✅ Parsed as wrapped response: \(alertsWrapper.results.count) alerts")
            return alertsWrapper.results
        } else {
            // Try to decode as single object
            let singleAlert = try decoder.decode(AlertResponse.self, from: data)
            print("✅ Parsed as single alert")
            return [singleAlert]
        }
    }
    
    // MARK: - Create Alert (Existing Method)
    
    func createAlert(
        origin: String,
        destination: String,
        originName: String,
        destinationName: String,
        currency: String = "INR"
    ) async throws -> AlertResponse {
        
        guard let url = URL(string: "\(baseURL)/api/alerts/") else {
            print("❌ Invalid URL: \(baseURL)/api/alerts/")
            throw AlertNetworkError.invalidURL
        }
        
        // Create request body exactly matching the curl example
        let alertRequest = AlertRequest(
            user: AlertUser(
                id: userId,
                push_token: pushToken
            ),
            route: AlertRoute(
                origin: origin,
                destination: destination,
                currency: currency,
                origin_name: originName,
                destination_name: destinationName
            )
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(csrfToken, forHTTPHeaderField: "X-CSRFToken")
        
        // Debug: Print request details
        print("🌐 Alert API Request:")
        print("   URL: \(url)")
        print("   Method: POST")
        print("   Headers: accept=application/json, Content-Type=application/json")
        print("   CSRF-Token: \(csrfToken)")
        
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(alertRequest)
            request.httpBody = jsonData
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("   Body: \(jsonString)")
            }
        } catch {
            print("❌ Error encoding alert request: \(error)")
            throw AlertNetworkError.decodingError(error)
        }
        
        do {
            print("🚀 Making alert API call...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Debug response
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Alert API Response:")
                print("   Status Code: \(httpResponse.statusCode)")
                print("   Headers: \(httpResponse.allHeaderFields)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid HTTP response")
                throw AlertNetworkError.invalidResponse
            }
            
            // Log raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("   Response Body: \(responseString)")
            } else {
                print("   Response Body: Unable to decode as string")
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                let errorMessage = "Alert API failed with status \(httpResponse.statusCode)"
                print("❌ \(errorMessage)")
                
                // Try to parse error response
                if let responseString = String(data: data, encoding: .utf8) {
                    throw AlertNetworkError.serverError("API Error (\(httpResponse.statusCode)): \(responseString)")
                } else {
                    throw AlertNetworkError.serverError("API Error: Status code \(httpResponse.statusCode)")
                }
            }
            
            // Parse successful response
            do {
                let decoder = JSONDecoder()
                let alertResponse = try decoder.decode(AlertResponse.self, from: data)
                print("✅ Alert created successfully:")
                print("   Alert ID: \(alertResponse.id)")
                print("   Route: \(alertResponse.route.origin_name) → \(alertResponse.route.destination_name)")
                if let cheapestFlight = alertResponse.cheapest_flight {
                    print("   Price: \(cheapestFlight.price) \(alertResponse.route.currency)")
                }
                return alertResponse
            } catch {
                print("❌ Alert response decoding error: \(error)")
                print("❌ Raw response: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                throw AlertNetworkError.decodingError(error)
            }
            
        } catch {
            if error is AlertNetworkError {
                throw error
            } else {
                print("❌ Network error: \(error)")
                throw AlertNetworkError.serverError("Network error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Delete Alert
    
    func deleteAlert(alertId: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/alerts/\(alertId)/") else {
            print("❌ Invalid URL: \(baseURL)/api/alerts/\(alertId)/")
            throw AlertNetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.addValue(csrfToken, forHTTPHeaderField: "X-CSRFToken")
        
        print("🗑️ Deleting alert: \(alertId)")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AlertNetworkError.invalidResponse
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw AlertNetworkError.serverError("Delete failed with status \(httpResponse.statusCode)")
            }
            
            print("✅ Alert deleted successfully: \(alertId)")
            
        } catch {
            print("❌ Delete alert error: \(error)")
            throw error
        }
    }
    
    // Helper method for testing the API connection
    func testAPIConnection() async {
        print("🧪 Testing Alert API connection...")
        do {
            let alerts = try await fetchAlerts()
            print("✅ API test successful: Found \(alerts.count) alerts")
        } catch {
            print("❌ API test failed: \(error)")
        }
    }
}

// MARK: - Supporting Models

struct AlertsWrapper: Codable {
    let results: [AlertResponse]
    let count: Int?
    let next: String?
    let previous: String?
}
