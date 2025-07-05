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
    
    // MARK: - NEW: Primary fetch method using specific user endpoint
    
    func fetchUserAlerts() async throws -> [AlertResponse] {
        print("🔍 Fetching alerts for user: \(userId)")
        
        guard let url = URL(string: "\(baseURL)/api/alerts/user/\(userId)/") else {
            throw AlertNetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.addValue(csrfToken, forHTTPHeaderField: "X-CSRFToken")
        
        print("🌐 GET URL: \(url)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AlertNetworkError.invalidResponse
            }
            
            print("📡 Response Status: \(httpResponse.statusCode)")
            
            // Log raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Raw Response: \(responseString)")
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                if httpResponse.statusCode == 404 {
                    // User has no alerts - return empty array
                    print("✅ No alerts found for user (404) - returning empty array")
                    return []
                }
                throw AlertNetworkError.serverError("Status: \(httpResponse.statusCode)")
            }
            
            // Parse the response
            let alerts = try parseAlertsResponse(data: data)
            print("✅ Successfully fetched \(alerts.count) alerts for user")
            return alerts
            
        } catch {
            if let alertError = error as? AlertNetworkError {
                throw alertError
            } else {
                print("❌ Network error: \(error)")
                throw AlertNetworkError.serverError("Network error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Keep existing fetchAlerts as fallback
    
    func fetchAlerts() async throws -> [AlertResponse] {
        print("🔍 Using fallback fetch method...")
        
        // First try the specific user endpoint
        do {
            return try await fetchUserAlerts()
        } catch {
            print("⚠️ User-specific endpoint failed, trying fallback strategies: \(error)")
        }
        
        // If that fails, use the existing multi-strategy approach
        return try await fetchAlertsWithMultipleStrategies()
    }
    
    // MARK: - Existing multi-strategy fetch (kept as fallback)
    
    private func fetchAlertsWithMultipleStrategies() async throws -> [AlertResponse] {
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
    
    // MARK: - Helper: Parse Alerts Response
    
    private func parseAlertsResponse(data: Data) throws -> [AlertResponse] {
        let decoder = JSONDecoder()
        
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
    
    // MARK: - Keep all existing methods (create, delete, edit, etc.)
    // [Rest of the existing methods remain exactly the same...]
    
    private func fetchAlertsWithUserFilter() async throws -> [AlertResponse] {
        guard let url = URL(string: "\(baseURL)/api/alerts/?user_id=\(userId)") else {
            throw AlertNetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.addValue(csrfToken, forHTTPHeaderField: "X-CSRFToken")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AlertNetworkError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw AlertNetworkError.serverError("Status: \(httpResponse.statusCode)")
        }
        
        return try parseAlertsResponse(data: data)
    }
    
    private func fetchAlertsFromEndpoint(_ endpoint: String) async throws -> [AlertResponse] {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw AlertNetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.addValue(csrfToken, forHTTPHeaderField: "X-CSRFToken")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AlertNetworkError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw AlertNetworkError.serverError("Status: \(httpResponse.statusCode)")
        }
        
        return try parseAlertsResponse(data: data)
    }
    
    private func fetchAlertsWithPOST() async throws -> [AlertResponse] {
        guard let url = URL(string: "\(baseURL)/api/alerts/") else {
            throw AlertNetworkError.invalidURL
        }
        
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AlertNetworkError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw AlertNetworkError.serverError("Status: \(httpResponse.statusCode)")
        }
        
        return try parseAlertsResponse(data: data)
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
    
    // MARK: - Delete Alert Methods
    
    // ENHANCED: Delete method with user context
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
        print("🌐 DELETE URL: \(url)")
        print("🔑 CSRF Token: \(csrfToken)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AlertNetworkError.invalidResponse
            }
            
            print("📡 Delete Response Status: \(httpResponse.statusCode)")
            
            // Log response body for debugging
            if let responseString = String(data: data, encoding: .utf8), !responseString.isEmpty {
                print("📄 Delete Response Body: \(responseString)")
            }
            
            if httpResponse.statusCode == 404 {
                // Specific handling for 404 - alert might not exist or wrong endpoint
                let errorMessage = "Alert not found. It may have been already deleted or doesn't belong to this user."
                print("❌ 404 Error: \(errorMessage)")
                throw AlertNetworkError.serverError(errorMessage)
            } else if httpResponse.statusCode == 403 {
                // Forbidden - might need user-specific endpoint
                let errorMessage = "Access denied. You may not have permission to delete this alert."
                print("❌ 403 Error: \(errorMessage)")
                throw AlertNetworkError.serverError(errorMessage)
            } else if !(200...299 ~= httpResponse.statusCode) {
                let errorMessage = "Delete failed with status \(httpResponse.statusCode)"
                print("❌ Delete Error: \(errorMessage)")
                
                if let responseString = String(data: data, encoding: .utf8), !responseString.isEmpty {
                    throw AlertNetworkError.serverError("Delete Error (\(httpResponse.statusCode)): \(responseString)")
                } else {
                    throw AlertNetworkError.serverError(errorMessage)
                }
            }
            
            print("✅ Alert deleted successfully: \(alertId)")
            
        } catch {
            print("❌ Delete alert error: \(error)")
            throw error
        }
    }
    
    // NEW: Delete with explicit user context in request body
    func deleteAlertWithUserContext(alertId: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/alerts/\(alertId)/") else {
            print("❌ Invalid URL: \(baseURL)/api/alerts/\(alertId)/")
            throw AlertNetworkError.invalidURL
        }
        
        // Add user context to request body
        let deleteRequest = [
            "user_id": userId,
            "alert_id": alertId
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(csrfToken, forHTTPHeaderField: "X-CSRFToken")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: deleteRequest)
            request.httpBody = jsonData
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("🗑️ Delete request body: \(jsonString)")
            }
        } catch {
            throw AlertNetworkError.decodingError(error)
        }
        
        print("🗑️ Deleting alert with user context: \(alertId)")
        print("🌐 DELETE URL: \(url)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AlertNetworkError.invalidResponse
            }
            
            print("📡 Delete with context Response Status: \(httpResponse.statusCode)")
            
            // Debug response
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Delete with context Response: \(responseString)")
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                let errorMessage = "Delete with context failed with status \(httpResponse.statusCode)"
                print("❌ \(errorMessage)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    throw AlertNetworkError.serverError("Delete Error (\(httpResponse.statusCode)): \(responseString)")
                } else {
                    throw AlertNetworkError.serverError(errorMessage)
                }
            }
            
            print("✅ Alert deleted successfully with user context: \(alertId)")
            
        } catch {
            print("❌ Delete alert with user context error: \(error)")
            throw error
        }
    }
    
    // ALTERNATIVE: Try query parameter approach
    func deleteAlertWithUserQuery(alertId: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/alerts/\(alertId)/?user_id=\(userId)") else {
            print("❌ Invalid URL: \(baseURL)/api/alerts/\(alertId)/?user_id=\(userId)")
            throw AlertNetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.addValue(csrfToken, forHTTPHeaderField: "X-CSRFToken")
        
        print("🗑️ Deleting alert with user query: \(alertId)")
        print("🌐 DELETE URL: \(url)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AlertNetworkError.invalidResponse
            }
            
            print("📡 Delete with query Response Status: \(httpResponse.statusCode)")
            
            // Debug response
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Delete with query Response: \(responseString)")
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                let errorMessage = "Delete with query failed with status \(httpResponse.statusCode)"
                print("❌ \(errorMessage)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    throw AlertNetworkError.serverError("Delete Error (\(httpResponse.statusCode)): \(responseString)")
                } else {
                    throw AlertNetworkError.serverError(errorMessage)
                }
            }
            
            print("✅ Alert deleted successfully with user query: \(alertId)")
            
        } catch {
            print("❌ Delete alert with user query error: \(error)")
            throw error
        }
    }
    
    // ENHANCED: Smart delete method that tries multiple approaches
    func deleteAlertSmart(alertId: String) async throws {
        print("🤖 Attempting smart delete for alert: \(alertId)")
        
        // First, let's verify the alert exists by fetching current alerts
        do {
            let currentAlerts = try await fetchUserAlerts()
            let alertExists = currentAlerts.contains { $0.id == alertId }
            
            if !alertExists {
                print("⚠️ Alert \(alertId) not found in current alerts list")
                print("📋 Available alerts: \(currentAlerts.map { $0.id })")
                throw AlertNetworkError.serverError("Alert not found in your alerts list. It may have been deleted already.")
            } else {
                print("✅ Alert \(alertId) confirmed to exist in fetched alerts")
                // Show which user the alert belongs to
                if let alert = currentAlerts.first(where: { $0.id == alertId }) {
                    print("👤 Alert belongs to user: \(alert.user.id)")
                    print("🛫 Alert route: \(alert.route.origin) → \(alert.route.destination)")
                }
            }
        } catch {
            print("⚠️ Could not verify alert existence: \(error)")
        }
        
        // Strategy 1: Try with user query parameter
        do {
            try await deleteAlertWithUserQuery(alertId: alertId)
            print("✅ Successfully deleted via user query parameter")
            return
        } catch {
            print("⚠️ User query parameter delete failed: \(error)")
        }
        
        // Strategy 2: Try with user context in request body
        do {
            try await deleteAlertWithUserContext(alertId: alertId)
            print("✅ Successfully deleted via user context in body")
            return
        } catch {
            print("⚠️ User context delete failed: \(error)")
        }
        
        // Strategy 3: Try the standard REST endpoint
        do {
            try await deleteAlert(alertId: alertId)
            print("✅ Successfully deleted via standard endpoint")
            return
        } catch {
            print("⚠️ Standard endpoint delete failed: \(error)")
        }
        
        // If all strategies fail
        print("❌ All delete strategies failed")
        throw AlertNetworkError.serverError("Unable to delete alert. This might be a permission issue or the alert may belong to a different user.")
    }
    

    // MARK: - Edit Alert Method

    // Replace the editAlert method in your AlertNetworkManager.swift with this improved version

    func editAlert(
        alertId: String,
        origin: String,
        destination: String,
        originName: String,
        destinationName: String,
        currency: String = "INR"
    ) async throws -> AlertResponse {
        
        print("🔄 Starting edit alert process...")
        print("   Alert ID: \(alertId)")
        print("   New Route: \(origin) → \(destination) (\(currency))")
        
        // Step 1: Fetch current alerts to check for conflicts
        var existingAlerts: [AlertResponse] = []
        do {
            existingAlerts = try await fetchUserAlerts()
            print("✅ Fetched \(existingAlerts.count) existing alerts for conflict check")
        } catch {
            print("⚠️ Could not fetch existing alerts: \(error)")
            print("⚠️ Proceeding with edit attempt anyway...")
        }
        
        // Step 2: Check if we're trying to change to the same route (no-op case)
        if let currentAlert = existingAlerts.first(where: { $0.id == alertId }) {
            if currentAlert.route.origin == origin &&
               currentAlert.route.destination == destination &&
               currentAlert.route.currency == currency {
                print("ℹ️ No changes detected - same route. Updating names only...")
                // Continue with update to refresh the names
            }
        }
        
        // Step 3: Enhanced conflict detection and resolution
        let conflictingAlerts = existingAlerts.filter { alert in
            alert.id != alertId && // Not the same alert being edited
            alert.route.origin.uppercased() == origin.uppercased() &&
            alert.route.destination.uppercased() == destination.uppercased() &&
            alert.route.currency.uppercased() == currency.uppercased()
        }
        
        if !conflictingAlerts.isEmpty {
            print("⚠️ Found \(conflictingAlerts.count) conflicting alert(s)")
            
            // Strategy: Delete conflicting alerts before updating
            for conflictingAlert in conflictingAlerts {
                print("🗑️ Deleting conflicting alert: \(conflictingAlert.id)")
                print("   Route: \(conflictingAlert.route.origin) → \(conflictingAlert.route.destination)")
                
                do {
                    try await deleteAlertSmart(alertId: conflictingAlert.id)
                    print("✅ Successfully deleted conflicting alert: \(conflictingAlert.id)")
                } catch {
                    print("❌ Failed to delete conflicting alert: \(conflictingAlert.id)")
                    print("   Error: \(error)")
                    
                    // If we can't delete the conflicting alert, we can't proceed
                    throw AlertNetworkError.serverError("Cannot update alert: A similar route already exists and could not be removed. Please delete the existing \(conflictingAlert.route.origin) → \(conflictingAlert.route.destination) alert first.")
                }
            }
            
            // Wait a moment for the deletion to process
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            print("✅ All conflicting alerts deleted, proceeding with update...")
        }
        
        // Step 4: Proceed with the edit API call
        guard let url = URL(string: "\(baseURL)/api/alerts/\(alertId)/") else {
            print("❌ Invalid URL: \(baseURL)/api/alerts/\(alertId)/")
            throw AlertNetworkError.invalidURL
        }
        
        let alertRequest = AlertRequest(
            user: AlertUser(
                id: userId,
                push_token: pushToken
            ),
            route: AlertRoute(
                origin: origin.uppercased(), // Ensure uppercase
                destination: destination.uppercased(), // Ensure uppercase
                currency: currency.uppercased(), // Ensure uppercase
                origin_name: originName,
                destination_name: destinationName
            )
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(csrfToken, forHTTPHeaderField: "X-CSRFToken")
        
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(alertRequest)
            request.httpBody = jsonData
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📝 Edit request body: \(jsonString)")
            }
        } catch {
            print("❌ Error encoding edit alert request: \(error)")
            throw AlertNetworkError.decodingError(error)
        }
        
        // Step 5: Make the API call with enhanced error handling
        do {
            print("🚀 Making edit alert API call...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid HTTP response")
                throw AlertNetworkError.invalidResponse
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📡 Edit Response (\(httpResponse.statusCode)): \(responseString)")
            }
            
            // Handle specific error cases
            if httpResponse.statusCode == 400 {
                if let responseString = String(data: data, encoding: .utf8),
                   responseString.contains("must make a unique set") {
                    print("❌ Unique constraint violation detected")
                    
                    // Try alternative approach: Create new alert and delete old one
                    return try await handleUniqueConstraintViolation(
                        originalAlertId: alertId,
                        origin: origin,
                        destination: destination,
                        originName: originName,
                        destinationName: destinationName,
                        currency: currency
                    )
                }
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                let errorMessage = "Edit Alert API failed with status \(httpResponse.statusCode)"
                print("❌ \(errorMessage)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    throw AlertNetworkError.serverError("API Error (\(httpResponse.statusCode)): \(responseString)")
                } else {
                    throw AlertNetworkError.serverError("API Error: Status code \(httpResponse.statusCode)")
                }
            }
            
            // Step 6: Parse successful response
            do {
                let decoder = JSONDecoder()
                let alertResponse = try decoder.decode(AlertResponse.self, from: data)
                print("✅ Alert edited successfully:")
                print("   Alert ID: \(alertResponse.id)")
                print("   Route: \(alertResponse.route.origin_name) → \(alertResponse.route.destination_name)")
                if let cheapestFlight = alertResponse.cheapest_flight {
                    print("   Price: \(cheapestFlight.price) \(alertResponse.route.currency)")
                }
                return alertResponse
            } catch {
                print("❌ Edit alert response decoding error: \(error)")
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

    // MARK: - Helper method for handling unique constraint violations

    private func handleUniqueConstraintViolation(
        originalAlertId: String,
        origin: String,
        destination: String,
        originName: String,
        destinationName: String,
        currency: String
    ) async throws -> AlertResponse {
        
        print("🔄 Handling unique constraint violation with alternative approach...")
        print("   Strategy: Create new alert → Delete old alert")
        
        // Step 1: Create a new alert with the desired route
        do {
            let newAlert = try await createAlert(
                origin: origin,
                destination: destination,
                originName: originName,
                destinationName: destinationName,
                currency: currency
            )
            
            print("✅ Successfully created new alert: \(newAlert.id)")
            
            // Step 2: Delete the original alert
            do {
                try await deleteAlertSmart(alertId: originalAlertId)
                print("✅ Successfully deleted original alert: \(originalAlertId)")
                
                print("✅ Edit operation completed via create-then-delete strategy")
                return newAlert
                
            } catch {
                print("⚠️ Created new alert but failed to delete original: \(error)")
                // We have a new alert created, but couldn't delete the old one
                // Return the new alert anyway - user will have duplicate until they manually delete
                print("⚠️ User now has both alerts - recommend manual cleanup")
                return newAlert
            }
            
        } catch {
            print("❌ Alternative strategy failed: \(error)")
            throw AlertNetworkError.serverError("Unable to update alert. The route \(origin) → \(destination) may already exist. Please try creating a new alert instead.")
        }
    }
    
    // Helper method for testing the API connection
    func testAPIConnection() async {
        print("🧪 Testing Alert API connection...")
        do {
            let alerts = try await fetchUserAlerts()
            print("✅ API test successful: Found \(alerts.count) alerts")
        } catch {
            print("❌ API test failed: \(error)")
        }
    }
}


// MARK: - Supporting Models (keep existing)
struct AlertsWrapper: Codable {
    let results: [AlertResponse]
    let count: Int?
    let next: String?
    let previous: String?
}
