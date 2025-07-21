import Foundation
import Combine

// MARK: - Updated SharedFlightSearchViewModel for HomeView with Last Search Persistence (Modified)
class SharedFlightSearchViewModel: ObservableObject {
    @Published var fromLocation = "Departure?"
    @Published var toLocation = "Destination?"
    @Published var fromIataCode: String = ""
    @Published var toIataCode: String = ""
    
    @Published var selectedDates: [Date] = []
    @Published var isRoundTrip: Bool = true
    @Published var selectedTab = 0 // 0: Return, 1: One way, 2: Multi city
    
    @Published var adultsCount = 1
    @Published var childrenCount = 0
    @Published var childrenAges: [Int?] = []
    @Published var selectedCabinClass = "Economy"
    
    @Published var multiCityTrips: [MultiCityTrip] = []
    
    // ADD: Direct flights toggle state
    @Published var directFlightsOnly = false
    
    // ADD: Last search manager
    private let lastSearchManager = LastSearchManager.shared
    
    // ADD: Track if we've loaded the last search (to prevent multiple loads)
    private var hasLoadedLastSearch = false
    
    init() {
        // Load last search on initialization
        loadLastSearchState()
    }
    
    // MARK: - Last Search Persistence Methods
    
    // MODIFIED: Load the last search state but always use default dates
    func loadLastSearchState() {
        guard !hasLoadedLastSearch else { return }
        hasLoadedLastSearch = true
        
        guard let lastSearch = lastSearchManager.loadLastSearch() else {
            print("📭 No valid last search to restore")
            setDefaultDates() // Set default dates even when no last search
            return
        }
        
        print("🔄 Restoring last search state...")
        
        // Restore all search parameters EXCEPT dates
        fromLocation = lastSearch.fromLocation
        toLocation = lastSearch.toLocation
        fromIataCode = lastSearch.fromIataCode
        toIataCode = lastSearch.toIataCode
        // selectedDates = lastSearch.selectedDates // REMOVED: Don't restore old dates
        isRoundTrip = lastSearch.isRoundTrip
        selectedTab = lastSearch.selectedTab
        adultsCount = lastSearch.adultsCount
        childrenCount = lastSearch.childrenCount
        childrenAges = lastSearch.childrenAges
        selectedCabinClass = lastSearch.selectedCabinClass
        multiCityTrips = lastSearch.multiCityTrips
        directFlightsOnly = lastSearch.directFlightsOnly
        
        // ADDED: Always set default dates instead of restoring old ones
        setDefaultDates()
        
        print("✅ Last search state restored successfully (with default dates)")
        print("🔍 Route: \(fromIataCode) → \(toIataCode)")
    }
    
    // ADDED: Method to set default dates
    private func setDefaultDates() {
        let calendar = Calendar.current
        let today = Date()
        
        if isRoundTrip {
            // For round trip: today + 1 day as departure, today + 8 days as return
            let departureDate = calendar.date(byAdding: .day, value: 1, to: today) ?? today
            let returnDate = calendar.date(byAdding: .day, value: 8, to: today) ?? today
            selectedDates = [departureDate, returnDate]
        } else {
            // For one-way: today + 1 day as departure
            let departureDate = calendar.date(byAdding: .day, value: 1, to: today) ?? today
            selectedDates = [departureDate]
        }
        
        // Also update multi-city trips with default dates
        updateMultiCityDatesWithDefaults()
    }
    
    // ADDED: Method to update multi-city trips with default dates
    private func updateMultiCityDatesWithDefaults() {
        let calendar = Calendar.current
        let baseDate = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        
        for index in multiCityTrips.indices {
            let tripDate = calendar.date(byAdding: .day, value: index + 1, to: baseDate) ?? baseDate
            multiCityTrips[index].date = tripDate
        }
    }
    
    // Save the current search state
    private func saveLastSearchState() {
        lastSearchManager.saveLastSearch(
            fromLocation: fromLocation,
            toLocation: toLocation,
            fromIataCode: fromIataCode,
            toIataCode: toIataCode,
            selectedDates: selectedDates,
            isRoundTrip: isRoundTrip,
            selectedTab: selectedTab,
            adultsCount: adultsCount,
            childrenCount: childrenCount,
            childrenAges: childrenAges,
            selectedCabinClass: selectedCabinClass,
            multiCityTrips: multiCityTrips,
            directFlightsOnly: directFlightsOnly
        )
    }
    
    // MODIFIED: When changing trip type, update dates accordingly
    func updateTripType(newTab: Int, newIsRoundTrip: Bool) {
        selectedTab = newTab
        isRoundTrip = newIsRoundTrip
        
        // Always refresh dates when trip type changes
        setDefaultDates()
    }
    
    // MARK: - Existing Methods (Updated)
    
    func executeMultiCitySearch() {
        // Validate all trips have required data
        let isValid = multiCityTrips.allSatisfy { trip in
            !trip.fromIataCode.isEmpty && !trip.toIataCode.isEmpty
        }
        
        guard isValid else {
            print("❌ Multi-city validation failed")
            return
        }
        
        // ENHANCED: Save to recent searches with complete data before executing
        saveToRecentSearches()
        
        // NEW: Save last search state
        saveLastSearchState()
        
        // Pass direct flights preference
        SharedSearchDataStore.shared.executeSearchFromHome(
            fromLocation: fromLocation,
            toLocation: toLocation,
            fromIataCode: fromIataCode,
            toIataCode: toIataCode,
            selectedDates: selectedDates,
            isRoundTrip: isRoundTrip,
            selectedTab: selectedTab,
            adultsCount: adultsCount,
            childrenCount: childrenCount,
            childrenAges: childrenAges,
            selectedCabinClass: selectedCabinClass,
            multiCityTrips: multiCityTrips,
            directFlightsOnly: directFlightsOnly
        )
        
        print("✅ Multi-city search executed with \(multiCityTrips.count) trips")
    }
    
    // Use the shared recent search manager
    var recentSearchManager: RecentSearchManager {
        return RecentSearchManager.shared
    }
   
    // MODIFIED: Initialize multi-city trips with default dates
    func initializeMultiCityTrips() {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        
        multiCityTrips = [
            MultiCityTrip(fromLocation: "Departure?", fromIataCode: "",
                         toLocation: "Destination?", toIataCode: "", date: tomorrow),
            MultiCityTrip(fromLocation: "Departure?", fromIataCode: "",
                         toLocation: "Destination?", toIataCode: "", date: dayAfterTomorrow)
        ]
    }

    // Update children ages array when count changes
    func updateChildrenAgesArray(for newCount: Int) {
        if newCount > childrenAges.count {
            childrenAges.append(contentsOf: Array(repeating: nil, count: newCount - childrenAges.count))
        } else if newCount < childrenAges.count {
            childrenAges = Array(childrenAges.prefix(newCount))
        }
    }
    
    // UPDATED: executeSearch to use enhanced recent search saving and last search persistence
    func executeSearch() {
        // ENHANCED: Save to recent searches with complete data before executing
        saveToRecentSearches()
        
        // NEW: Save last search state
        saveLastSearchState()
        
        // Pass direct flights preference
        SharedSearchDataStore.shared.executeSearchFromHome(
            fromLocation: fromLocation,
            toLocation: toLocation,
            fromIataCode: fromIataCode,
            toIataCode: toIataCode,
            selectedDates: selectedDates,
            isRoundTrip: isRoundTrip,
            selectedTab: selectedTab,
            adultsCount: adultsCount,
            childrenCount: childrenCount,
            childrenAges: childrenAges,
            selectedCabinClass: selectedCabinClass,
            multiCityTrips: multiCityTrips,
            directFlightsOnly: directFlightsOnly
        )
        
        print("✅ Search executed and saved to recent searches")
    }
    
    // ENHANCED: Save current search to recent searches with complete information
    private func saveToRecentSearches() {
        // Only save if we have valid from/to locations
        guard !fromIataCode.isEmpty && !toIataCode.isEmpty,
              fromLocation != "Departure?" && toLocation != "Destination?" else {
            print("⚠️ Skipping recent search save - incomplete location data")
            return
        }
        
        // Determine departure and return dates
        var departureDate: Date? = nil
        var returnDate: Date? = nil
        
        if !selectedDates.isEmpty {
            let sortedDates = selectedDates.sorted()
            departureDate = sortedDates.first
            
            if isRoundTrip && sortedDates.count >= 2 {
                returnDate = sortedDates.last
            }
        }
        
        // ENHANCED: Save with complete data using the new enhanced method
        recentSearchManager.addRecentSearch(
            fromLocation: fromLocation,
            toLocation: toLocation,
            fromIataCode: fromIataCode,
            toIataCode: toIataCode,
            adultsCount: adultsCount,
            childrenCount: childrenCount,
            childrenAges: childrenAges,
            cabinClass: selectedCabinClass,
            isRoundTrip: isRoundTrip,
            selectedTab: selectedTab,
            departureDate: departureDate,
            returnDate: returnDate
        )
        
        print("✅ Enhanced recent search saved:")
        print("🔍 Route: \(fromIataCode) → \(toIataCode)")
        print("👥 Passengers: \(adultsCount) adults, \(childrenCount) children")
        print("✈️ Trip Type: \(isRoundTrip ? "Round Trip" : "One Way")")
        print("🏷️ Class: \(selectedCabinClass)")
    }
    
    // Keep the old method for backward compatibility (but it now does the same thing)
    func executeSearchWithHistory() {
        executeSearch()
    }
    
    // NEW: Method to manually clear the last search (useful for testing or user action)
    func clearLastSearch() {
        lastSearchManager.clearLastSearch()
    }
    
    // NEW: Check if current state matches last search
    func hasLastSearchData() -> Bool {
        return !fromIataCode.isEmpty && !toIataCode.isEmpty &&
               fromLocation != "Departure?" && toLocation != "Destination?"
    }
    
    // 🔥 NEW: Helper properties for UI display
    var routeDisplay: String {
        if selectedTab == 2 {
            // Multi-city route display
            if multiCityTrips.isEmpty { return "Multi-city" }
            
            var codes = multiCityTrips.compactMap { trip in
                trip.fromIataCode.isEmpty ? nil : trip.fromIataCode
            }
            
            if let lastTrip = multiCityTrips.last, !lastTrip.toIataCode.isEmpty {
                codes.append(lastTrip.toIataCode)
            }
            
            return codes.joined(separator: " → ")
        } else {
            // Regular route display
            if fromIataCode.isEmpty && toIataCode.isEmpty {
                return "Select route"
            } else if fromIataCode.isEmpty {
                return "FROM → \(toIataCode)"
            } else if toIataCode.isEmpty {
                return "\(fromIataCode) → TO"
            } else {
                return "\(fromIataCode) → \(toIataCode)"
            }
        }
    }
    
    // Get passenger count display
    var passengerDisplay: String {
        let total = adultsCount + childrenCount
        return "\(total) \(total == 1 ? "Person" : "People")"
    }
    
    // Get dates display
    var datesDisplay: String {
        if selectedDates.isEmpty { return "Select dates" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        
        if selectedDates.count == 1 {
            return formatter.string(from: selectedDates[0])
        } else if selectedDates.count >= 2 {
            let departure = formatter.string(from: selectedDates[0])
            let returnDate = formatter.string(from: selectedDates[1])
            return "\(departure) - \(returnDate)"
        }
        
        return "Select dates"
    }
}
