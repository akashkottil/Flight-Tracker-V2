//
//  SearchManager.swift
//  AllFlights
//
//  Created by Akash Kottil on 26/06/25.
//


// Create new file: Utils/SearchManager.swift
import Foundation
import Combine

@MainActor
class SearchManager: ObservableObject {
    static let shared = SearchManager()
    
    @Published var searchResults: SearchResults = SearchResults()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var searchTask: Task<Void, Never>?
    private var lastSearchTime: Date = Date()
    private let minimumSearchInterval: TimeInterval = 0.3
    private let networkManager = FlightTrackNetworkManager.shared
    
    private init() {}
    
    struct SearchResults {
        var airports: [FlightTrackAirport] = []
        var airlines: [FlightTrackAirline] = []
        var searchEntityType: SearchEntityType = .unknown
    }
    
    func performSearch(query: String, shouldPerformMixed: Bool = false) {
        // Cancel previous search
        searchTask?.cancel()
        
        // Clear results if query is too short
        guard query.count >= 2 else {
            searchResults = SearchResults()
            return
        }
        
        // Throttle search requests
        let now = Date()
        let timeSinceLastSearch = now.timeIntervalSince(lastSearchTime)
        let delay = max(0, minimumSearchInterval - timeSinceLastSearch)
        
        searchTask = Task {
            // Wait for throttle delay
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            
            // Check if task was cancelled
            guard !Task.isCancelled else { return }
            
            await executeSearch(query: query, shouldPerformMixed: shouldPerformMixed)
        }
    }
    
    private func executeSearch(query: String, shouldPerformMixed: Bool) async {
        isLoading = true
        errorMessage = nil
        lastSearchTime = Date()
        
        do {
            if shouldPerformMixed {
                await performMixedSearch(query: query)
            } else {
                await performAirportOnlySearch(query: query)
            }
        } catch {
            if !Task.isCancelled {
                errorMessage = error.localizedDescription
                searchResults = SearchResults()
            }
        }
        
        if !Task.isCancelled {
            isLoading = false
        }
    }
    
    private func performMixedSearch(query: String) async {
        // Perform searches in parallel but handle errors independently
        async let airportResults = networkManager.searchAirports(query: query)
        async let airlineResults = networkManager.searchAirlines(query: query)
        
        var airports: [FlightTrackAirport] = []
        var airlines: [FlightTrackAirline] = []
        
        // Handle airport search
        do {
            let airportResponse = try await airportResults
            airports = airportResponse.results
        } catch {
            print("Airport search failed: \(error)")
        }
        
        // Handle airline search
        do {
            let airlineResponse = try await airlineResults
            airlines = airlineResponse.results.filter { $0.iataCode != nil }
        } catch {
            print("Airline search failed: \(error)")
        }
        
        // Update results
        if !Task.isCancelled {
            searchResults = SearchResults(
                airports: airports,
                airlines: airlines,
                searchEntityType: determineSearchEntityType(query: query, airports: airports, airlines: airlines)
            )
        }
    }
    
    private func performAirportOnlySearch(query: String) async {
        do {
            let response = try await networkManager.searchAirports(query: query)
            if !Task.isCancelled {
                searchResults = SearchResults(
                    airports: response.results,
                    airlines: [],
                    searchEntityType: .airport
                )
            }
        } catch {
            if !Task.isCancelled {
                errorMessage = error.localizedDescription
                searchResults = SearchResults()
            }
        }
    }
    
    private func determineSearchEntityType(query: String, airports: [FlightTrackAirport], airlines: [FlightTrackAirline]) -> SearchEntityType {
        let searchUpper = query.uppercased()
        
        if searchUpper.count == 2 || (searchUpper.count == 3 && !airlines.isEmpty) {
            return .airline
        } else if searchUpper.count == 3 || !airports.isEmpty {
            return .airport
        } else {
            return .unknown
        }
    }
    
    func clearResults() {
        searchTask?.cancel()
        searchResults = SearchResults()
        errorMessage = nil
        isLoading = false
    }
}
