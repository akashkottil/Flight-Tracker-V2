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
    
    // Helper method for testing the API connection
    func testAPIConnection() async {
        print("🧪 Testing Alert API connection...")
        do {
            let response = try await createAlert(
                origin: "COK",
                destination: "DXB",
                originName: "Kochi",
                destinationName: "Dubai"
            )
            print("✅ API test successful: \(response.id)")
        } catch {
            print("❌ API test failed: \(error)")
        }
    }
}
