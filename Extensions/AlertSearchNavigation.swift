import SwiftUI
import Foundation

// MARK: - Alert Search Navigation Extension
extension SharedSearchDataStore {
    func executeSearchFromAlert(
        fromLocationCode: String,
        fromLocationName: String,
        toLocationCode: String,
        toLocationName: String,
        departureDate: Date,
        adultsCount: Int,
        childrenCount: Int,
        selectedCabinClass: String
    ) {
        // Clear any existing search state
        self.resetAll()
        
        // Set search parameters from alert
        self.fromLocation = fromLocationName
        self.toLocation = toLocationName
        self.fromIataCode = fromLocationCode
        self.toIataCode = toLocationCode
        self.selectedDates = [departureDate]
        self.isRoundTrip = false
        self.selectedTab = 1
        self.adultsCount = adultsCount           // UPDATED: Use actual values
        self.childrenCount = childrenCount       // UPDATED: Use actual values
        self.selectedCabinClass = selectedCabinClass  // UPDATED: Use actual values
        self.childrenAges = Array(repeating: nil, count: childrenCount) // Generate appropriate array
        self.directFlightsOnly = false
        
        // Set navigation flags
        self.isInSearchMode = true
        self.isDirectFromHome = true
        self.shouldExecuteSearch = true
        self.shouldNavigateToExplore = true
        self.searchTimestamp = Date()
        
        print("🚨 Alert Search: \(fromLocationName) → \(toLocationName) with \(adultsCount + childrenCount) passengers (\(selectedCabinClass))")
    }
}
