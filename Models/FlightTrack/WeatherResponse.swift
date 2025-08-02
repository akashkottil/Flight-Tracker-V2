//
//  WeatherResponse.swift
//  AllFlights
//
//  Created by Akash Kottil on 02/08/25.
//


// Models/Weather/WeatherModels.swift
import Foundation

struct WeatherResponse: Codable {
    let latitude: Double
    let longitude: Double
    let generationtimeMs: Double
    let utcOffsetSeconds: Int
    let timezone: String
    let timezoneAbbreviation: String
    let elevation: Double
    let currentUnits: CurrentUnits
    let current: CurrentWeather
    
    enum CodingKeys: String, CodingKey {
        case latitude, longitude
        case generationtimeMs = "generationtime_ms"
        case utcOffsetSeconds = "utc_offset_seconds"
        case timezone
        case timezoneAbbreviation = "timezone_abbreviation"
        case elevation
        case currentUnits = "current_units"
        case current
    }
}

struct CurrentUnits: Codable {
    let time: String
    let interval: String
    let temperature2m: String
    let isDay: String
    let rain: String
    let weatherCode: String
    
    enum CodingKeys: String, CodingKey {
        case time, interval
        case temperature2m = "temperature_2m"
        case isDay = "is_day"
        case rain
        case weatherCode = "weather_code"
    }
}

struct CurrentWeather: Codable {
    let time: String
    let interval: Int
    let temperature2m: Double
    let isDay: Int
    let rain: Double
    let weatherCode: Int
    
    enum CodingKeys: String, CodingKey {
        case time, interval
        case temperature2m = "temperature_2m"
        case isDay = "is_day"
        case rain
        case weatherCode = "weather_code"
    }
}

// Weather condition helper
extension CurrentWeather {
    var temperatureDisplay: String {
        return "\(Int(temperature2m))°C"
    }
    
    var weatherCondition: String {
        // Convert WMO weather codes to readable conditions
        switch weatherCode {
        case 0: return "Clear"
        case 1, 2, 3: return "Partly Cloudy"
        case 45, 48: return "Foggy"
        case 51, 53, 55: return "Drizzle"
        case 56, 57: return "Freezing Drizzle"
        case 61, 63, 65: return "Rain"
        case 66, 67: return "Freezing Rain"
        case 71, 73, 75: return "Snow"
        case 77: return "Snow Grains"
        case 80, 81, 82: return "Rain Showers"
        case 85, 86: return "Snow Showers"
        case 95: return "Thunderstorm"
        case 96, 99: return "Thunderstorm with Hail"
        default: return "Unknown"
        }
    }
    
    var weatherIcon: String {
        // Map weather codes to appropriate system icons or custom weather icons
        let isDayTime = isDay == 1
        
        switch weatherCode {
        case 0:
            return isDayTime ? "sun.max" : "moon"
        case 1, 2, 3:
            return isDayTime ? "cloud.sun" : "cloud.moon"
        case 45, 48:
            return "cloud.fog"
        case 51, 53, 55, 56, 57:
            return "cloud.drizzle"
        case 61, 63, 65, 66, 67:
            return "cloud.rain"
        case 71, 73, 75, 77:
            return "cloud.snow"
        case 80, 81, 82:
            return "cloud.heavyrain"
        case 85, 86:
            return "cloud.snow"
        case 95, 96, 99:
            return "cloud.bolt.rain"
        default:
            return "cloud"
        }
    }
}

// MARK: - Error Handling
enum WeatherError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case decodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid weather API URL"
        case .invalidResponse:
            return "Invalid response from weather service"
        case .noData:
            return "No weather data available"
        case .decodingError(let error):
            return "Weather data parsing error: \(error.localizedDescription)"
        case .networkError(let error):
            return "Weather network error: \(error.localizedDescription)"
        }
    }
}
