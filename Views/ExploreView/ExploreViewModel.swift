import Foundation
import Combine
import Alamofire



class ExploreViewModel: ObservableObject {
    @Published var hasInitialResultsLoaded = false
    private static var cachedDestinations: [ExploreDestination]? = nil
    private static var lastCachedCurrency: String? = nil
    private static var lastCachedCountry: String? = nil
    @Published var destinations: [ExploreDestination] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var showingCities = false
    @Published var selectedCountryName: String? = nil
    @Published var fromLocation = "Kochi"  // Default to Kochi
    @Published var toLocation = "Anywhere"  // Default to Chennai
    @Published var selectedCity: ExploreDestination? = nil
    
    @Published var availableMonths: [Date] = []
    @Published var selectedMonthIndex: Int = 0
    
    // Updated flight results properties
    @Published var flightSearchResponse: FlightSearchResponse?
    @Published var flightResults: [FlightResult] = []
    @Published var isLoadingFlights = false

    @Published var selectedDepartureDate = Date()
    @Published var selectedReturnDate: Date?
   
    @Published var hasSearchedFlights = false
    
    @Published var fromIataCode: String = "COK"
    @Published var toIataCode: String = ""
    
    @Published var selectedFlightDetail: FlightDetailResult?
    @Published var isLoadingFlightDetails = false
    @Published var showingDetailedFlightCard = false
    
    @Published var detailedFlightResults: [FlightDetailResult] = []
    @Published var isLoadingDetailedFlights = false
    @Published var detailedFlightError: String? = nil
    @Published var showingDetailedFlightList = false
    @Published var selectedDepartureDatee: String = ""
    @Published var selectedReturnDatee: String = ""
    @Published var selectedOriginCode: String = ""
    @Published var selectedDestinationCode: String = ""
    
    @Published var dates: [Date] = []
    
    @Published var isRoundTrip: Bool = true
    
    // Add this to the ExploreViewModel class
    @Published var multiCityTrips: [MultiCityTrip] = []

    
    @Published var adultsCount = 1
    @Published var childrenCount = 0
    @Published var childrenAges: [Int?] = []
    @Published var selectedCabinClass = "Economy"
    @Published var showingPassengersSheet = false
    
    
    @Published var isAnytimeMode: Bool = false
    
    @Published var selectedFlightId: String? = nil
    
    @Published var directFlightsOnlyFromHome = false
    
    // Pagination properties
    @Published var currentPage = 1
    @Published var totalFlightCount = 0
    @Published var isLoadingMoreFlights = false
    @Published var hasMoreFlights = true
    @Published var currentSearchId: String? = nil
    
    @Published var isFirstLoad: Bool = true
    
    @Published var isDataCached = false
    @Published var actualLoadedCount = 0
    
    @Published var showNoResultsModal = false
    @Published var isInitialEmptyResult = false
    

    // REPLACE the handleSwitchToMultiCity method in ExploreViewModel.swift

    func handleSwitchToMultiCity() {
        print("🔄 Switching back to multi-city mode")
        
        let sharedData = SharedSearchDataStore.shared
        
        // Restore saved multi-city state if available
        if let restoredState = sharedData.restoreMultiCityState() {
            print("✅ Restored multi-city state with \(restoredState.multiCityTrips.count) trips")
            
            // Update view model with restored state
            fromLocation = restoredState.fromLocation
            toLocation = restoredState.toLocation
            fromIataCode = restoredState.fromIataCode
            toIataCode = restoredState.toIataCode
            dates = restoredState.selectedDates
            multiCityTrips = restoredState.multiCityTrips
            adultsCount = restoredState.adultsCount
            childrenCount = restoredState.childrenCount
            childrenAges = restoredState.childrenAges
            selectedCabinClass = restoredState.selectedCabinClass
            directFlightsOnlyFromHome = restoredState.directFlightsOnly
            
            // Update selected codes from first and last trips
            if !restoredState.multiCityTrips.isEmpty {
                let firstTrip = restoredState.multiCityTrips[0]
                let lastTrip = restoredState.multiCityTrips.last!
                
                selectedOriginCode = firstTrip.fromIataCode
                selectedDestinationCode = lastTrip.toIataCode
            }
            
            // Clear current results and set loading state
            detailedFlightResults = []
            flightResults = []
            isLoadingDetailedFlights = true
            detailedFlightError = nil
            
            // Execute multi-city search using your existing method
            if hasValidMultiCityData() {
                print("🔍 Executing multi-city search with restored data")
                
                // Use your existing searchMultiCityFlights method
                searchMultiCityFlights()
                
            } else {
                print("⚠️ Invalid multi-city data after restoration")
                isLoadingDetailedFlights = false
            }
        } else {
            // No saved state, initialize empty multi-city trips
            print("ℹ️ No saved multi-city state, initializing new trips")
            initializeMultiCityTrips()
        }
    }

    // ADD this helper method
    private func hasValidMultiCityData() -> Bool {
        return multiCityTrips.count >= 2 &&
               multiCityTrips.allSatisfy { trip in
                   !trip.fromIataCode.isEmpty && !trip.toIataCode.isEmpty
               }
    }
    
    func switchToMultiCity() {
        print("🔄 Switching to multi-city mode")
        
        // Re-initialize multi-city trips based on current from/to locations
        if !fromIataCode.isEmpty && !toIataCode.isEmpty {
            let calendar = Calendar.current
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: Date()) ?? Date()
            
            multiCityTrips = [
                MultiCityTrip(
                    fromLocation: fromLocation,
                    fromIataCode: fromIataCode,
                    toLocation: toLocation,
                    toIataCode: toIataCode,
                    date: tomorrow
                ),
                MultiCityTrip(
                    fromLocation: toLocation,
                    fromIataCode: toIataCode,
                    toLocation: "",
                    toIataCode: "",
                    date: dayAfterTomorrow
                )
            ]
        }
        
        // Execute multi-city search if we have valid data
        if multiCityTrips.count >= 2 && multiCityTrips.allSatisfy({ !$0.fromIataCode.isEmpty && !$0.toIataCode.isEmpty }) {
            searchMultiCityFlights()
        }
    }
    
    func formatPrice(_ price: Int) -> String {
        return CurrencyManager.shared.formatPrice(price)
    }

    func formatPrice(_ price: Double) -> String {
        return CurrencyManager.shared.formatPrice(price)
    }
    
    // Helper method to get API minimum price (add this if it doesn't exist)
        func getApiMinPrice() -> Double {
            if let pollResponse = lastPollResponse {
                return pollResponse.minPrice
            } else {
                return 0.0
            }
        }
        
        // Helper method to get API maximum price (add this if it doesn't exist)
        func getApiMaxPrice() -> Double {
            if let pollResponse = lastPollResponse {
                return pollResponse.maxPrice
            } else {
                return 5000.0
            }
        }
    
    // 🔥 ADD: Save search to recent searches when search is executed in ExploreViewModel
    private func saveSearchToRecentAndLastSearch() {
        // Only save valid searches
        guard !selectedOriginCode.isEmpty && !selectedDestinationCode.isEmpty &&
              fromLocation != "Departure?" && toLocation != "Destination?" &&
              fromLocation != "Where from?" && toLocation != "Where to?" else {
            print("⚠️ Skipping search save - invalid data")
            return
        }
        
        // Save to recent searches
        RecentSearchManager.shared.addRecentSearch(
            fromLocation: fromLocation,
            toLocation: toLocation,
            fromIataCode: selectedOriginCode,
            toIataCode: selectedDestinationCode,
            adultsCount: adultsCount,
            childrenCount: childrenCount,
            childrenAges: childrenAges,
            cabinClass: selectedCabinClass,
            isRoundTrip: isRoundTrip,
            selectedTab: isRoundTrip ? 0 : 1, // Determine tab based on trip type
            departureDate: dates.first,
            returnDate: dates.count > 1 ? dates[1] : nil
        )
        
        // Save to last search
        LastSearchManager.shared.saveLastSearch(
            fromLocation: fromLocation,
            toLocation: toLocation,
            fromIataCode: selectedOriginCode,
            toIataCode: selectedDestinationCode,
            selectedDates: dates,
            isRoundTrip: isRoundTrip,
            selectedTab: isRoundTrip ? 0 : 1,
            adultsCount: adultsCount,
            childrenCount: childrenCount,
            childrenAges: childrenAges,
            selectedCabinClass: selectedCabinClass,
            multiCityTrips: multiCityTrips,
            directFlightsOnly: directFlightsOnlyFromHome
        )
        
        print("✅ Search saved from ExploreViewModel: \(selectedOriginCode) → \(selectedDestinationCode)")
    }
    
    func handleTryDifferentSearch() {
        print("🔄 User requested different search from modal")
        showNoResultsModal = false
        isInitialEmptyResult = false
        
        // Navigate back to search form
        if isDirectSearch {
            clearSearchFormAndReturnToExplore()
        } else {
            goBackToFlightResults()
        }
    }

    func handleClearFilters() {
        print("🧹 User requested clear filters from modal")
        showNoResultsModal = false
        isInitialEmptyResult = false
        
        // Reset filters and try search again
        _currentFilterRequest = nil
        resetFilterSheetState()
        
        // Retry the search with no filters
        if !selectedOriginCode.isEmpty && !selectedDestinationCode.isEmpty && !selectedDepartureDatee.isEmpty {
            searchFlightsForDatesWithPagination(
                origin: selectedOriginCode,
                destination: selectedDestinationCode,
                returnDate: selectedReturnDatee,
                departureDate: selectedDepartureDatee,
                isDirectSearch: isDirectSearch
            )
        }
    }
    
    func resetFilterSheetStateForNewSearch() {
        filterSheetState = FilterSheetState()
        print("🧹 Filter sheet state reset for new search")
    }
    
    func handleFlightResults(_ results: [FlightResult]) {
            // Filter out invalid results before setting
            let validResults = results.filter { result in
                // Ensure we have valid data
                !result.outbound.origin.iata.isEmpty &&
                !result.outbound.destination.iata.isEmpty &&
                result.price > 0 &&
                result.outbound.departure != nil
            }
            
            DispatchQueue.main.async {
                self.flightResults = validResults
                self.isLoadingFlights = false
                
                if validResults.isEmpty {
                    self.errorMessage = "No flights found for this route"
                } else {
                    self.errorMessage = nil
                }
            }
        }
    
    // Add this method to ExploreViewModel
    func resetFilterSheetState() {
        filterSheetState = FilterSheetState()
        print("🧹 Filter sheet state reset to defaults")
    }
    
    func getFilterPreviewCount(filterRequest: FlightFilterRequest) -> AnyPublisher<Int, Error> {
        guard let searchId = currentSearchId else {
            return Fail(error: NSError(domain: "ExploreViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "No search ID available"]))
                .eraseToAnyPublisher()
        }
        
        print("🔍 Getting filter preview count for searchId: \(searchId)")
        
        return service.pollFlightResultsPaginated(
            searchId: searchId,
            page: 1,
            limit: 1, // We only need the count, not the actual results
            filterRequest: filterRequest
        )
        .map { response in
            print("📊 Preview count response: \(response.count) flights")
            return response.count
        }
        .eraseToAnyPublisher()
    }
    // Add this method inside the ExploreViewModel class

    func resetToInitialState(preserveCountries: Bool = true) {
        print("🔄 Resetting ExploreViewModel to initial state")
            
        // Reset all search-related states
        isDirectSearch = false
        showingDetailedFlightList = false
        hasSearchedFlights = false
        flightResults = []
        detailedFlightResults = []
        flightSearchResponse = nil
        selectedFlightId = nil
        isAnytimeMode = false
        directFlightsOnlyFromHome = false

        // IMPORTANT: Reset filters
        _currentFilterRequest = nil
        resetFilterSheetState()
            
        // Reset navigation states
        showingCities = false
        selectedCountryName = nil
        selectedCity = nil
            
        // Reset location states to default - FIXED to always show COK Kochi
        toLocation = "Anywhere"
        toIataCode = ""
        fromLocation = "Kochi"  // Always reset to Kochi
        fromIataCode = "COK"    // Always reset to COK
            
        // Clear search context
        selectedOriginCode = ""
        selectedDestinationCode = ""
        selectedDepartureDatee = ""
        selectedReturnDatee = ""
        dates = []
            
        // Reset error states
        errorMessage = nil
        detailedFlightError = nil
        isLoadingDetailedFlights = false
        isLoadingFlights = false
            
        // Reset pagination
        currentPage = 1
        totalFlightCount = 0
        actualLoadedCount = 0
        hasMoreFlights = true
        isLoadingMoreFlights = false
        isFirstLoad = true
        isDataCached = false
            
        // Clear multi-city data
        multiCityTrips = []
            
        // Set loading state if destinations will be cleared
        if !preserveCountries {
            destinations = []
        }
        if destinations.isEmpty {
            isLoading = true
            print("🔄 Setting loading state during reset (destinations empty)")
        }
            
        print("✅ ExploreViewModel reset completed - fromLocation: \(fromLocation), fromIataCode: \(fromIataCode)")
    }
    
    func debugDuplicateFlightIDs() {
            let allIds = detailedFlightResults.map { $0.id }
            let uniqueIds = Set(allIds)
            
            if allIds.count != uniqueIds.count {
                print("🚨 DUPLICATE IDs DETECTED!")
                print("Total flights: \(allIds.count)")
                print("Unique IDs: \(uniqueIds.count)")
                
                // Find and print duplicates
                var idCounts: [String: Int] = [:]
                for id in allIds {
                    idCounts[id, default: 0] += 1
                }
                
                let duplicates = idCounts.filter { $0.value > 1 }
                print("Duplicate IDs: \(duplicates)")
            } else {
                print("✅ No duplicate IDs found. Total unique flights: \(uniqueIds.count)")
            }
        }
    
    func searchMultiCityFlightsWithPagination() {
        isLoadingDetailedFlights = true
        detailedFlightError = nil
        detailedFlightResults = []
        showingDetailedFlightList = true
        
        // Reset pagination
        currentPage = 1
        totalFlightCount = 0
        actualLoadedCount = 0
        isDataCached = false
        hasMoreFlights = true
        isLoadingMoreFlights = false
        isFirstLoad = true
        
        // Store the first and last cities for display
        selectedOriginCode = multiCityTrips.first?.fromIataCode ?? ""
        selectedDestinationCode = multiCityTrips.last?.toIataCode ?? ""
        
        saveSearchToRecentAndLastSearch()
        
        // CRITICAL FIX: Reset filters for new search
        _currentFilterRequest = nil
        resetFilterSheetState()
        
        // Create request payload using the existing searchFlights method
        var legs: [[String: String]] = []
        
        for trip in multiCityTrips {
            legs.append([
                "origin": trip.fromIataCode,
                "destination": trip.toIataCode,
                "date": trip.formattedDate
            ])
        }
        
        print("Searching multi-city with pagination: \(legs.count) legs")
        
        let validChildrenAges = childrenAges.compactMap { $0 }
        
        let baseURL = "https://staging.plane.lascade.com/api/search/"
        
        let parameters: [String: String] = [
            "user_id": "-0",
            "currency": service.currency,
            "language": "en-GB",
            "app_code": "D1WF"
        ]
        
        let requestData: [String: Any] = [
            "legs": legs,
            "cabin_class": selectedCabinClass.lowercased(),
            "adults": adultsCount,
            "children_ages": validChildrenAges
        ]
        
        var urlComponents = URLComponents(string: baseURL)!
        urlComponents.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("IN", forHTTPHeaderField: "country")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestData)
        
        AF.request(request)
            .validate()
            .responseDecodable(of: SearchResponse.self) { [weak self] response in
                guard let self = self else { return }
                
                switch response.result {
                case .success(let searchResponse):
                    self.hasInitialResultsLoaded = true
                    print("Multi-city search successful, got searchId: \(searchResponse.searchId)")
                    self.currentSearchId = searchResponse.searchId
                    
                    // CRITICAL FIX: First poll with NO filters
                    self.service.pollFlightResultsPaginated(
                        searchId: searchResponse.searchId,
                        page: 1,
                        limit: 30,
                        filterRequest: nil  // CRITICAL: NO filters for initial search
                    )
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                print("Multi-city flight search failed: \(error.localizedDescription)")
                                self.isLoadingDetailedFlights = false
                                self.detailedFlightError = error.localizedDescription
                            }
                        },
                        receiveValue: { pollResponse in
                            self.handlePollResponse(pollResponse, isInitialLoad: true)
                        }
                    )
                    .store(in: &self.cancellables)
                    
                case .failure(let error):
                    print("Multi-city search API error: \(error.localizedDescription)")
                    self.isLoadingDetailedFlights = false
                    self.detailedFlightError = error.localizedDescription
                }
            }
    }

    func searchFlightsForDatesWithPagination(origin: String, destination: String, returnDate: String, departureDate: String, isDirectSearch: Bool = false) {
        print("🔍 Starting search: \(origin) -> \(destination)")
        
        // Immediately set loading state
        self.isDirectSearch = isDirectSearch
        isLoadingDetailedFlights = true
        detailedFlightError = nil
        detailedFlightResults = []
        showingDetailedFlightList = true
        
        // Reset pagination and cache tracking
        currentPage = 1
        totalFlightCount = 0
        actualLoadedCount = 0
        isDataCached = false
        hasMoreFlights = true
        isLoadingMoreFlights = false
        isFirstLoad = true
        
        saveSearchToRecentAndLastSearch()
        
        // CRITICAL FIX: Reset filters for new search - start with NO filters
        _currentFilterRequest = nil
        resetFilterSheetState()
        
        // Store search parameters
        selectedOriginCode = origin
        selectedDestinationCode = destination
        selectedDepartureDatee = departureDate
        selectedReturnDatee = returnDate
        
        // Start the search process
        service.searchFlights(
            origin: origin,
            destination: destination,
            returndate: isRoundTrip ? selectedReturnDatee : "",
            departuredate: selectedDepartureDatee,
            roundTrip: isRoundTrip,
            adults: adultsCount,
            childrenAges: childrenAges,
            cabinClass: selectedCabinClass
        )
        .receive(on: DispatchQueue.main)
        .flatMap { [weak self] searchResponse -> AnyPublisher<FlightPollResponse, Error> in
            guard let self = self else {
                return Fail(error: NSError(domain: "ViewModelError", code: 0, userInfo: [NSLocalizedDescriptionKey: "View model deallocated"]))
                    .eraseToAnyPublisher()
            }
            
            print("🔍 Search successful, got searchId: \(searchResponse.searchId)")
            self.currentSearchId = searchResponse.searchId
            
            // CRITICAL FIX: First poll should be with NO filters (empty body {})
            return self.service.pollFlightResultsPaginated(
                searchId: searchResponse.searchId,
                page: 1,
                limit: 30,  // Use consistent limit
                filterRequest: nil  // CRITICAL: NO filters for initial search
            )
        }
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                if case .failure(let error) = completion {
                    print("❌ Flight search failed: \(error.localizedDescription)")
                    self.detailedFlightError = error.localizedDescription
                }
                
                // Only set loading to false if we have results or an error
                if !self.detailedFlightResults.isEmpty || self.detailedFlightError != nil {
                    self.isLoadingDetailedFlights = false
                }
            },
            receiveValue: { [weak self] pollResponse in
                guard let self = self else { return }
                
                self.handlePollResponse(pollResponse, isInitialLoad: true)
            }
        )
        .store(in: &cancellables)
    }
    
    private func handlePollResponse(_ pollResponse: FlightPollResponse, isInitialLoad: Bool = false) {
        // Always update tracking variables
        self.totalFlightCount = pollResponse.count
        self.isDataCached = pollResponse.cache
        self.actualLoadedCount = pollResponse.results.count
        self.detailedFlightResults = pollResponse.results
        self.detailedFlightError = nil
        
        // Store the last poll response for filter operations
        self.lastPollResponse = pollResponse
        
        // Set hasInitialResultsLoaded when we get results
        if !pollResponse.results.isEmpty {
            self.hasInitialResultsLoaded = true
            print("✅ Initial results loaded: \(pollResponse.results.count) flights received")
        }
        
        // CRITICAL: Handle different cache states properly
        if pollResponse.cache {
            // Backend finished processing - final results
            if pollResponse.count == 0 && isInitialLoad {
                // This is an initial empty result - show modal
                print("🚨 Initial empty result detected (cache: true, count: 0)")
                self.isInitialEmptyResult = true
                self.showNoResultsModal = true
                self.hasMoreFlights = false
                self.detailedFlightError = nil
            } else {
                // We have results or this is not initial load
                self.hasMoreFlights = pollResponse.next != nil
                if pollResponse.count == 0 {
                    self.detailedFlightError = "No flights found for this route and date"
                    self.hasMoreFlights = false
                }
            }
            self.hasInitialResultsLoaded = true
            self.isLoadingDetailedFlights = false
            print("✅ Search complete (cached): \(pollResponse.results.count)/\(pollResponse.count) flights, hasMore: \(self.hasMoreFlights)")
        } else {
            // Backend still processing - continue polling automatically
            self.hasMoreFlights = true
            print("🔄 Search (processing): \(pollResponse.results.count)/\(pollResponse.count) flights, backend still processing")
            
            // Set hasInitialResultsLoaded even when backend is still processing
            if !pollResponse.results.isEmpty {
                self.hasInitialResultsLoaded = true
                print("✅ Initial results received while backend processing: \(pollResponse.results.count) flights")
            }
            
            // FIXED: Continue polling automatically until cache becomes true
            if pollResponse.results.isEmpty || pollResponse.results.count < 10 {
                self.scheduleContinuousPolling()
            } else {
                // We have some results, but backend is still processing
                self.isLoadingDetailedFlights = false
            }
        }
        
        // Mark first load complete
        if isInitialLoad {
            self.isFirstLoad = false
        }
    }
    
    private func scheduleContinuousPolling() {
        guard let searchId = self.currentSearchId,
              !self.isDataCached else {
            print("🛑 Stopping continuous polling - data cached or no search ID")
            return
        }
        
        print("🔄 Scheduling continuous polling (cache=false)...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self,
                  let searchId = self.currentSearchId,
                  !self.isDataCached else {
                print("🛑 Continuous polling cancelled - data cached or no search ID")
                return
            }
            
            print("🔄 Executing continuous poll for more results")
            
            // Use larger limit for continuous polling to get more results faster
            self.service.pollFlightResultsPaginated(
                searchId: searchId,
                page: 1,  // Always use page 1 for continuous polling
                limit: 50,  // Larger limit for faster data gathering
                filterRequest: self._currentFilterRequest
            )
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Continuous polling failed: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] pollResponse in
                    guard let self = self else { return }
                    
                    // Update data with latest results
                    self.totalFlightCount = pollResponse.count
                    self.isDataCached = pollResponse.cache
                    
                    // CRITICAL: Replace results entirely for continuous polling (not append)
                    self.detailedFlightResults = pollResponse.results
                    self.actualLoadedCount = pollResponse.results.count
                    
                    // Update pagination state
                    self.hasMoreFlights = pollResponse.next != nil
                    
                    print("🔄 Continuous poll result: \(pollResponse.results.count)/\(pollResponse.count) flights, cache: \(pollResponse.cache)")
                    
                    // Continue polling if cache is still false
                    if !pollResponse.cache {
                        self.scheduleContinuousPolling()
                    } else {
                        // Backend finished processing
                        print("✅ Continuous polling complete - backend finished processing")
                        self.isLoadingDetailedFlights = false
                    }
                }
            )
            .store(in: &self.cancellables)
        }
    }

    
    private func scheduleRetryAfterDelay() {
        // Only retry if backend is still processing (cache: false)
        print("🔄 Backend still processing data, scheduling retry...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self,
                  let searchId = self.currentSearchId,
                  !self.isDataCached else {
                print("🛑 Retry cancelled - data cached or no search ID")
                return
            }
            
            print("🔄 Executing retry poll for more results")
            
            // 🚨 FIX: Use consistent retry parameters for all search types
            let retryLimit = self.multiCityTrips.count >= 2 ? 20 : 30  // Slightly smaller for multi-city
            
            self.service.pollFlightResultsPaginated(
                searchId: searchId,
                page: self.currentPage,
                limit: retryLimit,
                filterRequest: self._currentFilterRequest
            )
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] pollResponse in
                    guard let self = self else { return }
                    
                    // Always update cache status
                    self.isDataCached = pollResponse.cache
                    self.totalFlightCount = pollResponse.count
                    
                    // Add new results, avoiding duplicates
                    let existingIds = Set(self.detailedFlightResults.map { $0.id })
                    let newResults = pollResponse.results.filter { !existingIds.contains($0.id) }
                    if !newResults.isEmpty {
                        self.detailedFlightResults.append(contentsOf: newResults)
                        self.actualLoadedCount = self.detailedFlightResults.count
                    }
                    
                    print("✅ Retry fetched \(newResults.count) new results, total now: \(self.detailedFlightResults.count)")
                    print("📊 Cache status: \(pollResponse.cache)")
                    
                    // 🚨 FIX: Use EXACT same logic for all search types
                    if pollResponse.cache {
                        // Backend finished - check final state
                        if self.detailedFlightResults.isEmpty && pollResponse.count == 0 {
                            // Only show modal if this wasn't already handled as initial empty result
                            if !self.isInitialEmptyResult {
                                print("🚨 Empty result detected during retry (cache: true, count: 0)")
                                self.showNoResultsModal = true
                                self.detailedFlightError = nil
                            }
                            self.hasMoreFlights = false
                        } else {
                            self.hasMoreFlights = pollResponse.next != nil
                            self.detailedFlightError = nil
                        }
                        print("✅ Backend finished after retry - hasMoreFlights: \(self.hasMoreFlights)")
                    } else {
                        // Still processing - schedule another retry
                        self.hasMoreFlights = true
                        self.scheduleRetryAfterDelay()
                        print("🔄 Backend still processing - scheduling another retry")
                    }
                }
            )
            .store(in: &self.cancellables)
        }
    }

    // 2. Also update the applyFiltersWithPagination method in ExploreViewModel
    func applyFiltersWithPagination(filterRequest: FlightFilterRequest) {
        print("🔧 Applying user filters...")
        
        // Store the filter request
        self._currentFilterRequest = filterRequest
        
        // Reset pagination and reload from first page
        guard let searchId = currentSearchId else { return }
        
        isLoadingDetailedFlights = true
        detailedFlightResults = []
        currentPage = 1
        hasMoreFlights = true
        isLoadingMoreFlights = false
        isFirstLoad = true
        // Reset cache tracking for new filter
        isDataCached = false
        actualLoadedCount = 0
        
        service.pollFlightResultsPaginated(
            searchId: searchId,
            page: 1,
            limit: 30,
            filterRequest: filterRequest  // APPLY the user's filters
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    print("Filter application failed: \(error.localizedDescription)")
                    self?.isLoadingDetailedFlights = false
                    self?.detailedFlightError = error.localizedDescription
                }
            },
            receiveValue: { [weak self] pollResponse in
                guard let self = self else { return }
                
                self.handlePollResponse(pollResponse)
                
                // Continue polling if backend is still processing
                if !pollResponse.cache {
                    self.scheduleContinuousPolling()
                }
            }
        )
        .store(in: &cancellables)
    }


    func loadMoreFlights() {
        guard let searchId = currentSearchId,
              !isLoadingMoreFlights,
              !isLoadingDetailedFlights,
              shouldContinueLoadingMore() else {
            print("🚫 Cannot load more flights - conditions not met")
            print("   searchId: \(currentSearchId != nil)")
            print("   isLoadingMore: \(isLoadingMoreFlights)")
            print("   isLoadingDetailed: \(isLoadingDetailedFlights)")
            print("   shouldContinue: \(shouldContinueLoadingMore())")
            return
        }
        
        print("📥 Loading more flights: page \(currentPage + 1)")
        isLoadingMoreFlights = true
        let nextPage = currentPage + 1
        
        service.pollFlightResultsPaginated(
            searchId: searchId,
            page: nextPage,
            limit: 30,  // Consistent limit for pagination
            filterRequest: _currentFilterRequest
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                self.isLoadingMoreFlights = false
                
                if case .failure(let error) = completion {
                    print("❌ Load more flights failed: \(error.localizedDescription)")
                    
                    // Check for specific pagination errors
                    let errorDescription = error.localizedDescription.lowercased()
                    let isInvalidPageError = errorDescription.contains("invalid page") ||
                                           errorDescription.contains("404") ||
                                           (error as NSError).code == 404
                    
                    if isInvalidPageError {
                        print("🛑 Invalid page error - no more pages available")
                        self.hasMoreFlights = false
                    } else {
                        print("⚠️ Other pagination error - will retry later")
                    }
                }
            },
            receiveValue: { [weak self] pollResponse in
                guard let self = self else { return }
                
                // Update pagination tracking
                self.currentPage = nextPage
                self.totalFlightCount = pollResponse.count
                self.isDataCached = pollResponse.cache
                
                // Filter out duplicates before appending
                let existingIds = Set(self.detailedFlightResults.map { $0.id })
                let newResults = pollResponse.results.filter { !existingIds.contains($0.id) }
                
                print("📥 Page \(nextPage): received \(pollResponse.results.count) flights, \(newResults.count) are unique")
                
                // Append only unique results
                if !newResults.isEmpty {
                    self.detailedFlightResults.append(contentsOf: newResults)
                    self.actualLoadedCount = self.detailedFlightResults.count
                }
                
                // Update pagination state based on API response
                self.hasMoreFlights = pollResponse.next != nil
                
                print("✅ Pagination complete: total \(self.detailedFlightResults.count), hasMore: \(self.hasMoreFlights)")
                
                self.isLoadingMoreFlights = false
            }
        )
        .store(in: &cancellables)
    }
    
    private func shouldContinueLoadingMore() -> Bool {
        // CRITICAL: Only allow pagination when backend has finished processing (cache: true)
        guard isDataCached else {
            print("🔄 Backend still processing - no pagination until cache=true")
            return false
        }
        
        // Check if API indicates more pages available
        let hasMorePages = hasMoreFlights // This should be set based on next != null from API
        let notAtLimit = actualLoadedCount < totalFlightCount
        
        print("✅ Pagination check: hasMorePages=\(hasMorePages), loaded=\(actualLoadedCount)/\(totalFlightCount)")
        
        return hasMorePages && notAtLimit
    }

        

    // Modified method with special page 2 handling
    private func fetchPageWithRetry(searchId: String, page: Int, limit: Int, retryCount: Int, isPage2: Bool = false) {
        print("Fetching page \(page) (attempt \(retryCount + 1))")
        
        // Set a safety timeout to reset loading state if the request takes too long
        let safetyTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { [weak self] _ in
            guard let self = self, self.isLoadingMoreFlights else { return }
            print("⚠️ Safety timeout triggered for page \(page) - resetting loading state")
            self.isLoadingMoreFlights = false
        }
        
        service.pollFlightResultsPaginated(
            searchId: searchId,
            page: page,
            limit: limit,
            filterRequest: _currentFilterRequest
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                // Cancel the safety timer since we got a response
                safetyTimer.invalidate()
                
                if case .failure(let error) = completion {
                    print("Pagination error (attempt \(retryCount + 1)): \(error.localizedDescription)")
                    
                    // Check if it's a 404 error (common for pagination)
                    let is404Error = error.localizedDescription.contains("404")
                    
                    // Special handling for page 2 - always retry page 2 failures with a different approach
                    if isPage2 && retryCount == 0 {
                        // For first failure of page 2, try a different approach immediately
                        print("Page 2 first attempt failed - trying again immediately with different parameters")
                        
                        // Wait a short time (0.5 seconds) then retry with a smaller page size
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            // Try with a smaller page size for the retry
                            self.fetchPageWithRetry(
                                searchId: searchId,
                                page: page,
                                limit: 15, // Use smaller page size for retry
                                retryCount: retryCount + 1,
                                isPage2: true
                            )
                        }
                    }
                    // Standard retry logic for other errors and pages
                    else if is404Error && retryCount < 3 {
                        // Exponential backoff: wait longer between retries
                        let delay = Double(1 << retryCount) // 1, 2, 4 seconds
                        print("Retrying in \(delay) seconds...")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            self.fetchPageWithRetry(
                                searchId: searchId,
                                page: page,
                                limit: limit,
                                retryCount: retryCount + 1,
                                isPage2: isPage2
                            )
                        }
                    } else {
                        // Max retries reached or non-404 error
                        self.isLoadingMoreFlights = false
                        
                        // For 404 errors, just silently fail and update the UI
                        if is404Error {
                            print("Pagination failed after \(retryCount + 1) attempts - no more results available")
                            self.hasMoreFlights = false
                        } else {
                            // For other errors, show a message
                            print("Pagination failed: \(error.localizedDescription)")
                            
                            // IMPORTANT: Even on failure, we might still have more flights
                            // Only set hasMoreFlights to false if we're sure there are no more
                            if page > 1 && self.detailedFlightResults.count >= self.totalFlightCount {
                                self.hasMoreFlights = false
                            }
                        }
                    }
                }
            },
            receiveValue: { [weak self] pollResponse in
                guard let self = self else { return }
                
                // Cancel the safety timer since we got a response
                safetyTimer.invalidate()
                
                self.totalFlightCount = pollResponse.count
                
                // Only update current page on success
                self.currentPage = page
                
                // Append new results
                self.detailedFlightResults.append(contentsOf: pollResponse.results)
                
                // Update pagination state more reliably
                // Check both next flag and total count
                let loadedCount = self.detailedFlightResults.count
                let hasMoreBasedOnCount = loadedCount < pollResponse.count
                let hasMoreBasedOnNext = pollResponse.next != nil
                
                // Use both signals to determine if there are more flights
                self.hasMoreFlights = hasMoreBasedOnNext || hasMoreBasedOnCount
                
                // Always ensure we reset the loading flag
                self.isLoadingMoreFlights = false
                self.isFirstLoad = false
                
                print("Page \(page) loaded successfully: \(pollResponse.results.count) new flights, total loaded: \(self.detailedFlightResults.count), hasMore: \(self.hasMoreFlights)")
            }
        )
        .store(in: &cancellables)
    }
    
    func clearAllFilters() {
        print("🧹 Clearing all filters")
        
        // Reset filter state
        _currentFilterRequest = nil
        resetFilterSheetState()
        
        // Apply empty filter to get all results
        guard let searchId = currentSearchId else {
            print("⚠️ No search ID available for clearing filters")
            return
        }
        
        let emptyFilter = FlightFilterRequest()
        applyPollFilters(filterRequest: emptyFilter)
    }
    
    private func retrySearchWithBackoff(attempt: Int = 1) {
        guard attempt <= 3 else {
            print("❌ Max retry attempts reached")
            isLoadingDetailedFlights = false
            detailedFlightError = "Unable to load flights after multiple attempts"
            return
        }
        
        let delay = Double(attempt) * 2.0  // 2s, 4s, 6s delays
        print("🔄 Retrying search in \(delay)s (attempt \(attempt))")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self,
                  let searchId = self.currentSearchId else { return }
            
            self.service.pollFlightResultsPaginated(
                searchId: searchId,
                page: 1,
                limit: 30,
                filterRequest: self._currentFilterRequest
            )
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        self.retrySearchWithBackoff(attempt: attempt + 1)
                    }
                },
                receiveValue: { pollResponse in
                    self.handlePollResponse(pollResponse)
                    
                    // Continue polling if needed
                    if !pollResponse.cache {
                        self.scheduleContinuousPolling()
                    }
                }
            )
            .store(in: &self.cancellables)
        }
    }

   
    
    func resetToAnywhereDestination() {
            print("resetToAnywhereDestination called")
            
            // If we came from a direct search, clear everything
            if isDirectSearch {
                clearSearchFormAndReturnToExplore()
                return
            }
            
            // Otherwise use existing logic
            // Reset destination
            self.toLocation = "Anywhere"
            self.toIataCode = ""
            
            // Clear any search states
            self.hasSearchedFlights = false
            self.showingDetailedFlightList = false
            self.isDirectSearch = false
            self.isAnytimeMode = false
            
            // Clear results
            self.flightResults = []
            self.detailedFlightResults = []
            self.flightSearchResponse = nil
            
            // Clear selected city and return to countries
            self.selectedCity = nil
            self.selectedCountryName = nil
            self.showingCities = false
            
            // Clear error states
            self.errorMessage = nil
            self.detailedFlightError = nil
            
            // Clear dates to show "Anytime"
            self.dates = []
            self.selectedDepartureDatee = ""
            self.selectedReturnDatee = ""
            
            // Fetch countries to show the main explore screen
            self.fetchCountries()
        }
    
    func handleBackNavigationWithAnywhere() {
            if toLocation == "Anywhere" {
                // If destination is "Anywhere", check if we need to clear form
                if isDirectSearch {
                    clearSearchFormAndReturnToExplore()
                } else {
                    goBackToCountries()
                }
            } else {
                // Use existing back navigation logic
                if selectedFlightId != nil {
                    selectedFlightId = nil
                } else if showingDetailedFlightList {
                    goBackToFlightResults()
                } else if hasSearchedFlights {
                    goBackToCities()
                } else if showingCities {
                    goBackToCountries()
                }
            }
        }
    
    func handleDetailedFlightBackNavigation() {
            print("handleDetailedFlightBackNavigation called")
            print("Current selectedFlightId: \(selectedFlightId ?? "nil")")
            print("Current showingDetailedFlightList: \(showingDetailedFlightList)")
            
            if selectedFlightId != nil {
                // If a flight is selected, deselect it first
                print("Deselecting flight, going back to flight list")
                selectedFlightId = nil
            } else {
                // Otherwise go back to flight results or previous level
                print("Going back to previous level")
                goBackToFlightResults()
            }
        }
    
    func handleAnytimeResults(_ results: [FlightResult]) {
            // Filter valid results
            let validResults = results.filter { result in
                !result.outbound.origin.iata.isEmpty &&
                !result.outbound.destination.iata.isEmpty &&
                result.price > 0 &&
                result.outbound.departure != nil
            }
            
            // Set anytime mode flag
            self.isAnytimeMode = true
            
            // Reset all detailed view flags to ensure they don't activate
            self.detailedFlightResults = []
            self.showingDetailedFlightList = false
            self.isLoadingDetailedFlights = false
            self.detailedFlightError = nil
            self.isDirectSearch = false
            
            // Set up the flight results display
            self.flightResults = validResults
            self.hasSearchedFlights = true
            self.isLoadingFlights = false
            
            // If we got results, update the to/from location display
            if let firstResult = validResults.first {
                self.fromLocation = firstResult.outbound.origin.name
                self.toLocation = firstResult.outbound.destination.name
                
                self.fromIataCode = firstResult.outbound.origin.iata
                self.toIataCode = firstResult.outbound.destination.iata
                
                // Save search details for later use
                self.selectedOriginCode = firstResult.outbound.origin.iata
                self.selectedDestinationCode = firstResult.outbound.destination.iata
                
                if let outboundDeparture = firstResult.outbound.departure {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    let departureDate = Date(timeIntervalSince1970: TimeInterval(outboundDeparture))
                    self.selectedDepartureDatee = formatter.string(from: departureDate)
                    
                    if let inboundDeparture = firstResult.inbound?.departure {
                        let returnDate = Date(timeIntervalSince1970: TimeInterval(inboundDeparture))
                        self.selectedReturnDatee = formatter.string(from: returnDate)
                    }
                }
            }
            
            // Clear these to ensure we're in the right state
            self.selectedCity = nil
            self.showingCities = false
            
            // Set dates array to empty to show "Anytime" in the date field
            self.dates = []
            
            // Update error message based on results
            if validResults.isEmpty {
                self.errorMessage = "No flights found for this route"
            } else {
                self.errorMessage = nil
            }
            
            // Force an update to ensure changes are processed
            self.objectWillChange.send()
        }
    
    
    struct FilterSheetState {
        var sortOption: FlightFilterTabView.FilterOption = .best
        var directFlightsSelected: Bool = true      // ✅ Keep as true
        var oneStopSelected: Bool = true            // ✅ CHANGE: Set to true by default
        var multiStopSelected: Bool = true          // ✅ CHANGE: Set to true by default
        var priceRange: [Double] = [0.0, 2000.0]
        var departureTimes: [Double] = [0.0, 24.0]
        var arrivalTimes: [Double] = [0.0, 24.0]
        var durationRange: [Double] = [1.75, 8.5]
        var selectedAirlines: Set<String> = []
        
        // Add flag to track if this is first time opening filter sheet
        var isFirstTimeOpening: Bool = true         // ✅ ADD: Track first time opening
    }
    
    
    @Published var filterSheetState = FilterSheetState()
    
    @Published var isDirectSearch: Bool = false
    
    func goBackToMainFromDirectSearch() {
            print("goBackToMainFromDirectSearch called")
            clearSearchFormAndReturnToExplore()
        }
    
    // For storing filter state
    private var _currentFilterRequest: FlightFilterRequest?
    private var _lastPollResponse: FlightPollResponse?

    // Public accessors
    var currentFilterRequest: FlightFilterRequest? {
        get {
            return _currentFilterRequest
        }
        set {
            _currentFilterRequest = newValue
        }
    }

    var lastPollResponse: FlightPollResponse? {
        get {
            return _lastPollResponse
        }
        set {
            _lastPollResponse = newValue
        }
    }
    
    func applyQuickFilter(_ filter: FlightFilterTabView.FilterOption) {
        print("🔧 Applying quick filter: \(filter.rawValue)")
        
        var filterRequest: FlightFilterRequest?
        
        switch filter {
        case .best:
            // CRITICAL: For "Best", check if user has applied any filter sheet filters
            if let existingFilter = createCompleteFilterRequest() {
                // User has filter sheet changes, keep them but no additional sorting
                filterRequest = existingFilter
                print("   - Using existing filter sheet settings")
            } else {
                // No filter sheet changes, use completely empty filter for all results
                filterRequest = nil
                print("   - Using empty filter for all results")
            }
            
        case .cheapest:
            // Start with any existing filter sheet settings
            filterRequest = createCompleteFilterRequest() ?? FlightFilterRequest()
            filterRequest!.sortBy = "price"
            filterRequest!.sortOrder = "asc"
            print("   - Sort by price (cheapest)")
            
        case .fastest:
            // Start with any existing filter sheet settings
            filterRequest = createCompleteFilterRequest() ?? FlightFilterRequest()
            filterRequest!.sortBy = "duration"
            filterRequest!.sortOrder = "asc"
            print("   - Sort by duration (fastest)")
            
        case .direct:
            // Start with any existing filter sheet settings
            filterRequest = createCompleteFilterRequest() ?? FlightFilterRequest()
            filterRequest!.stopCountMax = 0
            print("   - Direct flights only")
        }
        
        // Store current filter request
        currentFilterRequest = filterRequest
        
        // Apply the filter if we have search context
        if !self.selectedOriginCode.isEmpty && !self.selectedDestinationCode.isEmpty {
            if let request = filterRequest {
                applyPollFilters(filterRequest: request)
            } else {
                // Apply empty filter for "Best" when no filter sheet changes
                let emptyFilter = FlightFilterRequest()
                applyPollFilters(filterRequest: emptyFilter)
            }
        }
    }
    
    func applyPollFilters(filterRequest: FlightFilterRequest) {
        guard let searchId = currentSearchId else {
            print("⚠️ No search ID available for filter application")
            return
        }
        
        print("🔍 Applying filters via API - searchId: \(searchId)")
        
        // Store the filter request for future use
        self._currentFilterRequest = filterRequest
        
        // Reset pagination and cache tracking for filtered results
        isLoadingDetailedFlights = true
        detailedFlightError = nil
        currentPage = 1
        actualLoadedCount = 0
        isDataCached = false
        hasMoreFlights = true
        isLoadingMoreFlights = false
        isFirstLoad = true
        
        // Clear existing results immediately to show loading state
        detailedFlightResults = []
        
        service.pollFlightResultsPaginated(
            searchId: searchId,
            page: 1,
            limit: 30,
            filterRequest: filterRequest
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                if case .failure(let error) = completion {
                    print("❌ Filter application failed: \(error.localizedDescription)")
                    self.isLoadingDetailedFlights = false
                    self.detailedFlightError = error.localizedDescription
                    self.detailedFlightResults = []
                    self.totalFlightCount = 0
                    self.actualLoadedCount = 0
                }
            },
            receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                print("✅ Filters applied successfully:")
                print("   - Results count: \(response.results.count)")
                print("   - Total available: \(response.count)")
                print("   - Cached: \(response.cache)")
                
                self.handlePollResponse(response)
                
                // Continue polling if backend is still processing
                if !response.cache {
                    self.scheduleContinuousPolling()
                }
            }
        )
        .store(in: &cancellables)
    }
    
    private func applyClientSideStopFiltering(
        results: [FlightDetailResult],
        filterRequest: FlightFilterRequest
    ) -> [FlightDetailResult] {
        
        // Get the current stop filter selections from the filter sheet state
        let directSelected = filterSheetState.directFlightsSelected
        let oneStopSelected = filterSheetState.oneStopSelected
        let multiStopSelected = filterSheetState.multiStopSelected
        
        let selectedOptions = [
            (directSelected, "direct"),
            (oneStopSelected, "oneStop"),
            (multiStopSelected, "multiStop")
        ].filter { $0.0 }.map { $0.1 }
        
        print("🛑 Client-side filtering for stops: \(selectedOptions)")
        
        // If all options are selected or no options are selected, return all results
        if selectedOptions.count == 0 || selectedOptions.count == 3 {
            print("🛑 No stop filtering needed (all or none selected)")
            return results
        }
        
        let filteredResults = results.filter { flight in
            // Get the maximum stop count for this flight across all legs
            let maxStops = flight.legs.map { $0.stopCount }.max() ?? 0
            
            let isDirect = maxStops == 0
            let isOneStop = maxStops == 1
            let isMultiStop = maxStops >= 2
            
            // Check if this flight matches the selected criteria
            if selectedOptions.count == 1 {
                // Only one option selected - be exclusive
                if directSelected && !oneStopSelected && !multiStopSelected {
                    return isDirect
                } else if !directSelected && oneStopSelected && !multiStopSelected {
                    return isOneStop // Only 1-stop flights, exclude direct
                } else if !directSelected && !oneStopSelected && multiStopSelected {
                    return isMultiStop // Only 2+ stop flights, exclude direct and 1-stop
                }
            } else if selectedOptions.count == 2 {
                // Two options selected
                if directSelected && oneStopSelected && !multiStopSelected {
                    return isDirect || isOneStop
                } else if directSelected && !oneStopSelected && multiStopSelected {
                    return isDirect || isMultiStop
                } else if !directSelected && oneStopSelected && multiStopSelected {
                    return isOneStop || isMultiStop // Exclude direct flights
                }
            }
            
            // Default: include the flight
            return true
        }
        
        print("🛑 Client-side filtering result: \(results.count) → \(filteredResults.count) flights")
        
        return filteredResults
    }
    
    func createCompleteFilterRequest() -> FlightFilterRequest? {
        // CRITICAL: Only return a filter if user has actually made changes in filter sheet
        let state = filterSheetState
        
        // Check if user has made any meaningful changes from defaults
        let hasStopChanges = !(state.directFlightsSelected && state.oneStopSelected && state.multiStopSelected)
        let hasPriceChanges = state.priceRange[0] > getApiMinPrice() + 50 || state.priceRange[1] < getApiMaxPrice() - 50
        let hasTimeChanges = abs(state.departureTimes[0] - 0.0) > 0.1 || abs(state.departureTimes[1] - 24.0) > 0.1 ||
                            abs(state.arrivalTimes[0] - 0.0) > 0.1 || abs(state.arrivalTimes[1] - 24.0) > 0.1
        let hasDurationChanges = abs(state.durationRange[0] - 1.75) > 0.1 || abs(state.durationRange[1] - 8.5) > 0.1
        let hasSortChanges = state.sortOption != .best
        
        // Check airline changes
        let hasAirlineChanges: Bool
        if let pollResponse = lastPollResponse, !pollResponse.airlines.isEmpty {
            let allAirlines = Set(pollResponse.airlines.map { $0.airlineIata })
            hasAirlineChanges = !state.selectedAirlines.isEmpty &&
                               state.selectedAirlines.count < allAirlines.count &&
                               state.selectedAirlines != allAirlines
        } else {
            hasAirlineChanges = false
        }
        
        // If no meaningful changes, return nil (will use empty filter)
        guard hasStopChanges || hasPriceChanges || hasTimeChanges || hasDurationChanges || hasSortChanges || hasAirlineChanges else {
            print("   - No filter sheet changes detected")
            return nil
        }
        
        print("   - Building filter from sheet changes")
        var filterRequest = FlightFilterRequest()
        
        // Apply stop filters if changed
        if hasStopChanges {
            let selectedOptions = [
                (state.directFlightsSelected, "direct"),
                (state.oneStopSelected, "oneStop"),
                (state.multiStopSelected, "multiStop")
            ].filter { $0.0 }.map { $0.1 }
            
            if selectedOptions.count == 1 {
                if state.directFlightsSelected {
                    filterRequest.stopCountMax = 0
                } else if state.oneStopSelected {
                    filterRequest.stopCountMax = 1
                }
            } else if selectedOptions.count == 2 {
                if state.directFlightsSelected && state.oneStopSelected {
                    filterRequest.stopCountMax = 1
                }
            }
        }
        
        // Apply price filters if changed
        if hasPriceChanges {
            filterRequest.priceMin = Int(state.priceRange[0])
            filterRequest.priceMax = Int(state.priceRange[1])
        }
        
        // Apply time filters if changed
        if hasTimeChanges {
            let departureMin = Int(state.departureTimes[0] * 3600)
            let departureMax = Int(state.departureTimes[1] * 3600)
            let arrivalMin = Int(state.arrivalTimes[0] * 3600)
            let arrivalMax = Int(state.arrivalTimes[1] * 3600)
            
            let timeRange = ArrivalDepartureRange(
                arrival: TimeRange(min: arrivalMin, max: arrivalMax),
                departure: TimeRange(min: departureMin, max: departureMax)
            )
            filterRequest.arrivalDepartureRanges = [timeRange]
        }
        
        // Apply duration filters if changed
        if hasDurationChanges {
            filterRequest.durationMax = Int(state.durationRange[1] * 60)
        }
        
        // Apply airline filters if changed
        if hasAirlineChanges {
            filterRequest.iataCodesInclude = Array(state.selectedAirlines)
        }
        
        // Apply sort filters if changed
        if hasSortChanges {
            switch state.sortOption {
            case .cheapest:
                filterRequest.sortBy = "price"
                filterRequest.sortOrder = "asc"
            case .fastest:
                filterRequest.sortBy = "duration"
                filterRequest.sortOrder = "asc"
            case .direct:
                filterRequest.stopCountMax = 0
            default:
                break
            }
        }
        
        return filterRequest
    }
    
    
    func updateChildrenAgesArray(for newCount: Int) {
        if newCount > childrenAges.count {
            // Add nil ages for new children
            childrenAges.append(contentsOf: Array(repeating: nil, count: newCount - childrenAges.count))
        } else if newCount < childrenAges.count {
            // Remove excess ages
            childrenAges = Array(childrenAges.prefix(newCount))
        }
    }

    // Initialize with default trips in viewModel's init() method
    func initializeMultiCityTrips() {
        // Default to 2 trips as you mentioned
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        
        multiCityTrips = [
            MultiCityTrip(fromLocation: fromLocation, fromIataCode: fromIataCode,
                         toLocation: toLocation, toIataCode: toIataCode, date: tomorrow),
            MultiCityTrip(fromLocation: toLocation, fromIataCode: toIataCode,
                         toLocation: "", toIataCode: "", date: dayAfterTomorrow)
        ]
    }
    
     var cancellables = Set<AnyCancellable>()
    private let service = ExploreAPIService.shared
    
    // In ExploreViewModel init() method, make sure these defaults are set
    init() {
        // Set default location values
        fromLocation = "Kochi"
        fromIataCode = "COK"
        toLocation = "Anywhere"
        toIataCode = ""
        
        setupAvailableMonths()
        
        // Initialize passenger data
        adultsCount = 1
        childrenCount = 0
        childrenAges = [0]
        selectedCabinClass = "Economy"
        
        // Rest of your existing init code...
        if destinations.isEmpty {
            isLoading = true
            print("🔄 ExploreViewModel: Setting initial loading state to true")
        }
        
        // Add observer for dates changes
        $dates
            .sink { [weak self] selectedDates in
                guard let self = self else { return }
                if !selectedDates.isEmpty {
                    self.updateSelectedDates()
                }
            }
            .store(in: &cancellables)
        
        ExploreAPIService.shared.viewModelReference = self
    }
    
    // MARK: - Fixed handleTripTypeChange Method in ExploreViewModel.swift

    func handleTripTypeChange() {
        print("🔄 Trip type changed to: \(isRoundTrip ? "Round Trip" : "One Way")")
        
        // Handle date changes when switching trip types
        if isRoundTrip { // Switching TO round trip
            // Make sure we have both departure and return dates for round trip
            if dates.count == 1 {
                // We only have a departure date, add a return date (departure + 7 days)
                if let returnDate = Calendar.current.date(byAdding: .day, value: 7, to: dates[0]) {
                    dates.append(returnDate)
                    
                    // Update the formatted date strings
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    selectedReturnDatee = formatter.string(from: returnDate)
                    
                    print("Added return date for round trip: \(selectedReturnDatee)")
                }
            } else if dates.isEmpty && !selectedDepartureDatee.isEmpty {
                // We have a string date but no Date objects - reconstruct from strings
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                
                if let departureDate = formatter.date(from: selectedDepartureDatee) {
                    dates = [departureDate]
                    
                    // Add a return date (departure + 7 days)
                    if let returnDate = Calendar.current.date(byAdding: .day, value: 7, to: departureDate) {
                        dates.append(returnDate)
                        selectedReturnDatee = formatter.string(from: returnDate)
                        print("Created return date for round trip: \(selectedReturnDatee)")
                    }
                }
            }
        } else { // Switching TO one-way
            // Keep only the first date for one-way if we have multiple dates
            if dates.count > 1 {
                dates = Array(dates.prefix(1))
            }
            // Clear the return date string
            selectedReturnDatee = ""
            print("Cleared return date for one-way trip")
        }
        
        // FIXED: Enhanced logic to handle all search scenarios
        if !fromIataCode.isEmpty && !toIataCode.isEmpty {
            // Clear current results first
            detailedFlightResults = []
            flightResults = []
            
            // Scenario 1: We're on the detailed flight list (most common case)
            if showingDetailedFlightList && !selectedOriginCode.isEmpty && !selectedDestinationCode.isEmpty && !selectedDepartureDatee.isEmpty {
                print("🔄 Re-searching detailed flights with new trip type")
                
                // For round trip, ensure we have a return date
                let returnDate = isRoundTrip ? selectedReturnDatee : ""
                
                // Re-search with new trip type
                searchFlightsForDatesWithPagination(
                    origin: selectedOriginCode,
                    destination: selectedDestinationCode,
                    returnDate: returnDate,
                    departureDate: selectedDepartureDatee,
                    isDirectSearch: isDirectSearch
                )
            }
            // Scenario 2: We're in flight results view with monthly data (THIS IS THE KEY FIX)
            else if hasSearchedFlights && !showingDetailedFlightList {
                print("🔄 Re-searching flight results with new trip type for current month")
                
                // FIXED: Auto-search with current month when trip type changes
                if let city = selectedCity {
                    // If we have a selected city, fetch flight details for current month
                    fetchFlightDetails(destination: city.location.iata)
                } else if !toIataCode.isEmpty {
                    // If we have destination code but no city, still fetch flight details
                    fetchFlightDetails(destination: toIataCode)
                } else {
                    // Fallback: trigger month selection to reload data
                    print("🔄 Triggering month selection to reload data")
                    selectMonth(at: selectedMonthIndex)
                }
            }
            // Scenario 3: We have search context with specific dates
            else if !dates.isEmpty {
                print("🔄 Re-searching with existing dates and new trip type")
                updateDatesAndRunSearch()
            }
            // Scenario 4: We have at least origin/destination but no specific dates - use defaults
            else {
                print("🔄 Re-searching with default dates and new trip type")
                
                // Create default dates (7 days from now for departure, 14 days for return)
                let calendar = Calendar.current
                let defaultDeparture = calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date()
                let defaultReturn = calendar.date(byAdding: .day, value: 14, to: Date()) ?? Date()
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                
                selectedDepartureDatee = formatter.string(from: defaultDeparture)
                selectedReturnDatee = isRoundTrip ? formatter.string(from: defaultReturn) : ""
                
                // Update dates array
                dates = isRoundTrip ? [defaultDeparture, defaultReturn] : [defaultDeparture]
                
                // Trigger search
                if showingDetailedFlightList {
                    searchFlightsForDatesWithPagination(
                        origin: fromIataCode,
                        destination: toIataCode,
                        returnDate: selectedReturnDatee,
                        departureDate: selectedDepartureDatee,
                        isDirectSearch: isDirectSearch
                    )
                } else {
                    updateDatesAndRunSearch()
                }
            }
        } else {
            print("⚠️ Missing origin/destination codes for trip type change")
        }
    }

    
    // Method to format selected dates for display in UI
    func formatDateForDisplay(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
    
    func updateSelectedDates() {
        if dates.count >= 2 {
            let sortedDates = dates.sorted()
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            selectedDepartureDatee = formatter.string(from: sortedDates[0])
            selectedReturnDatee = formatter.string(from: sortedDates[1])
        } else if dates.count == 1 {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            selectedDepartureDatee = formatter.string(from: dates[0])
            
            // For one-way trip - set same date or next day depending on your requirements
            if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: dates[0]) {
                selectedReturnDatee = formatter.string(from: nextDay)
            } else {
                selectedReturnDatee = selectedDepartureDatee
            }
        }
    }
    
    func updateDatesAndRunSearch() {
        // Only proceed if we have both origin and destination selected
        if !fromIataCode.isEmpty && !toIataCode.isEmpty && !dates.isEmpty {
            // Format dates properly for the API
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            let departureDate: String
            let returnDate: String
            
            if dates.count >= 2 && isRoundTrip {
                let sortedDates = dates.sorted()
                departureDate = formatter.string(from: sortedDates[0])
                returnDate = formatter.string(from: sortedDates[1])
            } else if dates.count == 1 {
                departureDate = formatter.string(from: dates[0])
                
                // For round trip with only one date, create a return date
                if isRoundTrip {
                    if let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: dates[0]) {
                        returnDate = formatter.string(from: nextWeek)
                        // Also add the return date to the dates array
                        if !dates.contains(nextWeek) {
                            dates.append(nextWeek)
                        }
                    } else {
                        returnDate = ""
                    }
                } else {
                    returnDate = ""
                }
            } else {
                // Default fallback dates if somehow we have no dates
                let today = Date()
                if let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: today) {
                    departureDate = formatter.string(from: today)
                    returnDate = isRoundTrip ? formatter.string(from: nextWeek) : ""
                    
                    // Also update the dates array
                    dates = isRoundTrip ? [today, nextWeek] : [today]
                } else {
                    departureDate = "2025-12-29"
                    returnDate = isRoundTrip ? "2025-12-30" : ""
                }
            }
            
            // Update the stored dates
            selectedDepartureDatee = departureDate
            selectedReturnDatee = returnDate
            
            // Initiate search with these dates - mark as direct search
            searchFlightsForDates(
                origin: fromIataCode,
                destination: toIataCode,
                returnDate: returnDate,
                departureDate: departureDate,
                isDirectSearch: true
            )
        }
    }
    
    // Add a method to initialize dates from API date strings
    func initializeDatesFromStrings() {
        if !selectedDepartureDatee.isEmpty && dates.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            if let departureDate = formatter.date(from: selectedDepartureDatee) {
                var newDates = [departureDate]
                
                if !selectedReturnDatee.isEmpty, let returnDate = formatter.date(from: selectedReturnDatee) {
                    newDates.append(returnDate)
                }
                
                // Update dates array to keep calendar in sync
                dates = newDates
            }
        }
    }
    
    func searchMultiCityFlights() {
        searchMultiCityFlightsWithPagination()
    }
    
    // Add this function to handle search and poll
    func searchFlightsForDates(origin: String, destination: String, returnDate: String, departureDate: String, isDirectSearch: Bool = false) {
        searchFlightsForDatesWithPagination(
            origin: origin,
            destination: destination,
            returnDate: returnDate,
            departureDate: departureDate,
            isDirectSearch: isDirectSearch
        )
    }

    // Add helper function to format date for API
    func formatDateForAPI(from date: String) -> String? {
           let inputFormatter = DateFormatter()
           inputFormatter.dateFormat = "EEE, d MMM yyyy"
           
           if let parsedDate = inputFormatter.date(from: date) {
               let outputFormatter = DateFormatter()
               outputFormatter.dateFormat = "yyyy-MM-dd"
               return outputFormatter.string(from: parsedDate)
           }
           
           // If we can't parse the date, return nil
           // The caller will use a default value
           return nil
       }
    
    // MARK: - Enhanced fetchCountries method (replace the existing fetchCountries)
    func fetchCountries() {
        // UPDATED: Check if currency has changed since last cache
        let currentCurrency = CurrencyManager.shared.currencyCode
        let currentCountry = CurrencyManager.shared.countryCode
        
        // First check if we already have cached data AND currency hasn't changed
        if let cachedData = ExploreViewModel.cachedDestinations,
           !cachedData.isEmpty,
           ExploreViewModel.lastCachedCurrency == currentCurrency,
           ExploreViewModel.lastCachedCountry == currentCountry {
            print("✅ Using cached country list data (currency: \(currentCurrency), country: \(currentCountry))")
            self.destinations = cachedData
            self.isLoading = false
            return
        }
        
        // Cache is invalid or currency/country changed, fetch fresh data
        print("🔄 Fetching fresh country data (currency: \(currentCurrency), country: \(currentCountry))")
        
        isLoading = true
        errorMessage = nil
        
        print("🔄 fetchCountries: Loading state set to true immediately")
        
        service.fetchDestinations()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                    print("❌ fetchCountries failed: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] destinations in
                self?.destinations = destinations
                
                // Cache the data with current currency/country info
                ExploreViewModel.cachedDestinations = destinations
                ExploreViewModel.lastCachedCurrency = currentCurrency
                ExploreViewModel.lastCachedCountry = currentCountry
                
                print("✅ fetchCountries completed: \(destinations.count) destinations loaded with currency \(currentCurrency)")
            })
            .store(in: &cancellables)
    }
        
        
    // Update this method to also clear currency tracking
    func clearCountriesCache() {
        ExploreViewModel.cachedDestinations = nil
        ExploreViewModel.lastCachedCurrency = nil
        ExploreViewModel.lastCachedCountry = nil
        print("💱 Cleared countries cache and currency tracking")
    }
    
    
    func fetchCitiesFor(countryId: String, countryName: String) {
        isLoading = true
        errorMessage = nil
        selectedCountryName = countryName
        
        // ADDED: Update toLocation to country name when country is selected
        toLocation = countryName
        
        // FIXED: Set showingCities immediately, not in completion handler
        showingCities = true
        
        service.fetchDestinations(arrivalType: "city", arrivalId: countryId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] destinations in
                self?.destinations = destinations
            })
            .store(in: &cancellables)
    }
    
    func selectCity(city: ExploreDestination) {
        selectedCity = city
        toLocation = city.location.name
        toIataCode = city.location.iata  // ADDED: Set the IATA code when city is selected
        
        // Fetch flight details when a city is selected - use fromIataCode as departure
        fetchFlightDetails(departure: fromIataCode, destination: city.location.iata)
    }
    
    func setupAvailableMonths() {
        // Generate next 6 months starting from current month
        let calendar = Calendar.current
        let currentDate = Date()
        
        var months: [Date] = []
        for i in 0..<12 {
            if let date = calendar.date(byAdding: .month, value: i, to: currentDate) {
                // Get the first day of each month
                let components = calendar.dateComponents([.year, .month], from: date)
                if let firstDayOfMonth = calendar.date(from: components) {
                    months.append(firstDayOfMonth)
                }
            }
        }
        
        availableMonths = months
        selectedMonthIndex = 0 // Default to current month
    }
    
    func fetchFlightDetails(departure: String? = nil, destination: String) {
        isLoadingFlights = true
        errorMessage = nil
        hasSearchedFlights = true
        // DON'T clear previous results immediately - let them stay visible
        // flightResults = [] // <- REMOVE THIS LINE
        
        // Use fromIataCode as default departure if not provided
        let finalDeparture = departure ?? fromIataCode
        
        // Format date based on selected month
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        
        let dateToUse: Date
        
        if selectedMonthIndex == 0 {
            // If current month, use current date
            dateToUse = Date()
        } else {
            // Otherwise use the first day of the selected month
            dateToUse = availableMonths[selectedMonthIndex]
        }
        
        let departureDate = dateFormatter.string(from: dateToUse)
        
        print("Fetching flight details for trip type: \(isRoundTrip ? "Round Trip" : "One Way")")
        print("Rountrip1111: \(isRoundTrip)")
        print("depdate1111: \(departureDate)")
        print("dest1111: \(destination)")
        print("departure1111: \(finalDeparture)")
        
        service.fetchFlightDetails(
            origin: finalDeparture,
            destination: destination,
            departure: departureDate,
            roundTrip: isRoundTrip
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { [weak self] completion in
            self?.isLoadingFlights = false
            if case .failure(let error) = completion {
                self?.errorMessage = error.localizedDescription
                // Only clear results on error, not on loading
                self?.flightResults = []
                print("Flight details fetch failed: \(error.localizedDescription)")
            }
        }, receiveValue: { [weak self] response in
            // Only update results when new data arrives
            self?.flightSearchResponse = response
            self?.flightResults = response.results
            print("Fetched \(response.results.count) flight results")
            
            // If we got an empty array but no error, set a custom error message
            if response.results.isEmpty {
                self?.errorMessage = "No flights available"
            } else {
                self?.errorMessage = nil
            }
        })
        .store(in: &cancellables)
    }
    
    // Update the month selector method to preserve dates
    func selectMonth(at index: Int) {
        if index >= 0 && index < availableMonths.count {
            // Exit anytime mode when selecting a specific month
            isAnytimeMode = false
            selectedMonthIndex = index
            
            // If we have origin, destination and dates set, perform a search with the new month
            if !fromIataCode.isEmpty && !toIataCode.isEmpty {
                // Get the first day of the selected month
                let selectedMonth = availableMonths[index]
                
                // Create a new date for the same day in the new month
                let calendar = Calendar.current
                
                // If we have existing dates, try to preserve the day value in the new month
                if !dates.isEmpty {
                    var newDates: [Date] = []
                    
                    for date in dates {
                        let components = calendar.dateComponents([.day], from: date)
                        let day = components.day ?? 1
                        
                        // Create a date with same day but in new month
                        var newDateComponents = calendar.dateComponents([.year, .month], from: selectedMonth)
                        newDateComponents.day = min(day, 28) // Ensure valid day even in February
                        
                        if let newDate = calendar.date(from: newDateComponents) {
                            newDates.append(newDate)
                        }
                    }
                    
                    // Update dates array
                    if !newDates.isEmpty {
                        dates = newDates
                        
                        // CHANGED: Check if we're already in flight results view
                        if hasSearchedFlights && !showingDetailedFlightList {
                            // If we're already in flight results view, use fetchFlightDetails instead of full search
                            if let city = selectedCity {
                                fetchFlightDetails(departure: fromIataCode, destination: city.location.iata)
                            } else if !selectedDestinationCode.isEmpty {
                                fetchFlightDetails(departure: fromIataCode, destination: selectedDestinationCode)
                            }
                            return
                        } else {
                            // Otherwise proceed with full search
                            updateDatesAndRunSearch()
                            return
                        }
                    }
                }
                
                // Fallback - use the selected month with default day values
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                
                // Get first and last days of month for search
                let firstDay = selectedMonth
                let lastDay = calendar.date(byAdding: .day, value: 6, to: firstDay) ?? firstDay // Default to 1 week trip
                
                // Update the search dates based on the new month selection
                selectedDepartureDatee = formatter.string(from: firstDay)
                selectedReturnDatee = formatter.string(from: lastDay)
                
                // CHANGED: Check if we're already in flight results view
                if hasSearchedFlights && !showingDetailedFlightList {
                    // If we're already in flight results view, use fetchFlightDetails
                    if let city = selectedCity {
                        fetchFlightDetails(departure: fromIataCode, destination: city.location.iata)
                    } else if !selectedDestinationCode.isEmpty {
                        fetchFlightDetails(departure: fromIataCode, destination: selectedDestinationCode)
                    }
                } else {
                    // Otherwise trigger search with the new month dates
                    searchFlightsForDates(
                        origin: fromIataCode,
                        destination: toIataCode,
                        returnDate: selectedReturnDatee,
                        departureDate: selectedDepartureDatee
                    )
                }
                
                // Also update the dates array to keep UI in sync
                dates = [firstDay, lastDay]
            }
            
            // If a city was selected but we don't have both origin/destination codes yet,
            // still fetch flight details to show available flights in this month
            else if let city = selectedCity {
                fetchFlightDetails(departure: fromIataCode, destination: city.location.iata)
            }
        }
    }
    
    func goBackToFlightResults() {
        print("goBackToFlightResults called")
        
        showNoResultsModal = false
        isInitialEmptyResult = false
        
        // Clear selected flight first
        selectedFlightId = nil
        
        // IMPORTANT: Reset filters when going back
        _currentFilterRequest = nil
        resetFilterSheetState()
        
        // Reset all search-related states
        if isDirectSearch {
            print("Handling direct search back navigation - clearing form")
            // Clear the search form completely for direct searches from HomeView
            clearSearchFormAndReturnToExplore()
        } else {
            print("Handling explore flow back navigation")
            // If this came from exploration, go back to flight results
            showingDetailedFlightList = false
            detailedFlightResults = []
            detailedFlightError = nil
            isLoadingDetailedFlights = false
            
            // CRITICAL: Don't clear any flight results or trigger any loading
            // Just reset loading states to false
            isLoadingFlights = false
            errorMessage = nil
            
            // Keep hasSearchedFlights = true to stay on flight results page
            // Keep flightResults intact - DON'T modify it
            
            print("✅ Returned to flight results screen")
            print("📊 Flight results preserved: \(flightResults.count) flights")
            print("📝 User can click month tab to refresh data if needed")
        }
    }
    
    func clearSearchFormAndReturnToExplore() {
        showNoResultsModal = false
            isInitialEmptyResult = false
            // Clear all search-related flags
            isDirectSearch = false
            showingDetailedFlightList = false
            detailedFlightResults = []
            detailedFlightError = nil
            isLoadingDetailedFlights = false
            hasSearchedFlights = false
            flightResults = []
            flightSearchResponse = nil
            isAnytimeMode = false
            directFlightsOnlyFromHome = false // ADD: Clear direct flights preference
        
        // IMPORTANT: Reset filters completely
           _currentFilterRequest = nil
           resetFilterSheetState()
            
            // Clear search form data
            fromLocation = "Kochi" // Reset to default
            toLocation = "Anywhere" // Reset to anywhere
            fromIataCode = "COK" // Reset to default origin
            toIataCode = "" // Clear destination
            dates = [] // Clear selected dates
            selectedDepartureDatee = ""
            selectedReturnDatee = ""
            selectedOriginCode = ""
            selectedDestinationCode = ""
            
            // Clear selected states
            selectedCountryName = nil
            selectedCity = nil
            showingCities = false
            selectedFlightId = nil
            
            // Clear error states
            errorMessage = nil
            
            // Return to countries view
            fetchCountries()
        DispatchQueue.main.async {
               SharedSearchDataStore.shared.isInSearchMode = false
           }
            
            print("✅ Search form cleared and returned to explore countries")
        }

    func goBackToCities() {
        print("goBackToCities called")
        
        // If this was a direct search, clear the form completely
        if isDirectSearch {
            clearSearchFormAndReturnToExplore()
            return
        }
        
        // Otherwise use existing logic
        isAnytimeMode = false
        hasSearchedFlights = false
        flightResults = []
        flightSearchResponse = nil
        selectedCity = nil
        toIataCode = ""  // ADDED: Clear IATA code when going back to cities
        // Keep toLocation as country name - don't reset it here
        
        // Fetch cities again for the selected country
        if let countryName = selectedCountryName,
           let country = destinations.first(where: { $0.location.name == countryName }) {
            fetchCitiesFor(countryId: country.location.entityId, countryName: countryName)
        }
    }
    
    func goBackToCountries() {
        print("goBackToCountries called")
        
        // If this was a direct search, clear the form completely
        if isDirectSearch {
            clearSearchFormAndReturnToExplore()
            return
        }
        
        // Otherwise use existing logic
        isAnytimeMode = false
        selectedCountryName = nil
        selectedCity = nil
        toLocation = "Anywhere"
        toIataCode = ""  // ADDED: Clear IATA code when going back to countries
        showingCities = false
        hasSearchedFlights = false
        showingDetailedFlightList = false
        flightResults = []
        flightSearchResponse = nil
        detailedFlightResults = []
        detailedFlightError = nil
        fetchCountries()
        
        // Reset tab visibility when returning to countries
        DispatchQueue.main.async {
            if !SharedSearchDataStore.shared.isInSearchMode {
                SharedSearchDataStore.shared.isInSearchMode = false
            }
        }
    }
    
    // Helper function to format timestamp to readable date
    func formatDate(_ timestamp: Int) -> String {
        if timestamp <= 0 {
            return "No date"
        }
        
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM yyyy"
        return formatter.string(from: date)
    }
    
    // Helper function to calculate trip duration
    func calculateTripDuration(_ result: FlightResult) -> String {
        if let inbound = result.inbound, let inboundDeparture = inbound.departure, inboundDeparture > 0 {
            let outboundDate = Date(timeIntervalSince1970: TimeInterval(result.outbound.departure ?? 0))
            let inboundDate = Date(timeIntervalSince1970: TimeInterval(inboundDeparture))
            let days = Calendar.current.dateComponents([.day], from: outboundDate, to: inboundDate).day ?? 0
            return "\(days) days trip"
        } else {
            return "One way trip"
        }
    }
}



// MARK: - Multi-City Extensions
extension ExploreViewModel {
    
    func updateMultiCityTripLocation(at index: Int, location: AutocompleteResult, isFrom: Bool) {
        guard index < multiCityTrips.count else { return }
        
        if isFrom {
            multiCityTrips[index].fromLocation = location.cityName
            multiCityTrips[index].fromIataCode = location.iataCode
        } else {
            multiCityTrips[index].toLocation = location.cityName
            multiCityTrips[index].toIataCode = location.iataCode
        }
        
        let sharedData = SharedSearchDataStore.shared
        if index < sharedData.multiCityTrips.count {
            if isFrom {
                sharedData.multiCityTrips[index].fromLocation = location.cityName
                sharedData.multiCityTrips[index].fromIataCode = location.iataCode
            } else {
                sharedData.multiCityTrips[index].toLocation = location.cityName
                sharedData.multiCityTrips[index].toIataCode = location.iataCode
            }
        }
    }
    
    func updateMultiCityTripDate(at index: Int, date: Date) {
        guard index < multiCityTrips.count else { return }
        
        multiCityTrips[index].date = date
        
        let sharedData = SharedSearchDataStore.shared
        if index < sharedData.multiCityTrips.count {
            sharedData.multiCityTrips[index].date = date
        }
    }

}
