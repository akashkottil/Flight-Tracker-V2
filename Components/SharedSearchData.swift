import SwiftUI
import Combine

// MARK: - Shared Search Data Store
class SharedSearchDataStore: ObservableObject {
    static let shared = SharedSearchDataStore()
    
    @Published var isAnyModalVisible = false
    
    // Search execution trigger
    @Published var shouldExecuteSearch = false
    @Published var searchTimestamp = Date()
    
    @Published var isDirectFromHome = false
    
    // Tab bar visibility control
    @Published var isInSearchMode = false
    @Published var isInExploreNavigation = false
    
    // ADD: Account navigation state
    @Published var isInAccountNavigation = false
    
    // Search parameters
    @Published var fromLocation = ""
    @Published var toLocation = ""
    @Published var fromIataCode = ""
    @Published var toIataCode = ""
    @Published var selectedDates: [Date] = []
    @Published var isRoundTrip = true
    @Published var selectedTab = 0 // 0: Return, 1: One way, 2: Multi city
    
    @Published var adultsCount = 1
    @Published var childrenCount = 0
    @Published var childrenAges: [Int?] = []
    @Published var selectedCabinClass = "Economy"
    
    @Published var multiCityTrips: [MultiCityTrip] = []
    
    // Direct flights preference
    @Published var directFlightsOnly = false
    
    // Navigation trigger
    @Published var shouldNavigateToExplore = false
    
    // Country-to-cities navigation
    @Published var shouldNavigateToExploreCities = false
    @Published var selectedCountryId = ""
    @Published var selectedCountryName = ""
    
    // Tab navigation
    @Published var shouldNavigateToTab: Int? = nil
    
    @Published var savedMultiCityState: MultiCitySearchState? = nil
    @Published var isRestoringMultiCityState = false
    
    private init() {}
    
    func showModal() {
           isAnyModalVisible = true
       }
       
       func hideModal() {
           isAnyModalVisible = false
       }
    
    // Navigate to specific tab
    func navigateToTab(_ tabIndex: Int) {
        shouldNavigateToTab = tabIndex
    }
    
    // NEW: Account navigation methods
    func enterAccountNavigation() {
        isInAccountNavigation = true
    }
    
    func exitAccountNavigation() {
        isInAccountNavigation = false
    }
    
    // MARK: - Execute Search Methods
    func executeSearchFromHome(
        fromLocation: String,
        toLocation: String,
        fromIataCode: String,
        toIataCode: String,
        selectedDates: [Date],
        isRoundTrip: Bool,
        selectedTab: Int,
        adultsCount: Int,
        childrenCount: Int,
        childrenAges: [Int?],
        selectedCabinClass: String,
        multiCityTrips: [MultiCityTrip],
        directFlightsOnly: Bool = false
    ) {
        // Store all search parameters
        self.fromLocation = fromLocation
        self.toLocation = toLocation
        self.fromIataCode = fromIataCode
        self.toIataCode = toIataCode
        self.selectedDates = selectedDates
        self.isRoundTrip = isRoundTrip
        self.selectedTab = selectedTab
        self.adultsCount = adultsCount
        self.childrenCount = childrenCount
        self.childrenAges = childrenAges
        self.selectedCabinClass = selectedCabinClass
        self.multiCityTrips = multiCityTrips
        self.directFlightsOnly = directFlightsOnly
        
        // Clear any country navigation state
        self.shouldNavigateToExploreCities = false
        self.selectedCountryId = ""
        self.selectedCountryName = ""
        
        // Set search mode to hide tab bar
        self.isInSearchMode = true
        
        // NEW: Set direct from home flag
        self.isDirectFromHome = true
        
        // Trigger navigation to explore tab
        shouldNavigateToExplore = true
        
        // Trigger search execution with a slight delay to ensure tab switch completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldExecuteSearch = true
            self.searchTimestamp = Date()
        }
        
        if selectedTab == 2 {
            saveMultiCityState(
                fromLocation: fromLocation,
                toLocation: toLocation,
                fromIataCode: fromIataCode,
                toIataCode: toIataCode,
                selectedDates: selectedDates,
                multiCityTrips: multiCityTrips,
                adultsCount: adultsCount,
                childrenCount: childrenCount,
                childrenAges: childrenAges,
                selectedCabinClass: selectedCabinClass,
                directFlightsOnly: directFlightsOnly
            )
        }
        
        print("🔍 Multi-city search execution triggered from SharedSearchDataStore")
    }
    
    // Navigate to explore and show cities for a specific country
    func navigateToExploreCities(countryId: String, countryName: String) {
        // Clear any search state first
        self.shouldExecuteSearch = false
        self.fromLocation = ""
        self.toLocation = ""
        self.fromIataCode = ""
        self.toIataCode = ""
        self.selectedDates = []
        self.multiCityTrips = []
        self.directFlightsOnly = false
        
        // This is explore mode, not search mode
        self.isInSearchMode = false
        
        // Set country navigation state
        self.selectedCountryId = countryId
        self.selectedCountryName = countryName
        self.shouldNavigateToExploreCities = true
        
        // Trigger navigation to explore tab
        shouldNavigateToExplore = true
    }
    
    // Return to home and show tab bar
    func returnToHomeFromSearch() {
        isInSearchMode = false
        shouldNavigateToTab = 0 // Navigate back to home tab
        
        // Reset search state
        shouldExecuteSearch = false
        shouldNavigateToExplore = false
        
        // ADD this line to clear saved multi-city state when returning home
        clearSavedMultiCityState()
    }
    
    func resetSearch() {
        shouldExecuteSearch = false
        shouldNavigateToExplore = false
        directFlightsOnly = false
        shouldNavigateToTab = nil
        // UPDATED: Reset the direct from home flag when search is complete
        isDirectFromHome = false
    }
    
    // Method to completely reset everything
    func resetAll() {
            shouldExecuteSearch = false
            shouldNavigateToExplore = false
            shouldNavigateToExploreCities = false
            directFlightsOnly = false
            isInSearchMode = false
            isInExploreNavigation = false
            isInAccountNavigation = false
            isAnyModalVisible = false // ADD: Reset modal state
            selectedCountryId = ""
            selectedCountryName = ""
            fromLocation = ""
            toLocation = ""
            fromIataCode = ""
            toIataCode = ""
            selectedDates = []
            multiCityTrips = []
            shouldNavigateToTab = nil
        }
    
    // Helper method to check if search data is valid
    var hasValidSearchData: Bool {
        if selectedTab == 2 {
            // Multi-city validation
            return multiCityTrips.allSatisfy { trip in
                !trip.fromIataCode.isEmpty && !trip.toIataCode.isEmpty
            }
        } else {
            // Regular search validation
            return !fromIataCode.isEmpty && !toIataCode.isEmpty && !selectedDates.isEmpty
        }
    }
    
    func saveMultiCityState(
        fromLocation: String,
        toLocation: String,
        fromIataCode: String,
        toIataCode: String,
        selectedDates: [Date],
        multiCityTrips: [MultiCityTrip],
        adultsCount: Int,
        childrenCount: Int,
        childrenAges: [Int?],
        selectedCabinClass: String,
        directFlightsOnly: Bool
    ) {
        savedMultiCityState = MultiCitySearchState(
            fromLocation: fromLocation,
            toLocation: toLocation,
            fromIataCode: fromIataCode,
            toIataCode: toIataCode,
            selectedDates: selectedDates,
            multiCityTrips: multiCityTrips,
            adultsCount: adultsCount,
            childrenCount: childrenCount,
            childrenAges: childrenAges,
            selectedCabinClass: selectedCabinClass,
            directFlightsOnly: directFlightsOnly
        )
        print("💾 Multi-city state saved with \(multiCityTrips.count) trips")
    }

    func restoreMultiCityState() -> MultiCitySearchState? {
        guard let state = savedMultiCityState else {
            print("⚠️ No saved multi-city state to restore")
            return nil
        }
        
        isRestoringMultiCityState = true
        print("🔄 Restoring multi-city state with \(state.multiCityTrips.count) trips")
        
        // Restore the state
        fromLocation = state.fromLocation
        toLocation = state.toLocation
        fromIataCode = state.fromIataCode
        toIataCode = state.toIataCode
        selectedDates = state.selectedDates
        multiCityTrips = state.multiCityTrips
        adultsCount = state.adultsCount
        childrenCount = state.childrenCount
        childrenAges = state.childrenAges
        selectedCabinClass = state.selectedCabinClass
        directFlightsOnly = state.directFlightsOnly
        
        // Reset restoration flag after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isRestoringMultiCityState = false
        }
        
        return state
    }

    func clearSavedMultiCityState() {
        savedMultiCityState = nil
        isRestoringMultiCityState = false
        print("🗑️ Cleared saved multi-city state")
    }
}

// MARK: - Multi-City Search State Structure
struct MultiCitySearchState {
    let fromLocation: String
    let toLocation: String
    let fromIataCode: String
    let toIataCode: String
    let selectedDates: [Date]
    let multiCityTrips: [MultiCityTrip]
    let adultsCount: Int
    let childrenCount: Int
    let childrenAges: [Int?]
    let selectedCabinClass: String
    let directFlightsOnly: Bool
}
