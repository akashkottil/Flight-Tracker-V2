import SwiftUI

struct FlightTrackerScreen: View {
    @State private var selectedTab = 0 // FIXED: Default to Tracked tab (0) instead of Scheduled (1)
    @State private var searchText = ""
    @State private var selectedFlightType = 0 // 0 for Departures, 1 for Arrivals
    @State private var showingTrackLocationSheet = false
    @State private var currentSheetSource: SheetSource = .trackedTab // FIXED: Default to tracked tab
    @State private var currentSearchType: FlightSearchType? = nil
    
    // Selected airport data
    @State private var selectedDepartureAirport: FlightTrackAirport?
    @State private var selectedArrivalAirport: FlightTrackAirport?
    
    // Tracked tab specific data
    @State private var trackedDepartureAirport: FlightTrackAirport?
    @State private var trackedArrivalAirport: FlightTrackAirport?
    @State private var trackedSelectedDate: String?
    
    // Schedule data
    @State private var scheduleResults: [FlightInfo] = []
    @State private var isLoadingSchedules = false
    @State private var scheduleError: String?
    
    // ADDED: Recent search management - simplified for now
    @State private var displayingRecentResults: [FlightInfo] = []
    @State private var hasRecentSearch = false
    
    // ADDED: Last searched airport storage
    @State private var lastSearchedAirportData: LastSearchedAirportData?
    @State private var lastSearchType: FlightSearchType = .departure
    
    // Network manager
    private let networkManager = FlightTrackNetworkManager.shared
    
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
                    } else {
                        scheduledTabContent
                    }
                    
                    Spacer()
                }
                .onAppear {
                    loadRecentSearchData()
                    if selectedTab == 1 {
                        loadLastSearchedAirport()
                    }
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
                onDateSelected: currentSheetSource == .trackedTab ? handleDateSelected : nil
            )
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 20) {
            Text("Track Flights")
                .font(.system(size: 24))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 10)
        }
    }
    
    private var tabSelectionView: some View {
        HStack(spacing: 0) {
            Spacer()
            
            HStack(spacing: 0) {
                // Tracked Tab
                Button(action: {
                    selectedTab = 0
                    currentSheetSource = .trackedTab // FIXED: Reset sheet source when switching to tracked tab
                    clearAllData()
                }) {
                    Text("Tracked")
                        .font(selectedTab == 0 ? Font.system(size: 13, weight: .bold) : Font.system(size: 13, weight: .regular))
                        .foregroundColor(selectedTab == 0 ? Color(hex: "006CE3") : .black)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(
                            selectedTab == 0 ? Color.white : Color.clear
                        )
                        .cornerRadius(20)
                }
                
                // Scheduled Tab
                Button(action: {
                    selectedTab = 1
                    currentSheetSource = .scheduledDeparture // FIXED: Reset sheet source when switching to scheduled tab
                    clearAllData()
                }) {
                    Text("Scheduled")
                        .font(selectedTab == 1 ? Font.system(size: 13, weight: .bold) : Font.system(size: 13, weight: .regular))
                        .foregroundColor(selectedTab == 1 ? Color(hex: "006CE3") : .black)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(
                            selectedTab == 1 ? Color.white : Color.clear
                        )
                        .cornerRadius(20)
                }
            }
            .padding(4)
            .background(Color(hex: "EFF1F4"))
            .cornerRadius(24)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private func clearScheduleResults() {
        scheduleResults = []
        scheduleError = nil
        isLoadingSchedules = false
    }
    
    private func clearAllData() {
        clearScheduleResults()
        // Clear tracked tab data
        trackedDepartureAirport = nil
        trackedArrivalAirport = nil
        trackedSelectedDate = nil
        // Clear scheduled tab data
        selectedDepartureAirport = nil
        selectedArrivalAirport = nil
        // ADDED: Clear displaying recent results but keep stored recent searches
        displayingRecentResults = []
        
        // FIXED: Reset currentSheetSource based on current selected tab
        if selectedTab == 0 {
            currentSheetSource = .trackedTab
        } else {
            currentSheetSource = selectedFlightType == 0 ? .scheduledDeparture : .scheduledArrival
        }
        
        // Load recent search data when switching tabs
        if selectedTab == 1 { // Only load for scheduled tab
            loadRecentSearchData()
            loadLastSearchedAirport()
        }
    }
    
    private var trackedTabContent: some View {
        VStack(spacing: 20) {
            // Search Field for Tracked Tab
            trackedSearchFieldView
            
            // Show loading, results, or empty state
            if isLoadingSchedules {
                // Show shimmer loading
                VStack(spacing: 0) {
                    flightListHeader
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(0..<6, id: \.self) { index in
                                FlightRowShimmer()
                                
                                if index < 5 {
                                    Divider()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            } else if let error = scheduleError {
                errorView(error)
            } else if !scheduleResults.isEmpty {
                // Show API results
                VStack(spacing: 0) {
                    flightListHeader
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(scheduleResults.indices, id: \.self) { index in
                                NavigationLink(destination: FlightDetailScreen(
                                    flightNumber: scheduleResults[index].flightNumber,
                                    date: getSelectedDateForAPI()
                                )) {
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
                // Empty State
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
    
    private var loadingSchedulesView: some View {
        VStack(spacing: 0) {
            // Flight List Header
            flightListHeader
            
            // Shimmer Loading
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(0..<6, id: \.self) { index in
                        FlightRowShimmer()
                        
                        if index < 5 {
                            Divider()
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            Text("Error loading flights")
                .font(.system(size: 18, weight: .semibold))
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
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
                            date: getCurrentDateForAPI()
                        )) {
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
                            date: getCurrentDateForAPI()
                        )) {
                            flightRowContent(displayingRecentResults[index])
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if index < displayingRecentResults.count - 1 {
                            Divider()
                        }
                    }
                }
            }
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
    
    private var trackedSearchFieldView: some View {
        HStack {
            TextField("Try flight number \"6E 6083\"", text: $searchText)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.3), lineWidth: 1)
                )
                .font(.system(size: 14))
                .fontWeight(.semibold)
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
                        Text(selectedAirport.iataCode)
                            .foregroundColor(.black)
                            .font(.system(size: 14, weight: .semibold))
                        Text(selectedAirport.city)
                            .foregroundColor(.black)
                            .font(.system(size: 16, weight: .regular))
                    } else if let lastAirportData = lastSearchedAirportData {
                        // ADDED: Show last searched airport if no current selection
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
                        Text(selectedAirport.iataCode)
                            .foregroundColor(.black)
                            .font(.system(size: 14, weight: .semibold))
                        Text(selectedAirport.city)
                            .foregroundColor(.black)
                            .font(.system(size: 16, weight: .regular))
                    } else if let lastAirportData = lastSearchedAirportData {
                        // ADDED: Show last searched airport if no current selection
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
                selectedFlightType = 0
                currentSheetSource = .scheduledDeparture // FIXED: Update sheet source for departures
                
                // Transfer airport selection and make API call
                if let arrivalAirport = selectedArrivalAirport {
                    // User was on arrival tab, now switching to departure
                    // Use the arrival airport as departure airport
                    selectedDepartureAirport = arrivalAirport
                    selectedArrivalAirport = nil
                    Task {
                        await fetchScheduleResults(departureId: arrivalAirport.iataCode, arrivalId: nil)
                    }
                } else if let departureAirport = selectedDepartureAirport {
                    // Already have departure airport, just fetch departures
                    Task {
                        await fetchScheduleResults(departureId: departureAirport.iataCode, arrivalId: nil)
                    }
                } else if let lastAirportData = lastSearchedAirportData {
                    // ADDED: Use last searched airport for departures
                    Task {
                        await fetchScheduleResults(departureId: lastAirportData.iataCode, arrivalId: nil)
                    }
                } else {
                    // No airport selected, clear results
                    clearScheduleResults()
                }
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
                selectedFlightType = 1
                currentSheetSource = .scheduledArrival // FIXED: Update sheet source for arrivals
                
                // Transfer airport selection and make API call
                if let departureAirport = selectedDepartureAirport {
                    // User was on departure tab, now switching to arrival
                    // Use the departure airport as arrival airport
                    selectedArrivalAirport = departureAirport
                    selectedDepartureAirport = nil
                    Task {
                        await fetchScheduleResults(departureId: nil, arrivalId: departureAirport.iataCode)
                    }
                } else if let arrivalAirport = selectedArrivalAirport {
                    // Already have arrival airport, just fetch arrivals
                    Task {
                        await fetchScheduleResults(departureId: nil, arrivalId: arrivalAirport.iataCode)
                    }
                } else if let lastAirportData = lastSearchedAirportData {
                    // ADDED: Use last searched airport for arrivals
                    Task {
                        await fetchScheduleResults(departureId: nil, arrivalId: lastAirportData.iataCode)
                    }
                } else {
                    // No airport selected, clear results
                    clearScheduleResults()
                }
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
        HStack(alignment: .top, spacing: 12) {
            Image("FlightTrackLogo")
            
            VStack(alignment: .leading, spacing: 2) {
                Text(flight.flightNumber)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                
                Text(flight.airline)
                    .font(.system(size: 14))
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .center, spacing: 2) {
                Text(flight.destination)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                
                Text(flight.destinationName)
                    .font(.system(size: 12))
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
            }
            
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
    
    // MARK: - Helper Methods
    
    // FIXED: Enhanced openTrackLocationSheet method with proper state management
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
            // This is a simplified approach - in a real app you might want to specify this
            if trackedDepartureAirport == nil {
                trackedDepartureAirport = airport
            } else {
                trackedArrivalAirport = airport
                // Check if we have all required data for tracked search
                await checkTrackedSearchReady()
            }
            
        case .scheduledDeparture:
            selectedDepartureAirport = airport
            // Clear arrival airport since we're focusing on departures
            selectedArrivalAirport = nil
            // ADDED: Save as last searched airport
            saveLastSearchedAirport(airport, searchType: .departure)
            // Make API call for scheduled departures
            await fetchScheduleResults(departureId: airport.iataCode, arrivalId: nil)
            
        case .scheduledArrival:
            selectedArrivalAirport = airport
            // Clear departure airport since we're focusing on arrivals
            selectedDepartureAirport = nil
            // ADDED: Save as last searched airport
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
    
    private func convertDateToAPIFormat(_ dateSelection: String) -> String {
        // Convert date selection to YYYYMMDD format
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
        // Return current date in YYYYMMDD format
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: Date())
    }
    
    // For tracked flights, use the selected date instead
    private func getSelectedDateForAPI() -> String {
        guard let selectedDate = trackedSelectedDate else {
            return getCurrentDateForAPI()
        }
        return convertDateToAPIFormat(selectedDate)
    }
    
    @MainActor
    private func fetchScheduleResults(departureId: String?, arrivalId: String?, date: String? = nil) async {
        isLoadingSchedules = true
        scheduleError = nil
        // Clear displaying recent results when making new search
        displayingRecentResults = []
        
        do {
            let response = try await networkManager.searchSchedules(
                departureId: departureId,
                arrivalId: arrivalId,
                date: date
            )
            
            // Convert ScheduleResult to FlightInfo for display
            scheduleResults = response.results.map { scheduleResult in
                convertScheduleToFlightInfo(scheduleResult, departureAirport: response.departureAirport, arrivalAirport: response.arrivalAirport)
            }
            
            // ADDED: Save successful search results locally (simplified)
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
    
    // ADDED: Save current search locally (simplified version)
    private func saveCurrentSearchLocally() {
        // Simple local storage - just save the current results
        displayingRecentResults = scheduleResults
        hasRecentSearch = true
        
        // Save to UserDefaults for persistence
        if let data = try? JSONEncoder().encode(scheduleResults.map { flight in
            [
                "flightNumber": flight.flightNumber,
                "airline": flight.airline,
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
    
    // ADDED: Load recent search data on app launch
    private func loadRecentSearchData() {
        // Load from UserDefaults
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
                      let delay = dict["delay"] else { return nil }
                
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
    
    // ADDED: Save last searched airport
    private func saveLastSearchedAirport(_ airport: FlightTrackAirport, searchType: FlightSearchType) {
        lastSearchType = searchType
        
        // Save to UserDefaults using Codable
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
    
    // ADDED: Load last searched airport
    private func loadLastSearchedAirport() {
        guard let data = UserDefaults.standard.data(forKey: "LastSearchedAirport"),
              let airportData = try? JSONDecoder().decode(LastSearchedAirportData.self, from: data) else {
            return
        }
        
        // Store the airport data for display and usage
        lastSearchedAirportData = airportData
        lastSearchType = airportData.searchType == "departure" ? .departure : .arrival
        
        // Auto-populate and fetch results based on current filter
        if selectedFlightType == 0 && lastSearchType == .departure {
            // Current filter is departures and last search was departure
            Task {
                await fetchScheduleResults(departureId: airportData.iataCode, arrivalId: nil)
            }
        } else if selectedFlightType == 1 && lastSearchType == .arrival {
            // Current filter is arrivals and last search was arrival
            Task {
                await fetchScheduleResults(departureId: nil, arrivalId: airportData.iataCode)
            }
        }
    }
    
    private func convertScheduleToFlightInfo(_ schedule: ScheduleResult, departureAirport: FlightTrackAirport?, arrivalAirport: FlightTrackAirport?) -> FlightInfo {
        // Format times
        let departureTime = formatTime(schedule.departureTime)
        let arrivalTime = formatTime(schedule.arrivalTime)
        
        // Determine destination based on search type
        let destination: String
        let destinationName: String
        
        if currentSheetSource == .scheduledDeparture {
            // Showing departures, so destination is where flights are going
            destination = schedule.airport.iataCode
            destinationName = schedule.airport.city
        } else {
            // Showing arrivals, so destination is where flights are coming from
            if let depAirport = departureAirport {
                destination = depAirport.iataCode
                destinationName = depAirport.city
            } else {
                destination = schedule.airport.iataCode
                destinationName = schedule.airport.city
            }
        }
        
        // Convert status to FlightStatus
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
            destination: destination,
            destinationName: destinationName,
            time: arrivalTime,
            scheduledTime: departureTime,
            status: flightStatus,
            delay: "", // No delay info in this API response
            airlineColor: .blue // Default color
        )
    }
    
    private func formatTime(_ timeString: String) -> String {
        // Convert "2025-06-18T02:20:00" to "02:20"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        if let date = formatter.date(from: timeString) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            return timeFormatter.string(from: date)
        }
        
        return timeString
    }
}

// MARK: - Supporting Models and Extensions
struct LastSearchedAirportData: Codable {
    let iataCode: String
    let name: String
    let city: String
    let country: String
    let searchType: String
}

struct FlightInfo {
    let flightNumber: String
    let airline: String
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

#Preview {
    FlightTrackerScreen()
}
