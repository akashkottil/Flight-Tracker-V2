import Foundation
import SwiftUI
import Combine

class SearchViewModel: ObservableObject {
    // Trip type selection
    @Published var tripType: TripType = .returnTrip
    
    // Location data
    @Published var originCode: String = "COK"
    @Published var originCity: String = "Cochin"
    @Published var destinationCode: String = "DXB"
    @Published var destinationCity: String = "Dubai"
    
    // Date selection
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
    
    // Traveler settings
    @Published var adultsCount: Int = 1
    @Published var childrenCount: Int = 0 // New property for children count
    @Published var travelClass: TravelClass = .economy
    @Published var directFlightsOnly: Bool = false
    
    // Multi-city trips
    @Published var trips: [Trip] = [Trip.createDefault(), Trip.createDefault()]
    
    // UI state
    @Published var isLocationSheetOpen: Bool = false
    @Published var isEditingOrigin: Bool = true
    @Published var currentTripIndex: Int = 0
    
    // Cancellables for notification handling
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupNotificationObserver()
    }
    
    // MARK: - Trip Type Management
    
    func selectTripType(_ type: TripType) {
        withAnimation(.bouncy()) {
            tripType = type
            if type == .multiCity && trips.isEmpty {
                trips = [Trip.createDefault()]
            }
        }
    }
    
    // MARK: - Multi-City Trip Management
    
    func addTrip() {
        withAnimation {
            trips.append(Trip.createDefault())
        }
    }
    
    func removeTrip(at index: Int) {
        withAnimation {
            if trips.count > 1 {
                trips.remove(at: index)
            }
        }
    }
    
    // MARK: - Location Management
    
    func openLocationSheet(isOrigin: Bool, tripIndex: Int = 0) {
        isEditingOrigin = isOrigin
        currentTripIndex = tripIndex
        isLocationSheetOpen = true
    }
    
    func swapOriginAndDestination() {
        let tempCode = originCode
        let tempCity = originCity
        originCode = destinationCode
        originCity = destinationCity
        destinationCode = tempCode
        destinationCity = tempCity
    }
    
    func swapOriginAndDestination(for tripIndex: Int) {
        let tempCode = trips[tripIndex].originCode
        let tempCity = trips[tripIndex].originCity
        trips[tripIndex].originCode = trips[tripIndex].destinationCode
        trips[tripIndex].originCity = trips[tripIndex].destinationCity
        trips[tripIndex].destinationCode = tempCode
        trips[tripIndex].destinationCity = tempCity
    }
    
    // MARK: - Formatters
    
    func formatDateRange() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE,d MMM"
        
        let startDateStr = dateFormatter.string(from: startDate)
        let endDateStr = dateFormatter.string(from: endDate)
        
        return "\(startDateStr) - \(endDateStr)"
    }
    
    func formatSingleDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE,d MMM"
        return dateFormatter.string(from: date)
    }
    
    // MARK: - Passenger and Class Management
    
    // Format passenger and class info for display
    func formatPassengerAndClassInfo() -> String {
        var text = "\(adultsCount) Adult\(adultsCount > 1 ? "s" : "")"
        
        if childrenCount > 0 {
            text += ", \(childrenCount) Child\(childrenCount > 1 ? "ren" : "")"
        }
        
        text += " - \(travelClass.rawValue)"
        return text
    }
    
    // MARK: - Search
    
    func search() {
        // Search implementation
        print("Searching for flights...")
    }
    
    // MARK: - Notification Observer
    
    private func setupNotificationObserver() {
        NotificationCenter.default.publisher(for: Notification.Name("LocationSelected"))
            .compactMap { $0.object as? AutocompleteItem }
            .sink { [weak self] location in
                self?.updateLocation(location)
            }
            .store(in: &cancellables)
    }
    
    private func updateLocation(_ location: AutocompleteItem) {
        if tripType == .multiCity {
            // Update for multi-city
            if isEditingOrigin {
                trips[currentTripIndex].originCode = location.iataCode
                trips[currentTripIndex].originCity = location.cityName
            } else {
                trips[currentTripIndex].destinationCode = location.iataCode
                trips[currentTripIndex].destinationCity = location.cityName
            }
        } else {
            // Update for return or one-way
            if isEditingOrigin {
                originCode = location.iataCode
                originCity = location.cityName
            } else {
                destinationCode = location.iataCode
                destinationCity = location.cityName
            }
        }
    }
    
    // Handle location selection from location sheet
    func handleLocationSelection(_ location: AutocompleteItem) {
        if tripType == .multiCity {
            // Update for multi-city
            if isEditingOrigin {
                trips[currentTripIndex].originCode = location.iataCode
                trips[currentTripIndex].originCity = location.cityName
            } else {
                trips[currentTripIndex].destinationCode = location.iataCode
                trips[currentTripIndex].destinationCity = location.cityName
            }
        } else {
            // Update for return or one-way
            if isEditingOrigin {
                originCode = location.iataCode
                originCity = location.cityName
            } else {
                destinationCode = location.iataCode
                destinationCity = location.cityName
            }
        }
    }
}
