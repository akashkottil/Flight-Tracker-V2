//
//  WeatherState.swift
//  AllFlights
//
//  Created by Akash Kottil on 02/08/25.
//


// ViewModels/WeatherState.swift
import Foundation

@MainActor
class WeatherState: ObservableObject {
    @Published var currentWeather: WeatherResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkManager = WeatherNetworkManager.shared
    private var currentTask: Task<Void, Never>?
    
    func fetchWeather(for airport: FlightDetailAirport) {
        // Cancel any existing request
        currentTask?.cancel()
        
        // Reset state
        isLoading = true
        errorMessage = nil
        
        currentTask = Task {
            do {
                let weather = try await networkManager.fetchWeather(
                    latitude: airport.location.lat,
                    longitude: airport.location.lng
                )
                
                // Check if task was cancelled
                guard !Task.isCancelled else { return }
                
                self.currentWeather = weather
                self.isLoading = false
                
            } catch {
                // Check if task was cancelled
                guard !Task.isCancelled else { return }
                
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                print("❌ Weather fetch failed: \(error)")
            }
        }
    }
    
    func reset() {
        currentTask?.cancel()
        currentWeather = nil
        isLoading = false
        errorMessage = nil
    }
    
    deinit {
        currentTask?.cancel()
    }
}