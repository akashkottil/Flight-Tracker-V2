import SwiftUI

struct FlightTrackerScreen: View {
    @State private var selectedTab = 0 // Default to Tracked tab (0)
    @State private var searchText = ""
    @State private var selectedFlightType = 0 // 0 for Departures, 1 for Arrivals
    @State private var showingTrackLocationSheet = false
    @State private var currentSheetSource: SheetSource = .trackedTab
    @State private var currentSearchType: FlightSearchType? = nil
    
    // Selected airport data (current session)
    @State private var selectedDepartureAirport: FlightTrackAirport?
    @State private var selectedArrivalAirport: FlightTrackAirport?
    
    // Tracked tab specific data
    @State private var trackedDepartureAirport: FlightTrackAirport?
    @State private var trackedArrivalAirport: FlightTrackAirport?
    @State private var trackedSelectedDate: String?
    @State private var trackedFlightNumber: String = ""
    @State private var trackedSearchType: TrackedSearchType?
    
    // ADDED: Calendar integration
    @State private var selectedCustomDate: Date?
    
    // UPDATED: Navigation states for tracked tab
    @State private var showingTrackedDetails = false // For airport search results
    @State private var showingFlightDetail = false   // For flight search results
    @State private var trackedFlightDetail: FlightDetail?
    @State private var trackedScheduleResults: [ScheduleResult] = []
    @State private var trackedAPIError: String?
    @State private var isLoadingTrackedResults = false
    
    // ADDED: Flight detail navigation parameters
    @State private var flightDetailNumber: String = ""
    @State private var flightDetailDate: String = ""
    
    
    // ADDED: Recently viewed flights for tracked tab
    @State private var recentlyViewedFlights: [TrackedFlightData] = [] {
        didSet {
            // Keep only last 10 flights to reduce memory
            if recentlyViewedFlights.count > 10 {
                recentlyViewedFlights = Array(recentlyViewedFlights.prefix(10))
            }
        }
    }
    
    // ADDED: Cached flight results for better performance
    @State private var cachedDepartureResults: [FlightInfo] = [] {
        didSet {
            // Limit cache size
            if cachedDepartureResults.count > 50 {
                cachedDepartureResults = Array(cachedDepartureResults.prefix(50))
            }
        }
    }
    @State private var cachedArrivalResults: [FlightInfo] = [] {
        didSet {
            // Limit cache size
            if cachedArrivalResults.count > 50 {
                cachedArrivalResults = Array(cachedArrivalResults.prefix(50))
            }
        }
    }
    
    @State private var currentCachedAirport: FlightTrackAirport?
    @State private var lastCachedDate: String?
    
    // Schedule data
    @State private var scheduleResults: [FlightInfo] = []
    @State private var isLoadingSchedules = false
    @State private var scheduleError: String?
    
    // Recent search management
    @State private var displayingRecentResults: [FlightInfo] = []
    @State private var hasRecentSearch = false
    
    // ADDED: Last searched airport storage (persistent)
    @State private var lastSearchedAirportData: LastSearchedAirportData?
    @State private var lastSearchType: FlightSearchType = .departure
    
    
    
    // Network manager
    private let networkManager = FlightTrackNetworkManager.shared
    
    @State private var currentPlaceholder: String = "flight number"
    @State private var placeholderIndex: Int = 0
    @State private var placeholderOpacity: Double = 1.0

    let placeholderSuggestions = ["flights", "airlines", "airports"]


    @State private var timer: Timer? = nil
    
    @State private var nextPlaceholder: String = ""
    @State private var animatePlaceholder = false
    
    @State private var resetMarquee = false


    
    var body: some View {
        NavigationView {
            ZStack {
                // Background Gradient
                GradientColor.BlueWhite
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Tab Selection
                    tabSelectionView
                    
                    // Content based on selected tab
                    if selectedTab == 0 {
                        trackedTabContent
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                    } else {
                        scheduledTabContent
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                    
                    Spacer()
                }
                .animation(.easeInOut(duration: 0.3), value: selectedTab) // ADDED: Smooth tab transition
                .onAppear {
                    loadRecentSearchData()
                    loadRecentlyViewedFlights()
                    if selectedTab == 1 {
                        loadLastSearchedAirport()
                    }
                    
                    // START ANIMATION TIMER IF NOT ALREADY RUNNING
                    if timer == nil {
                        startPlaceholderTimer()
                    }

                    // Setup performance monitoring
                    PerformanceMonitor.shared
                }

                .onReceive(NotificationCenter.default.publisher(for: .memoryPressure)) { _ in
                    handleMemoryPressure()
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingTrackLocationSheet) {
            trackLocationSheet(
                isPresented: $showingTrackLocationSheet,
                source: currentSheetSource,
                searchType: currentSearchType,
                onLocationSelected: handleLocationSelected,
                onDateSelected: currentSheetSource == .trackedTab ? handleDateSelected : nil,
                onFlightNumberEntered: currentSheetSource == .trackedTab ? handleFlightNumberEntered : nil,
                onSearchCompleted: currentSheetSource == .trackedTab ? handleTrackedSearchCompleted : nil,
                onCustomDateSelected: currentSheetSource == .trackedTab ? handleCustomDateSelected : nil
            )
            .transition(.move(edge: .bottom).combined(with: .opacity)) // ADDED: Better sheet animation
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingTrackLocationSheet)
        }
        // UPDATED: Better navigation animations for TrackedDetailsScreen
        .fullScreenCover(isPresented: $showingTrackedDetails) {
            if !trackedScheduleResults.isEmpty {
                TrackedDetailsScreen(
                    flightDetail: nil,
                    scheduleResults: trackedScheduleResults,
                    searchType: .airport,
                    departureAirport: trackedDepartureAirport,
                    arrivalAirport: trackedArrivalAirport
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        // UPDATED: Better navigation animations for FlightDetailScreen
        .fullScreenCover(isPresented: $showingFlightDetail) {
            FlightDetailScreen(
                flightNumber: flightDetailNumber,
                date: flightDetailDate,
                onFlightViewed: { flight in
                    addRecentlyViewedFlight(flight)
                }
            )
            .transition(.asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
        }
    }
    
    // MARK: - Enhanced Tracked Tab Handlers
    
    private func handleFlightNumberEntered(_ flightNumber: String) {
        trackedFlightNumber = flightNumber
        print("✈️ Flight number entered: \(flightNumber)")
    }
    
    // ADDED: Calendar integration handler
    private func handleCustomDateSelected(_ date: Date) {
        selectedCustomDate = date
        print("📅 Custom date selected: \(date)")
    }
    
    private func handleTrackedSearchCompleted(searchType: TrackedSearchType, flightNumber: String?, departureAirport: FlightTrackAirport?, arrivalAirport: FlightTrackAirport?, selectedDate: String?) {
        
        guard let selectedDate = selectedDate else {
            print("❌ No date selected")
            return
        }
        
        let apiDate = convertDateToAPIFormat(selectedDate)
        
        Task {
            await performTrackedSearch(
                searchType: searchType,
                flightNumber: flightNumber,
                departureAirport: departureAirport,
                arrivalAirport: arrivalAirport,
                date: apiDate
            )
        }
    }
    
    // UPDATED: Better animation for tracked search completion
    @MainActor
    private func performTrackedSearch(
        searchType: TrackedSearchType,
        flightNumber: String?,
        departureAirport: FlightTrackAirport?,
        arrivalAirport: FlightTrackAirport?,
        date: String
    ) async {
        isLoadingTrackedResults = true
        trackedAPIError = nil
        
        do {
            if searchType == .flight, let flightNumber = flightNumber {
                // Call flight detail API for airline search
                print("🔍 Calling flight detail API for: \(flightNumber), date: \(date)")
                let response = try await networkManager.fetchFlightDetail(flightNumber: flightNumber, date: date)
                trackedFlightDetail = response.result
                trackedScheduleResults = []
                
                // Add to recently viewed
                addRecentlyViewedFlight(createTrackedFlightData(from: response.result, date: date))
                
                // UPDATED: Navigate to FlightDetailScreen with animation delay
                flightDetailNumber = flightNumber
                flightDetailDate = date
                
                // Small delay for smooth animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showingFlightDetail = true
                    }
                }
                
            } else if searchType == .airport {
                // Call schedules API for airport search
                let departureId = departureAirport?.iataCode
                let arrivalId = arrivalAirport?.iataCode
                
                print("🔍 Calling schedules API - dep: \(departureId ?? "nil"), arr: \(arrivalId ?? "nil"), date: \(date)")
                let response = try await networkManager.searchSchedules(
                    departureId: departureId,
                    arrivalId: arrivalId,
                    date: date
                )
                trackedScheduleResults = response.results
                trackedFlightDetail = nil
                
                // UPDATED: Navigate to TrackedDetailsScreen with animation delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showingTrackedDetails = true
                    }
                }
            }
            
        } catch {
            trackedAPIError = error.localizedDescription
            print("❌ Tracked search error: \(error)")
        }
        
        isLoadingTrackedResults = false
    }
    
    private func createTrackedFlightData(from flightDetail: FlightDetail, date: String) -> TrackedFlightData {
        return TrackedFlightData(
            id: "\(flightDetail.flightIata)_\(date)",
            flightNumber: flightDetail.flightIata,
            airlineName: flightDetail.airline.name,
            status: flightDetail.status ?? "Unknown",
            departureTime: formatTime(flightDetail.departure.scheduled.local),
            departureAirport: flightDetail.departure.airport.iataCode,
            departureDate: formatDateOnly(flightDetail.departure.scheduled.local),
            arrivalTime: formatTime(flightDetail.arrival.scheduled.local),
            arrivalAirport: flightDetail.arrival.airport.iataCode,
            arrivalDate: formatDateOnly(flightDetail.arrival.scheduled.local),
            duration: calculateDuration(departure: flightDetail.departure.scheduled.local, arrival: flightDetail.arrival.scheduled.local),
            flightType: "Direct",
            date: date
        )
    }
    
    // MARK: - Helper Methods for Time Formatting
    
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
    
    private func formatDateOnly(_ timeString: String?) -> String {
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
                dateFormatter.dateFormat = "dd MMM"
                return dateFormatter.string(from: date)
            }
        }
        return timeString
    }
    
    private func calculateDuration(departure: String?, arrival: String?) -> String {
        guard let depString = departure, let arrString = arrival else { return "--h --min" }
        
        let formatter = DateFormatter()
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss"
        ]
        
        var depDate: Date?
        var arrDate: Date?
        
        for format in formats {
            formatter.dateFormat = format
            if depDate == nil {
                depDate = formatter.date(from: depString)
            }
            if arrDate == nil {
                arrDate = formatter.date(from: arrString)
            }
            if depDate != nil && arrDate != nil {
                break
            }
        }
        
        guard let departureDate = depDate, let arrivalDate = arrDate else { return "--h --min" }
        
        let duration = arrivalDate.timeIntervalSince(departureDate)
        let hours = Int(duration) / 3600
        let minutes = Int(duration.truncatingRemainder(dividingBy: 3600)) / 60
        
        return "\(hours)h \(minutes)min"
    }
    
    // MARK: - Helper Methods for Handler Functions
    
    private func handleLocationSelected(_ airport: FlightTrackAirport) {
        Task {
            await handleLocationSelection(airport)
        }
    }
    
    private func handleDateSelected(_ date: String) {
        trackedSelectedDate = date
        Task {
            await checkTrackedSearchReady()
        }
    }
    
    @MainActor
    private func handleLocationSelection(_ airport: FlightTrackAirport) async {
        switch currentSheetSource {
        case .trackedTab:
            // For tracked tab, we need to determine if this is departure or arrival
            if trackedDepartureAirport == nil {
                trackedDepartureAirport = airport
            } else {
                trackedArrivalAirport = airport
                await checkTrackedSearchReady()
            }
            
        case .scheduledDeparture:
            // ADDED: Clear cache if location is different
            if selectedDepartureAirport?.iataCode != airport.iataCode {
                clearCache()
            }
            selectedDepartureAirport = airport
            selectedArrivalAirport = nil
            // Save as last searched airport
            saveLastSearchedAirport(airport, searchType: .departure)
            // Make API call for scheduled departures
            await fetchScheduleResults(departureId: airport.iataCode, arrivalId: nil)
            
        case .scheduledArrival:
            // ADDED: Clear cache if location is different
            if selectedArrivalAirport?.iataCode != airport.iataCode {
                clearCache()
            }
            selectedArrivalAirport = airport
            selectedDepartureAirport = nil
            // Save as last searched airport
            saveLastSearchedAirport(airport, searchType: .arrival)
            // Make API call for scheduled arrivals
            await fetchScheduleResults(departureId: nil, arrivalId: airport.iataCode)
        }
    }
    
    @MainActor
    private func checkTrackedSearchReady() async {
        guard let departure = trackedDepartureAirport,
              let arrival = trackedArrivalAirport,
              let dateString = trackedSelectedDate else {
            return
        }
        
        let formattedDate = convertDateToAPIFormat(dateString)
        await fetchScheduleResults(
            departureId: departure.iataCode,
            arrivalId: arrival.iataCode,
            date: formattedDate
        )
    }
    
    // UPDATED: Handle custom dates in API format conversion
    private func convertDateToAPIFormat(_ dateSelection: String) -> String {
        let calendar = Calendar.current
        let today = Date()
        
        switch dateSelection {
        case "yesterday":
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            return formatDateForAPI(yesterday)
        case "today":
            return formatDateForAPI(today)
        case "tomorrow":
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
            return formatDateForAPI(tomorrow)
        case "dayafter":
            let dayAfter = calendar.date(byAdding: .day, value: 2, to: today)!
            return formatDateForAPI(dayAfter)
        case "custom":
            // ADDED: Handle custom date from calendar
            if let customDate = selectedCustomDate {
                return formatDateForAPI(customDate)
            } else {
                return formatDateForAPI(today)
            }
        default:
            return formatDateForAPI(today)
        }
    }
    
    private func formatDateForAPI(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: date)
    }
    
    // Helper methods for navigation
    private func getCurrentDateForAPI() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: Date())
    }
    
    private func getSelectedDateForAPI() -> String {
        guard let selectedDate = trackedSelectedDate else {
            return getCurrentDateForAPI()
        }
        return convertDateToAPIFormat(selectedDate)
    }
    
    // MARK: - Recently Viewed Flights Management
    
    private func addRecentlyViewedFlight(_ flight: TrackedFlightData) {
        // Remove any existing instance of the same flight (same flight number + date)
        recentlyViewedFlights.removeAll { existingFlight in
            existingFlight.flightNumber == flight.flightNumber && existingFlight.date == flight.date
        }
        
        // Add the flight to the beginning of the list (most recent)
        recentlyViewedFlights.insert(flight, at: 0)
        
        // Keep only the last 5 unique viewed flights
        if recentlyViewedFlights.count > 5 {
            recentlyViewedFlights = Array(recentlyViewedFlights.prefix(5))
        }
        
        saveRecentlyViewedFlights()
        
        print("📱 Recently viewed flights updated:")
        for (index, flight) in recentlyViewedFlights.enumerated() {
            print("  \(index + 1). \(flight.flightNumber) (\(flight.airlineName)) - \(flight.date)")
        }
    }
    
    private func saveRecentlyViewedFlights() {
        if let data = try? JSONEncoder().encode(recentlyViewedFlights) {
            UserDefaults.standard.set(data, forKey: "RecentlyViewedFlights")
        }
    }
    
    private func loadRecentlyViewedFlights() {
        guard let data = UserDefaults.standard.data(forKey: "RecentlyViewedFlights"),
              let flights = try? JSONDecoder().decode([TrackedFlightData].self, from: data) else {
            return
        }
        recentlyViewedFlights = flights
    }
    
    // MARK: - Cache Management
    
    private func clearCache() {
        cachedDepartureResults = []
        cachedArrivalResults = []
        currentCachedAirport = nil
        lastCachedDate = nil
        print("🗑️ Cache cleared")
    }
    
    // MARK: - UI Components
    
    private var headerView: some View {
        VStack(spacing: 20) {
            Text("Track Flights")
                .font(.system(size: 24))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 10)
        }
    }
    
    // UPDATED: Tab Selection with Better Animation
    private var tabSelectionView: some View {
        HStack(spacing: 0) {
            Spacer()
            
            HStack(spacing: 0) {
                // Tracked Tab
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) { // ADDED: Smooth animation
                        selectedTab = 0
                        currentSheetSource = .trackedTab
                        clearCurrentSessionData()
                        resetMarquee = true
                    }
                }) {
                    Text("Tracked")
                        .font(selectedTab == 0 ? Font.system(size: 13, weight: .bold) : Font.system(size: 13, weight: .regular))
                        .foregroundColor(selectedTab == 0 ? Color(hex: "006CE3") : .black)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .background(
                            selectedTab == 0 ? Color.white : Color.clear
                        )
                        .cornerRadius(20)
                        .padding(.horizontal, 4)
                        .scaleEffect(selectedTab == 0 ? 1.05 : 1.0) // ADDED: Subtle scale effect
                        .animation(.easeInOut(duration: 0.2), value: selectedTab)
                }
                
                // Scheduled Tab
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) { // ADDED: Smooth animation
                        selectedTab = 1
                        currentSheetSource = .scheduledDeparture
                        clearCurrentSessionData()
                        loadLastSearchedAirport()
                        resetMarquee = true
                    }
                }) {
                    Text("Scheduled")
                        .font(selectedTab == 1 ? Font.system(size: 13, weight: .bold) : Font.system(size: 13, weight: .regular))
                        .foregroundColor(selectedTab == 1 ? Color(hex: "006CE3") : .black)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .background(
                            selectedTab == 1 ? Color.white : Color.clear
                        )
                        .cornerRadius(20)
                        .padding(.horizontal, 4)
                        .scaleEffect(selectedTab == 1 ? 1.05 : 1.0) // ADDED: Subtle scale effect
                        .animation(.easeInOut(duration: 0.2), value: selectedTab)
                }
            }
            .padding(.vertical,6)
            .padding(.horizontal, 4)
            .frame(width: 250)
            .background(Color(hex: "EFF1F4"))
            .cornerRadius(25)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var trackedTabContent: some View {
        VStack(spacing: 20) {
            trackedSearchFieldView
            
            if !recentlyViewedFlights.isEmpty {
                recentlyViewedFlightsListView
            } else if isLoadingSchedules {
                VStack(spacing: 0) {
                    flightListHeader
                    // Shimmer Loading with staggered animation
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(0..<12, id: \.self) { index in // Changed from 6 to 12
                                FlightRowShimmer()
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                    .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.1), value: isLoadingSchedules)

                                if index < 11 { // Change this from 5 to 11 for the correct divider placement
                                    Divider()
                                }
                            }
                        }
                    }

                    .scrollIndicators(.hidden)
                    .padding(.horizontal, 20)
                }
            } else if let error = scheduleError {
                errorView(error)
            } else if !scheduleResults.isEmpty {
                VStack(spacing: 0) {
                    flightListHeader
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(scheduleResults.indices, id: \.self) { index in
                                NavigationLink(destination: FlightDetailScreen(
                                    flightNumber: scheduleResults[index].flightNumber,
                                    date: getSelectedDateForAPI(),
                                    onFlightViewed: { flight in
                                        addRecentlyViewedFlight(flight)
                                    }
                                )) {
                                    // FIXED: Remove the extra schedule parameter
                                    flightRowContent(scheduleResults[index])
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                if index < scheduleResults.count - 1 {
                                    Divider()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            } else {
                Spacer()
                
                VStack(spacing: 16) {
                    ZStack {
                        Image("NoFlights")
                            .frame(width: 92, height: 92)
                    }
                    
                    Text("No Tracked Flights")
                        .font(.system(size: 22))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Text("Check real-time flight status instantly")
                        .font(.system(size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
        }
    }
    
    private var recentlyViewedFlightsListView: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(recentlyViewedFlights) { flight in
                        NavigationLink(destination: FlightDetailScreen(
                            flightNumber: flight.flightNumber,
                            date: flight.date,
                            onFlightViewed: { flight in
                                addRecentlyViewedFlight(flight)
                            }
                        )) {
                            TrackedFlightCard(
                                airlineLogo: "FlightTrackLogo",
                                airlineName: flight.airlineName,
                                flightNumber: flight.flightNumber,
                                status: flight.status,
                                departureTime: flight.departureTime,
                                departureAirport: flight.departureAirport,
                                departureDate: flight.departureDate,
                                arrivalTime: flight.arrivalTime,
                                arrivalAirport: flight.arrivalAirport,
                                arrivalDate: flight.arrivalDate,
                                duration: flight.duration,
                                flightType: flight.flightType
                                // ✅ REMOVED: airlineIataCode parameter
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .scrollIndicators(.hidden)
        }
    }
    
    private var scheduledTabContent: some View {
        VStack(spacing: 0) {
            // Search Field for Scheduled
            scheduledSearchFieldView
            
            // Departures/Arrivals Filter
            departureArrivalFilter
            
            // Show loading, error, or results
            if isLoadingSchedules {
                loadingSchedulesView
            } else if let error = scheduleError {
                errorView(error)
            } else if !scheduleResults.isEmpty {
                // Show API results (current search)
                scheduleFlightListView
            } else if !displayingRecentResults.isEmpty {
                // Show recent search results
                recentSearchFlightListView
            } else {
                // Show empty state for no searches
                scheduledEmptyStateView
            }
        }
    }
    
    private var trackedSearchFieldView: some View {
        HStack {
            HStack {
                if !searchText.isEmpty {
                    // Show the current search text
                    Text(searchText)
                        .foregroundColor(.black)
                        .font(.system(size: 16, weight: .regular))
                } else {
                    HStack(spacing: 4) {
                        Text("Try Searching")

                        ZStack {
                            Text("'\(currentPlaceholder)'")
                                .id(currentPlaceholder) // Ensure transition triggers
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                                .animation(.easeInOut(duration: 0.5), value: currentPlaceholder)
                        }
                    }
                    .foregroundColor(.gray)
                    .font(.system(size: 16, weight: .regular))


                }

                Spacer()

                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.3), lineWidth: 1)
            )
            .onTapGesture {
                openTrackLocationSheet(source: .trackedTab)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    
    private var scheduledSearchFieldView: some View {
        HStack {
            HStack {
                if selectedFlightType == 0 { // Departures
                    if let selectedAirport = selectedDepartureAirport {
                        // Current session selection (black text)
                        Text(selectedAirport.iataCode)
                            .foregroundColor(.black)
                            .font(.system(size: 14, weight: .semibold))
                        Text(selectedAirport.city)
                            .foregroundColor(.black)
                            .font(.system(size: 16, weight: .regular))
                    } else if let lastAirportData = lastSearchedAirportData,
                              (lastAirportData.searchType == "departure" || lastAirportData.searchType == "both") {
                        // Last searched location (gray text)
                        Text(lastAirportData.iataCode)
                            .foregroundColor(.gray)
                            .font(.system(size: 14, weight: .semibold))
                        Text(lastAirportData.city)
                            .foregroundColor(.gray)
                            .font(.system(size: 16, weight: .regular))
                    } else {
                        Text("Select departure airport")
                            .foregroundColor(.gray)
                            .font(.system(size: 16, weight: .regular))
                    }
                } else { // Arrivals
                    if let selectedAirport = selectedArrivalAirport {
                        // Current session selection (black text)
                        Text(selectedAirport.iataCode)
                            .foregroundColor(.black)
                            .font(.system(size: 14, weight: .semibold))
                        Text(selectedAirport.city)
                            .foregroundColor(.black)
                            .font(.system(size: 16, weight: .regular))
                    } else if let lastAirportData = lastSearchedAirportData,
                              (lastAirportData.searchType == "arrival" || lastAirportData.searchType == "both") {
                        // Last searched location (gray text)
                        Text(lastAirportData.iataCode)
                            .foregroundColor(.gray)
                            .font(.system(size: 14, weight: .semibold))
                        Text(lastAirportData.city)
                            .foregroundColor(.gray)
                            .font(.system(size: 16, weight: .regular))
                    } else {
                        Text("Select arrival airport")
                            .foregroundColor(.gray)
                            .font(.system(size: 16, weight: .regular))
                    }
                }
                
                Spacer()
                
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.3), lineWidth: 1)
            )
            .font(.system(size: 16))
            .onTapGesture {
                if selectedFlightType == 0 {
                    openTrackLocationSheet(source: .scheduledDeparture)
                } else {
                    openTrackLocationSheet(source: .scheduledArrival)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var departureArrivalFilter: some View {
        HStack(spacing: 12) {
            Button(action: {
                // Switch to departures
                let previousFlightType = selectedFlightType
                selectedFlightType = 0
                currentSheetSource = .scheduledDeparture
                
                // ENHANCED: Smart location swapping and caching logic
                switchToFlightType(.departure, from: previousFlightType)
            }) {
                Text("Departures")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(selectedFlightType == 0 ? Color(hex: "006CE3") : .black)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        selectedFlightType == 0 ? Color.white : Color.clear
                    )
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selectedFlightType == 0 ? Color(hex: "006CE3") : Color.gray, lineWidth: 1)
                    )
            }
            
            Button(action: {
                // Switch to arrivals
                let previousFlightType = selectedFlightType
                selectedFlightType = 1
                currentSheetSource = .scheduledArrival
                
                // ENHANCED: Smart location swapping and caching logic
                switchToFlightType(.arrival, from: previousFlightType)
            }) {
                Text("Arrivals")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(selectedFlightType == 1 ? Color(hex: "006CE3") : .black)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        selectedFlightType == 1 ? Color.white : Color.clear
                    )
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selectedFlightType == 1 ? Color(hex: "006CE3") : Color.gray, lineWidth: 1)
                    )
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // UPDATED: Enhanced Error View with Animation
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
                .scaleEffect(scheduleError != nil ? 1.0 : 0.5)
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: scheduleError)
            
            Text("Error loading flights")
                .font(.system(size: 18, weight: .semibold))
                .opacity(scheduleError != nil ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.4).delay(0.2), value: scheduleError)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .opacity(scheduleError != nil ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.4).delay(0.4), value: scheduleError)
            
            Spacer()
        }
        .transition(.opacity.combined(with: .scale))
    }
    
    // UPDATED: Enhanced Loading States with Animation
    private var loadingSchedulesView: some View {
        VStack(spacing: 0) {
            // Flight List Header
            flightListHeader
            
            // Shimmer Loading with staggered animation
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(0..<12, id: \.self) { index in // Changed from 6 to 12
                        FlightRowShimmer()
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.1), value: isLoadingSchedules)

                        if index < 11 { // Change this from 5 to 11 for the correct divider placement
                            Divider()
                        }
                    }
                }
            }

            .scrollIndicators(.hidden)
            .padding(.horizontal, 20)
        }
    }
    
    private var scheduleFlightListView: some View {
        VStack(spacing: 0) {
            // Flight List Header
            flightListHeader
            
            // Flight List from API
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(scheduleResults.indices, id: \.self) { index in
                        NavigationLink(destination: FlightDetailScreen(
                            flightNumber: scheduleResults[index].flightNumber,
                            date: getCurrentDateForAPI(),
                            onFlightViewed: { flight in
                                addRecentlyViewedFlight(flight)
                            }
                        )) {
                            flightRowContent(scheduleResults[index])
                                .transition(.move(edge: .top).combined(with: .opacity))
                                .animation(.easeInOut(duration: 0.4).delay(Double(index) * 0.05), value: scheduleResults)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if index < scheduleResults.count - 1 {
                            Divider()
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, 20)
        }
    }
    
    private var recentSearchFlightListView: some View {
        VStack(spacing: 0) {
            flightListHeader
            
            // Flight List from Recent Search
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(displayingRecentResults.indices, id: \.self) { index in
                        NavigationLink(destination: FlightDetailScreen(
                            flightNumber: displayingRecentResults[index].flightNumber,
                            date: getCurrentDateForAPI(),
                            onFlightViewed: { flight in
                                addRecentlyViewedFlight(flight)
                            }
                        )) {
                            flightRowContent(displayingRecentResults[index])
                                .transition(.move(edge: .top).combined(with: .opacity))
                                .animation(.easeInOut(duration: 0.4).delay(Double(index) * 0.05), value: displayingRecentResults)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if index < displayingRecentResults.count - 1 {
                            Divider()
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, 20)
        }
    }
    
    private var scheduledEmptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 16) {
                ZStack {
                    Image("NoFlights")
                        .frame(width: 92, height: 92)
                }
                
                Text("Search any flights")
                    .font(.system(size: 22))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Text("Find departures and arrivals for any airport")
                    .font(.system(size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
    
    private var flightListHeader: some View {
        VStack(spacing: 0) {
            HStack {
                HStack {
                    Text("Flights")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)

                    Image("FilterIcon")
                        .resizable()
                        .frame(width: 20, height: 20)
                }

                Spacer()

                Text("To")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)

                Spacer()

                Text("Time")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)

                Spacer()

                Text("Status")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 30)
            .padding(.top, 24)
            .padding(.bottom, 12)

            Divider()
                .background(Color.gray.opacity(0.4))
                .padding(.horizontal, 24)
        }
    }
    
    // Create a separate content view for reusability
    private func flightRowContent(_ flight: FlightInfo) -> some View {
        HStack(alignment: .top, spacing: 10) {
            
            HStack{
                // UPDATED: Use airline IATA code from FlightInfo
                AirlineLogoView(
                            iataCode: flight.airlineIataCode ?? flight.flightNumber.airlineIataCode,
                            fallbackImage: "FlightTrackLogo",
                            size: 24
                        )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(flight.flightNumber)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                    
                    MarqueeText(text: flight.airline, font: .system(size: 14))
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                        .frame(height: 20) // Optional height
                        .id("\(resetMarquee ? "reset" : "")-\(flight.flightNumber)")
                }
                .frame(width: 70)
            }
            
            
            Spacer(minLength: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(flight.destination)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                
//                Text(flight.destinationName)
//                    .font(.system(size: 12))
//                    .fontWeight(.semibold)
//                    .foregroundColor(.gray)
                
                MarqueeText(text: flight.destinationName, font: .system(size: 14))
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                    .frame(height: 20)
            }
//            .frame(width:45)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 2) {
                Text(flight.time)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                
                Text(flight.scheduledTime)
                    .font(.system(size: 12))
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(flight.status.displayText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(flight.status == .cancelled ? .white : .rainForest)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(
                        flight.status == .cancelled ? Color.red : Color.clear
                    )
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(flight.status == .cancelled ? Color.red : Color.rainForest, lineWidth: 1)
                    )

                if !flight.delay.isEmpty {
                    Text(flight.delay)
                        .font(.system(size: 12))
                        .foregroundColor(flight.status.delayColor)
                }
            }.frame(width: 70, height: 34)
        }
        .padding(.vertical, 12)
    }
    private func openTrackLocationSheet(source: SheetSource) {
        // Force state update before showing sheet
        DispatchQueue.main.async {
            self.currentSheetSource = source
            self.currentSearchType = self.selectedFlightType == 0 ? .departure : .arrival
            
            // Small delay to ensure state is properly updated
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.showingTrackLocationSheet = true
            }
        }
    }
    
    // MARK: - Data Management Methods
    
    private func clearScheduleResults() {
        scheduleResults = []
        scheduleError = nil
        isLoadingSchedules = false
    }
    
    private func clearCurrentSessionData() {
        clearScheduleResults()
        trackedDepartureAirport = nil
        trackedArrivalAirport = nil
        trackedSelectedDate = nil
        trackedFlightNumber = ""
        trackedSearchType = nil
        selectedDepartureAirport = nil
        selectedArrivalAirport = nil
        cachedDepartureResults = []
        cachedArrivalResults = []
        currentCachedAirport = nil
        lastCachedDate = nil
        displayingRecentResults = []
        
        // Clear tracked tab specific data
        trackedFlightDetail = nil
        trackedScheduleResults = []
        trackedAPIError = nil
        
        // ADDED: Reset navigation states
        showingTrackedDetails = false
        showingFlightDetail = false
        flightDetailNumber = ""
        flightDetailDate = ""
        
        // ADDED: Clear custom date when switching tabs
        selectedCustomDate = nil
        
        if selectedTab == 0 {
            currentSheetSource = .trackedTab
        } else {
            currentSheetSource = selectedFlightType == 0 ? .scheduledDeparture : .scheduledArrival
        }
        
        if selectedTab == 1 {
            loadRecentSearchData()
        }
    }
    
    // MARK: - API Methods
    
    @MainActor
    private func fetchScheduleResults(departureId: String?, arrivalId: String?, date: String? = nil) async {
        isLoadingSchedules = true
        scheduleError = nil
        displayingRecentResults = []
        
        do {
            let response = try await networkManager.searchSchedules(
                departureId: departureId,
                arrivalId: arrivalId,
                date: date
            )
            
            scheduleResults = response.results.map { scheduleResult in
                convertScheduleToFlightInfo(scheduleResult, departureAirport: response.departureAirport, arrivalAirport: response.arrivalAirport)
            }
            
            // ADDED: Cache the results based on search type
            let currentDate = getCurrentDateForAPI()
            if let airportId = departureId ?? arrivalId {
                // Update cache info
                if currentCachedAirport?.iataCode != airportId {
                    currentCachedAirport = FlightTrackAirport(
                        iataCode: airportId,
                        icaoCode: nil,
                        name: "",
                        country: "",
                        countryCode: "",
                        isInternational: nil,
                        isMajor: nil,
                        city: "",
                        location: FlightTrackLocation(lat: 0.0, lng: 0.0),
                        timezone: FlightTrackTimezone(timezone: "", countryCode: "", gmt: 0.0, dst: 0.0)
                    )
                }
                lastCachedDate = currentDate
                
                // Cache results based on type
                if departureId != nil {
                    cachedDepartureResults = scheduleResults
                    print("💾 Cached departure results for \(airportId) (\(scheduleResults.count) flights)")
                } else {
                    cachedArrivalResults = scheduleResults
                    print("💾 Cached arrival results for \(airportId) (\(scheduleResults.count) flights)")
                }
            }
            
            if !scheduleResults.isEmpty {
                saveCurrentSearchLocally()
            }
            
        } catch {
            scheduleError = error.localizedDescription
            scheduleResults = []
            print("Schedule fetch error: \(error)")
        }
        
        isLoadingSchedules = false
    }
    
    private func switchToFlightType(_ targetType: FlightSearchType, from previousType: Int) {
        let currentDate = getCurrentDateForAPI()
        
        // Determine which airport to use
        var airportToUse: FlightTrackAirport?
        
        if targetType == .departure {
            // Switching to departures
            if let departureAirport = selectedDepartureAirport {
                airportToUse = departureAirport
            } else if let arrivalAirport = selectedArrivalAirport {
                // Swap: use arrival airport as departure
                airportToUse = arrivalAirport
                selectedDepartureAirport = arrivalAirport
                selectedArrivalAirport = nil
                print("🔄 Swapped arrival airport (\(arrivalAirport.iataCode)) to departure")
            } else if let lastAirportData = lastSearchedAirportData {
                // Use last searched airport
                let airport = FlightTrackAirport(
                    iataCode: lastAirportData.iataCode,
                    icaoCode: nil,
                    name: lastAirportData.name,
                    country: lastAirportData.country,
                    countryCode: "",
                    isInternational: nil,
                    isMajor: nil,
                    city: lastAirportData.city,
                    location: FlightTrackLocation(lat: 0.0, lng: 0.0),
                    timezone: FlightTrackTimezone(timezone: "", countryCode: "", gmt: 0.0, dst: 0.0)
                )
                selectedDepartureAirport = airport
                airportToUse = airport
            }
        } else {
            // Switching to arrivals
            if let arrivalAirport = selectedArrivalAirport {
                airportToUse = arrivalAirport
            } else if let departureAirport = selectedDepartureAirport {
                // Swap: use departure airport as arrival
                airportToUse = departureAirport
                selectedArrivalAirport = departureAirport
                selectedDepartureAirport = nil
                print("🔄 Swapped departure airport (\(departureAirport.iataCode)) to arrival")
            } else if let lastAirportData = lastSearchedAirportData {
                // Use last searched airport
                let airport = FlightTrackAirport(
                    iataCode: lastAirportData.iataCode,
                    icaoCode: nil,
                    name: lastAirportData.name,
                    country: lastAirportData.country,
                    countryCode: "",
                    isInternational: nil,
                    isMajor: nil,
                    city: lastAirportData.city,
                    location: FlightTrackLocation(lat: 0.0, lng: 0.0),
                    timezone: FlightTrackTimezone(timezone: "", countryCode: "", gmt: 0.0, dst: 0.0)
                )
                selectedArrivalAirport = airport
                airportToUse = airport
            }
        }
        
        guard let airport = airportToUse else {
            clearScheduleResults()
            return
        }
        
        // Check if we can use cached data
        let isSameAirport = currentCachedAirport?.iataCode == airport.iataCode
        let isSameDate = lastCachedDate == currentDate
        
        if isSameAirport && isSameDate {
            // Use cached data
            if targetType == .departure && !cachedDepartureResults.isEmpty {
                scheduleResults = cachedDepartureResults
                print("📋 Using cached departure results for \(airport.iataCode)")
                return
            } else if targetType == .arrival && !cachedArrivalResults.isEmpty {
                scheduleResults = cachedArrivalResults
                print("📋 Using cached arrival results for \(airport.iataCode)")
                return
            }
        }
        
        // Make API call if no cached data available
        Task {
            if targetType == .departure {
                await fetchScheduleResults(departureId: airport.iataCode, arrivalId: nil)
            } else {
                await fetchScheduleResults(departureId: nil, arrivalId: airport.iataCode)
            }
        }
    }
    
    // MARK: - Data Persistence Methods
    
    private func saveCurrentSearchLocally() {
        displayingRecentResults = scheduleResults
        hasRecentSearch = true
        
        if let data = try? JSONEncoder().encode(scheduleResults.map { flight in
            [
                "flightNumber": flight.flightNumber,
                "airline": flight.airline,
                "airlineIataCode": flight.airlineIataCode ?? "", // ADD THIS
                "destination": flight.destination,
                "destinationName": flight.destinationName,
                "time": flight.time,
                "scheduledTime": flight.scheduledTime,
                "status": flight.status.displayText,
                "delay": flight.delay
            ]
        }) {
            UserDefaults.standard.set(data, forKey: "LastFlightSearch")
            UserDefaults.standard.set(true, forKey: "HasRecentSearch")
        }
    }
    
    private func loadRecentSearchData() {
        hasRecentSearch = UserDefaults.standard.bool(forKey: "HasRecentSearch")
        
        if hasRecentSearch,
           let data = UserDefaults.standard.data(forKey: "LastFlightSearch"),
           let flightDicts = try? JSONDecoder().decode([[String: String]].self, from: data) {
            
            displayingRecentResults = flightDicts.compactMap { dict in
                guard let flightNumber = dict["flightNumber"],
                      let airline = dict["airline"],
                      let destination = dict["destination"],
                      let destinationName = dict["destinationName"],
                      let time = dict["time"],
                      let scheduledTime = dict["scheduledTime"],
                      let statusString = dict["status"],
                      let delay = dict["delay"] else {
                    // FIXED: Return nil instead of nothing
                    return nil
                }
                
                let status: FlightStatus
                switch statusString.lowercased() {
                case "expected": status = .expected
                case "landed": status = .landed
                case "cancelled": status = .cancelled
                default: status = .expected
                }
                
                return FlightInfo(
                    flightNumber: flightNumber,
                    airline: airline,
                    airlineIataCode: dict["airlineIataCode"], // ADD THIS - may be nil for old data
                    destination: destination,
                    destinationName: destinationName,
                    time: time,
                    scheduledTime: scheduledTime,
                    status: status,
                    delay: delay,
                    airlineColor: .blue
                )
            }
        }
    }
    
    private func saveLastSearchedAirport(_ airport: FlightTrackAirport, searchType: FlightSearchType) {
        lastSearchType = searchType
        
        let airportData = LastSearchedAirportData(
            iataCode: airport.iataCode,
            name: airport.name,
            city: airport.city,
            country: airport.country,
            searchType: searchType == .departure ? "departure" : "arrival"
        )
        
        lastSearchedAirportData = airportData
        
        if let data = try? JSONEncoder().encode(airportData) {
            UserDefaults.standard.set(data, forKey: "LastSearchedAirport")
        }
    }
    
    private func loadLastSearchedAirport() {
        guard let data = UserDefaults.standard.data(forKey: "LastSearchedAirport"),
              let airportData = try? JSONDecoder().decode(LastSearchedAirportData.self, from: data) else {
            return
        }
        
        lastSearchedAirportData = airportData
        lastSearchType = airportData.searchType == "departure" ? .departure : .arrival
        
        // ADDED: Auto-fetch results if we have last searched data and no current selection
        if selectedDepartureAirport == nil && selectedArrivalAirport == nil {
            // Create airport object from saved data
            let airport = FlightTrackAirport(
                iataCode: airportData.iataCode,
                icaoCode: nil,
                name: airportData.name,
                country: airportData.country,
                countryCode: "",
                isInternational: nil,
                isMajor: nil,
                city: airportData.city,
                location: FlightTrackLocation(lat: 0.0, lng: 0.0),
                timezone: FlightTrackTimezone(timezone: "", countryCode: "", gmt: 0.0, dst: 0.0)
            )
            
            if selectedFlightType == 0 && (airportData.searchType == "departure" || airportData.searchType == "both") {
                selectedDepartureAirport = airport
                Task {
                    await fetchScheduleResults(departureId: airportData.iataCode, arrivalId: nil)
                }
            } else if selectedFlightType == 1 && (airportData.searchType == "arrival" || airportData.searchType == "both") {
                selectedArrivalAirport = airport
                Task {
                    await fetchScheduleResults(departureId: nil, arrivalId: airportData.iataCode)
                }
            }
        }
    }
    
    // MARK: - FIXED: Updated Data Conversion Method to Handle Optional Airport
    
    private func convertScheduleToFlightInfo(_ schedule: ScheduleResult, departureAirport: FlightTrackAirport?, arrivalAirport: FlightTrackAirport?) -> FlightInfo {
        let departureTime = formatTimeString(schedule.departureTime)
        let arrivalTime = formatTimeString(schedule.arrivalTime)
        
        let destination: String
        let destinationName: String
        
        if currentSheetSource == .scheduledDeparture {
            // For departures, show the arrival airport
            if let airport = schedule.airport {
                destination = airport.iataCode
                destinationName = airport.city
            } else if let arrAirport = arrivalAirport {
                destination = arrAirport.iataCode
                destinationName = arrAirport.city
            } else {
                destination = "---"
                destinationName = "Unknown"
            }
        } else {
            // For arrivals, show the departure airport
            if let depAirport = departureAirport {
                destination = depAirport.iataCode
                destinationName = depAirport.city
            } else if let airport = schedule.airport {
                destination = airport.iataCode
                destinationName = airport.city
            } else {
                destination = "---"
                destinationName = "Unknown"
            }
        }
        
        let flightStatus: FlightStatus
        switch schedule.status.lowercased() {
        case "scheduled":
            flightStatus = .expected
        case "landed", "arrived":
            flightStatus = .landed
        case "cancelled":
            flightStatus = .cancelled
        default:
            flightStatus = .expected
        }
        
        return FlightInfo(
            flightNumber: schedule.flightNumber,
            airline: schedule.airline.name,
            airlineIataCode: schedule.airline.iataCode, // ADD THIS
            destination: destination,
            destinationName: destinationName,
            time: arrivalTime,
            scheduledTime: departureTime,
            status: flightStatus,
            delay: "",
            airlineColor: .blue
        )
    }
    
    private func formatTimeString(_ timeString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        if let date = formatter.date(from: timeString) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            return timeFormatter.string(from: date)
        }
        
        return timeString
    }
    
    func startPlaceholderTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            let nextIndex = (placeholderIndex + 1) % placeholderSuggestions.count
            placeholderIndex = nextIndex

            withAnimation {
                currentPlaceholder = placeholderSuggestions[nextIndex]
            }
        }
    }



    
    private func handleMemoryPressure() {
        // Clear caches on memory pressure
        APICache.shared.clearCache()
        ImageCache.shared.clearCache()
        
        // Reduce in-memory data
        if recentlyViewedFlights.count > 5 {
            recentlyViewedFlights = Array(recentlyViewedFlights.prefix(5))
        }
        
        if cachedDepartureResults.count > 20 {
            cachedDepartureResults = Array(cachedDepartureResults.prefix(20))
        }
        
        if cachedArrivalResults.count > 20 {
            cachedArrivalResults = Array(cachedArrivalResults.prefix(20))
        }
        
        print("🧹 Cleared caches due to memory pressure")
    }
    
}

// MARK: - Supporting Models (Keep existing)
struct LastSearchedAirportData: Codable {
    let iataCode: String
    let name: String
    let city: String
    let country: String
    let searchType: String
}

struct TrackedFlightData: Codable, Identifiable {
    let id: String
    let flightNumber: String
    let airlineName: String
    let status: String
    let departureTime: String
    let departureAirport: String
    let departureDate: String
    let arrivalTime: String
    let arrivalAirport: String
    let arrivalDate: String
    let duration: String
    let flightType: String
    let date: String
}

struct FlightInfo: Equatable {
    let flightNumber: String
    let airline: String
    let airlineIataCode: String? // ADD THIS FIELD
    let destination: String
    let destinationName: String
    let time: String
    let scheduledTime: String
    let status: FlightStatus
    let delay: String
    let airlineColor: Color
}

enum FlightStatus {
    case expected
    case landed
    case cancelled
    
    var displayText: String {
        switch self {
        case .expected: return "Expected"
        case .landed: return "Landed"
        case .cancelled: return "Cancelled"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .expected: return .clear
        case .landed: return .clear
        case .cancelled: return .red
        }
    }
    
    var delayColor: Color {
        switch self {
        case .expected: return .rainForest
        case .landed: return .rainForest
        case .cancelled: return .red
        }
    }
}

enum FlightTrackSearchType {
    case departure
    case arrival
}

#Preview {
    FlightTrackerScreen()
}
