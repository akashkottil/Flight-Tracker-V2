//
//  AboutDestination.swift
//  AllFlights
//
//  Created by Akash Kottil on 21/07/25.
//

import SwiftUI

struct AboutDestination: View {
    let flight: FlightDetail
    @StateObject private var weatherState = WeatherState()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("About your destination")
                .font(.system(size: 18, weight: .semibold))
                .padding(.vertical, 10)
            
            // Weather Card
            weatherCard
            
            // Time Zone Card
            timeZoneCard
        }
        .onAppear {
            // Fetch weather for arrival airport
            weatherState.fetchWeather(for: flight.arrival.airport)
        }
        .onChange(of: flight.arrival.airport.iataCode) { _ in
            // Fetch weather if airport changes
            weatherState.fetchWeather(for: flight.arrival.airport)
        }
    }
    
    // MARK: - Weather Card
    
    private var weatherCard: some View {
        HStack {
            VStack(alignment: .leading) {
                if weatherState.isLoading {
                    // Loading state
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        
                        Text("Loading...")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                    }
                } else if let weather = weatherState.currentWeather {
                    // Weather data loaded
                    Text(weather.current.temperatureDisplay)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                } else {
                    // Fallback temperature
                    Text("--°C")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text(weatherLocationText)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Weather Icon
            if weatherState.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(width: 40, height: 40)
            } else if let weather = weatherState.currentWeather {
                // Dynamic weather icon based on condition
                if weather.current.weatherCondition.lowercased().contains("cloud") {
                    Image(weather.current.weatherIcon)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.white)
                } else {
                    // Use SF Symbol for other conditions
                    Image(systemName: weather.current.weatherIcon)
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
            } else {
                // Default cloud icon
                Image("Cloud")
            }
        }
        .padding()
        .background(backgroundColorForWeather)
        .cornerRadius(20)
        .onTapGesture {
            // Tap to refresh weather data
            if !weatherState.isLoading {
                weatherState.fetchWeather(for: flight.arrival.airport)
            }
        }
    }
    
    // MARK: - Time Zone Card
    
    private var timeZoneCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Time Zone Change")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.black.opacity(0.7))
                
                Text(timeZoneChangeText)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(arrivalTimeExplanation)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.black.opacity(0.7))
            }
            Spacer()
        }
        .padding()
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.black.opacity(0.3), lineWidth: 1.4)
        )
        .cornerRadius(20)
    }
    
    // MARK: - Computed Properties
    
    private var weatherLocationText: String {
        let cityName = flight.arrival.airport.city ?? flight.arrival.airport.name
        
        if let weather = weatherState.currentWeather {
            return "Weather in \(cityName) • \(weather.current.weatherCondition)"
        } else if weatherState.isLoading {
            return "Getting weather for \(cityName)..."
        } else if weatherState.errorMessage != nil {
            return "Weather in \(cityName) • Unavailable"
        } else {
            return "Weather in \(cityName)"
        }
    }
    
    private var backgroundColorForWeather: Color {
        guard let weather = weatherState.currentWeather else {
            return .blue // Default blue
        }
        
        // Dynamic background color based on weather condition
        switch weather.current.weatherCode {
        case 0: // Clear
            return weather.current.isDay == 1 ? .orange : .indigo
        case 1, 2, 3: // Partly cloudy
            return .blue
        case 45, 48: // Foggy
            return .gray
        case 51...67: // Rain/Drizzle
            return .blue.opacity(0.8)
        case 71...77: // Snow
            return .cyan
        case 80...86: // Showers
            return .blue
        case 95...99: // Thunderstorm
            return .purple
        default:
            return .blue
        }
    }
    
    private var timeZoneChangeText: String {
        // Calculate time zone difference
        let departureGMT = flight.departure.airport.timezone.gmt ?? 0.0
        let arrivalGMT = flight.arrival.airport.timezone.gmt ?? 0.0
        let timeDifference = arrivalGMT - departureGMT
        
        if timeDifference > 0 {
            let hours = Int(timeDifference)
            let minutes = Int((timeDifference - Double(hours)) * 60)
            if minutes == 0 {
                return "+ \(hours)h"
            } else {
                return "+ \(hours)h \(minutes)min"
            }
        } else if timeDifference < 0 {
            let hours = Int(abs(timeDifference))
            let minutes = Int((abs(timeDifference) - Double(hours)) * 60)
            if minutes == 0 {
                return "- \(hours)h"
            } else {
                return "- \(hours)h \(minutes)min"
            }
        } else {
            return "Same timezone"
        }
    }
    
    private var arrivalTimeExplanation: String {
        let arrivalTime = formatTime(flight.arrival.scheduled.local)
        let arrivalDate = formatDate(flight.arrival.scheduled.local)
        let destinationCity = flight.arrival.airport.city ?? flight.arrival.airport.name
        
        return "Arrival at \(arrivalTime) \(arrivalDate) is local time in \(destinationCity)"
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ timeString: String?) -> String {
        guard let timeString = timeString else { return "--:--" }
        
        let formatter = DateFormatter()
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss"
        ]
        
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: timeString) {
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                return timeFormatter.string(from: date)
            }
        }
        return timeString
    }
    
    private func formatDate(_ timeString: String?) -> String {
        guard let timeString = timeString else { return "--" }
        
        let formatter = DateFormatter()
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss"
        ]
        
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: timeString) {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "EEE, dd MMM"
                return dateFormatter.string(from: date)
            }
        }
        return timeString
    }
}
