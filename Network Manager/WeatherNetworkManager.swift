//
//  WeatherNetworkManager.swift
//  AllFlights
//
//  Created by Akash Kottil on 02/08/25.
//


// Network Manager/WeatherNetworkManager.swift
import Foundation

class WeatherNetworkManager {
    static let shared = WeatherNetworkManager()
    private let baseURL = "https://api.open-meteo.com/v1/forecast"
    private let cache = NSCache<NSString, NSData>()
    
    private init() {
        // Configure cache
        cache.countLimit = 50
        cache.totalCostLimit = 10 * 1024 * 1024 // 10MB
    }
    
    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherResponse {
        let cacheKey = "\(latitude),\(longitude)" as NSString
        
        // Check cache first (cache for 30 minutes)
        if let cachedData = cache.object(forKey: cacheKey) as Data?,
           let cachedResponse = try? JSONDecoder().decode(CachedWeatherResponse.self, from: cachedData),
           Date().timeIntervalSince(cachedResponse.timestamp) < 1800 { // 30 minutes
            print("🌤️ Using cached weather data for \(latitude), \(longitude)")
            return cachedResponse.weather
        }
        
        // Build URL with parameters
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,is_day,rain,weather_code")
        ]
        
        guard let url = components.url else {
            throw WeatherError.invalidURL
        }
        
        print("🌐 Weather API URL: \(url)")
        
        // Declare data outside the do block so it's accessible in catch blocks
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await URLSession.shared.data(from: url)
        } catch {
            print("❌ Weather network error: \(error)")
            throw WeatherError.networkError(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherError.invalidResponse
        }
        
        print("📡 Weather API Response Status: \(httpResponse.statusCode)")
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw WeatherError.networkError(NSError(domain: "WeatherAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"]))
        }
        
        guard !data.isEmpty else {
            throw WeatherError.noData
        }
        
        do {
            // Parse the response
            let decoder = JSONDecoder()
            let weatherResponse = try decoder.decode(WeatherResponse.self, from: data)
            
            // Cache the response
            let cachedResponse = CachedWeatherResponse(weather: weatherResponse, timestamp: Date())
            if let cachedData = try? JSONEncoder().encode(cachedResponse) {
                cache.setObject(cachedData as NSData, forKey: cacheKey)
            }
            
            print("✅ Weather data fetched successfully for \(latitude), \(longitude)")
            print("🌡️ Temperature: \(weatherResponse.current.temperatureDisplay)")
            print("🌤️ Condition: \(weatherResponse.current.weatherCondition)")
            
            return weatherResponse
            
        } catch let decodingError as DecodingError {
            print("❌ Weather decoding error: \(decodingError)")
            // Now data is accessible here
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Raw weather response: \(responseString)")
            }
            throw WeatherError.decodingError(decodingError)
        } catch {
            print("❌ Unexpected error: \(error)")
            throw error
        }
    }
    
    // Helper method to clear cache if needed
    func clearCache() {
        cache.removeAllObjects()
        print("🗑️ Weather cache cleared")
    }
}

// MARK: - Cache Helper
private struct CachedWeatherResponse: Codable {
    let weather: WeatherResponse
    let timestamp: Date
}
