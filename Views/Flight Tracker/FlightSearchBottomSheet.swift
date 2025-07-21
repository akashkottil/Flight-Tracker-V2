// Enhanced FlightSearchBottomSheet.swift - Complete optimized version with loading states
import SwiftUI

struct trackLocationSheet: View {
    @Binding var isPresented: Bool
    let source: SheetSource
    let searchType: FlightSearchType?
    let onLocationSelected: (FlightTrackAirport) -> Void
    let onDateSelected: ((String) -> Void)?
    
    // ADDED: New completion handlers for tracked tab
    let onFlightNumberEntered: ((String) -> Void)?
    let onSearchCompleted: ((TrackedSearchType, String?, FlightTrackAirport?, FlightTrackAirport?, String?) -> Void)?
    
    // ADDED: Calendar integration callback
    let onCustomDateSelected: ((Date) -> Void)?
    
    // OPTIMIZED: Use shared search manager instead of viewModel
    @StateObject private var searchManager = SearchManager.shared
    @State private var searchText = ""
    @State private var selectedAirport: FlightTrackAirport?
    
    // ADDED: Track completion state for tracked tab
    @State private var trackedDepartureAirport: FlightTrackAirport?
    @State private var trackedArrivalAirport: FlightTrackAirport?
    @State private var trackedFlightNumber: String = ""
    @State private var trackedSelectedDate: String?
    @State private var trackedSearchType: TrackedSearchType?
    
    // ADDED: Progressive display states
    @State private var showDateForAirportSearch: Bool = false
    
    // ADDED: Calendar integration states
    @State private var showingTrackCalendar = false
    @State private var selectedCustomDate: Date?
    
    // ADDED: Local state variables for compatibility
    @State private var selectedSearchType: TrackedSearchType?
    @State private var arrivalAirportText: String = ""
    @State private var arrivalAirports: [FlightTrackAirport] = []
    @State private var selectedDate: String?
    
    // NEW: Loading and error states
    @State private var isFlightDetailLoading = false
    @State private var flightDetailError: String?
    @State private var hasPerformedOriginSearch = false
    @State private var hasPerformedDestinationSearch = false
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Top Bar
            HStack {
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                        .padding(10)
                        .fontWeight(.bold)
                }
                Spacer()
                Text(getSheetTitle())
                    .bold()
                    .font(.title2)
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }
            .padding()
            
            // Content based on source
            ScrollView {
                VStack(spacing: 16) {
                    if source == .trackedTab {
                        trackedTabContent()
                    } else {
                        scheduledTabContent()
                    }
                }
                .padding(.horizontal)
                .padding(.top)
            }
            
            Spacer()
        }
        .background(Color.white)
        .onAppear {
            // Search manager automatically handles mixed search for tracked tab
        }
        .sheet(isPresented: $showingTrackCalendar) {
            TrackCalendar(
                isPresented: $showingTrackCalendar,
                onDateSelected: { selectedCustomDateFromCalendar in
                    selectedCustomDate = selectedCustomDateFromCalendar
                    // Handle the date selection
                    if source == .trackedTab {
                        trackedSelectedDate = "custom"
                        print("📅 Selected custom date for tracked: \(selectedCustomDateFromCalendar)")
                    } else {
                        selectedDate = "custom"
                        onDateSelected?("custom")
                    }
                    // Notify parent about custom date
                    onCustomDateSelected?(selectedCustomDateFromCalendar)
                }
            )
        }
    }
    
    // MARK: - Enhanced Tracked Tab Content
    
    @ViewBuilder
    private func trackedTabContent() -> some View {
        VStack(spacing: 20) {
            // Primary search field
            primarySearchField()
            
            // Show search results if available
            // OPTIMIZED: Use search manager state
            if searchManager.isLoading {
                loadingView()
            } else if !searchText.isEmpty && (!searchManager.searchResults.airports.isEmpty || !searchManager.searchResults.airlines.isEmpty) {
                searchResultsView()
            } else if let error = searchManager.errorMessage {
                errorView(error)
            } else if searchText.isEmpty {
                defaultTrackedContent()
            }
            
            // Show additional fields based on selection - MODIFIED for progressive display
            if let searchType = selectedSearchType {
                additionalFieldsView(for: searchType)
            }
            
            // ADDED: Auto-check completion when all fields are filled
            if source == .trackedTab {
                let _ = checkTrackedCompletion()
            }
        }
    }
    
    // ADDED: Check if tracked search is complete and trigger API call
    private func checkTrackedCompletion() {
        // Check if we have all required data
        guard let searchType = trackedSearchType,
              let selectedDate = trackedSelectedDate else {
            return
        }
        
        var isComplete = false
        
        if searchType == .flight {
            // For flight search: need flight number
            isComplete = !trackedFlightNumber.isEmpty
        } else if searchType == .airport {
            // For airport search: need at least departure airport
            isComplete = trackedDepartureAirport != nil
        }
        
        if isComplete {
            // Trigger the completion handler
            handleTrackedSearchCompleted(
                searchType: searchType,
                flightNumber: searchType == .flight ? trackedFlightNumber : nil,
                departureAirport: trackedDepartureAirport,
                arrivalAirport: trackedArrivalAirport,
                selectedDate: selectedDate
            )
        }
    }
    
    // NEW: Enhanced handleTrackedSearchCompleted with loading states
    private func handleTrackedSearchCompleted(
        searchType: TrackedSearchType,
        flightNumber: String?,
        departureAirport: FlightTrackAirport?,
        arrivalAirport: FlightTrackAirport?,
        selectedDate: String?
    ) {
        
        guard let selectedDate = selectedDate else {
            print("❌ No date selected")
            return
        }
        
        let apiDate = convertDateToAPIFormat(selectedDate)
        
        // Handle flight number concatenation for tracked search
        var finalFlightNumber: String?
        if searchType == .flight {
            finalFlightNumber = buildCompleteFlightNumber(
                selectedAirline: getSelectedAirlineCode(),
                enteredFlightNumber: flightNumber
            )
        }
        
        // NEW: Start loading state
        withAnimation(.easeInOut(duration: 0.3)) {
            isFlightDetailLoading = true
            flightDetailError = nil
        }
        
        Task {
            await performTrackedSearchWithLoadingStates(
                searchType: searchType,
                flightNumber: finalFlightNumber,
                departureAirport: departureAirport,
                arrivalAirport: arrivalAirport,
                date: apiDate
            )
        }
    }
    
    // NEW: Enhanced performTrackedSearch with loading states
    @MainActor
    private func performTrackedSearchWithLoadingStates(
        searchType: TrackedSearchType,
        flightNumber: String?,
        departureAirport: FlightTrackAirport?,
        arrivalAirport: FlightTrackAirport?,
        date: String
    ) async {
        
        do {
            if searchType == .flight, let flightNumber = flightNumber {
                print("🔍 Calling flight detail API for: \(flightNumber), date: \(date)")
                
                // Use existing method with concatenated flight number
                let response = try await FlightTrackNetworkManager.shared.fetchFlightDetail(
                    flightNumber: flightNumber,
                    date: date
                )
                
                // Success - hide loading and navigate
                withAnimation(.easeInOut(duration: 0.3)) {
                    isFlightDetailLoading = false
                    flightDetailError = nil
                }
                
                // Small delay to show success state before navigation
                try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                
                // Navigate to flight detail screen
                onSearchCompleted?(searchType, flightNumber, departureAirport, arrivalAirport, date)
                
            } else if searchType == .airport {
                // Handle airport search (existing logic)
                let departureId = departureAirport?.iataCode
                let arrivalId = arrivalAirport?.iataCode
                
                print("🔍 Calling schedules API - dep: \(departureId ?? "nil"), arr: \(arrivalId ?? "nil"), date: \(date)")
                let response = try await FlightTrackNetworkManager.shared.searchSchedules(
                    departureId: departureId,
                    arrivalId: arrivalId,
                    date: date
                )
                
                // Success - hide loading and navigate
                withAnimation(.easeInOut(duration: 0.3)) {
                    isFlightDetailLoading = false
                    flightDetailError = nil
                }
                
                // Navigate to schedule results
                onSearchCompleted?(searchType, flightNumber, departureAirport, arrivalAirport, date)
            }
            
        } catch {
            // Error - show error state
            withAnimation(.easeInOut(duration: 0.3)) {
                isFlightDetailLoading = false
                flightDetailError = error.localizedDescription
            }
            
            print("❌ Tracked search error: \(error)")
        }
    }
    
    // NEW: Build complete flight number from separate components
    private func buildCompleteFlightNumber(
        selectedAirline: String?,
        enteredFlightNumber: String?
    ) -> String? {
        
        guard let flightNumber = enteredFlightNumber?.trimmingCharacters(in: .whitespacesAndNewlines),
              !flightNumber.isEmpty else {
            return nil
        }
        
        // If user entered just numbers (like "503")
        if flightNumber.allSatisfy({ $0.isNumber }) {
            if let airline = selectedAirline?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
               !airline.isEmpty {
                let combinedFlightNumber = "\(airline)\(flightNumber)"
                print("✅ CONCATENATED: '\(airline)' + '\(flightNumber)' = '\(combinedFlightNumber)'")
                return combinedFlightNumber
            }
        }
        
        // If user entered complete flight number (like "6E503"), use as-is
        print("✅ USING AS-IS: '\(flightNumber)'")
        return flightNumber
    }
    
    // NEW: Get selected airline code from search text
    private func getSelectedAirlineCode() -> String? {
        // Extract airline code from the searchText if an airline was selected
        if let selectedType = selectedSearchType, selectedType == .flight {
            // searchText format would be "6E - IndiGo" after airline selection
            let components = searchText.components(separatedBy: " - ")
            if let firstComponent = components.first?.trimmingCharacters(in: .whitespacesAndNewlines),
               firstComponent.count >= 2 && firstComponent.count <= 3 {
                return firstComponent.uppercased()
            }
        }
        return nil
    }
    
    // NEW: Retry method
    private func retryFlightSearch(searchType: TrackedSearchType, selectedDate: String) {
        let apiDate = convertDateToAPIFormat(selectedDate)
        
        if searchType == .flight {
            let finalFlightNumber = buildCompleteFlightNumber(
                selectedAirline: getSelectedAirlineCode(),
                enteredFlightNumber: trackedFlightNumber
            )
            
            Task {
                await performTrackedSearchWithLoadingStates(
                    searchType: searchType,
                    flightNumber: finalFlightNumber,
                    departureAirport: trackedDepartureAirport,
                    arrivalAirport: trackedArrivalAirport,
                    date: apiDate
                )
            }
        }
    }
    
    private func primarySearchField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Enter flight or airport", text: $searchText)
                    .padding()
                    .onChange(of: searchText) { newValue in
                        // OPTIMIZED: Use debounced search
                        searchManager.performSearch(
                            query: newValue,
                            shouldPerformMixed: source == .trackedTab
                        )
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        searchManager.clearResults()
                        if source == .trackedTab {
                            resetTrackedData()
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .padding(.trailing)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.orange, lineWidth: 1)
            )
        }
    }
    
    private func searchResultsView() -> some View {
        VStack(spacing: 12) {
            // Airlines results
            if !searchManager.searchResults.airlines.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Airlines")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    // OPTIMIZED: Use LazyVStack for better performance
                    LazyVStack(spacing: 8) {
                        ForEach(searchManager.searchResults.airlines.prefix(3)) { airline in
                            OptimizedAirlineRowView(airline: airline) {
                                if source == .trackedTab {
                                    selectAirlineForTracked(airline)
                                }
                            }
                        }
                    }
                }
            }
            
            // Airports results
            if !searchManager.searchResults.airports.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Airports")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    // OPTIMIZED: Use LazyVStack for better performance
                    LazyVStack(spacing: 8) {
                        ForEach(searchManager.searchResults.airports.prefix(3)) { airport in
                            OptimizedAirportRowView(airport: airport) {
                                if source == .trackedTab {
                                    selectAirportForTracked(airport)
                                } else {
                                    selectAirport(airport)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func selectAirlineForTracked(_ airline: FlightTrackAirline) {
        trackedSearchType = .flight
        selectedSearchType = .flight
        let airlineCode = airline.iataCode ?? airline.icaoCode ?? "??"
        searchText = "\(airlineCode) - \(airline.name)"
        searchManager.clearResults()
        print("✈️ Selected airline for tracked: \(airlineCode)")
    }

    private func selectAirportForTracked(_ airport: FlightTrackAirport) {
        trackedSearchType = .airport
        selectedSearchType = .airport
        
        if trackedDepartureAirport == nil {
            trackedDepartureAirport = airport
            searchText = "\(airport.iataCode) - \(airport.city)"
            searchManager.clearResults()
            print("🛫 Selected departure airport for tracked: \(airport.iataCode)")
        } else if trackedArrivalAirport == nil {
            trackedArrivalAirport = airport
            print("🛬 Selected arrival airport for tracked: \(airport.iataCode)")
        }
    }
    
    private func resetTrackedData() {
        trackedDepartureAirport = nil
        trackedArrivalAirport = nil
        trackedFlightNumber = ""
        trackedSelectedDate = nil
        trackedSearchType = nil
        selectedSearchType = nil
        showDateForAirportSearch = false
        selectedCustomDate = nil
        arrivalAirportText = ""
        arrivalAirports = []
        selectedDate = nil
        isFlightDetailLoading = false
        flightDetailError = nil
        searchManager.clearResults()
    }
    
    // MODIFIED: Progressive display logic for additional fields
    private func additionalFieldsView(for searchType: TrackedSearchType) -> some View {
        VStack(spacing: 16) {
            // Always show the second input field when search type is determined
            if searchType == .flight {
                flightNumberField()
            } else if searchType == .airport {
                arrivalAirportField()
            }
            
            // MODIFIED: Show date selection only when second input is complete
            if shouldShowDateSelection(for: searchType) {
                dateSelectionView()
            }
        }
    }
    
    // ADDED: Logic to determine when to show date selection
    private func shouldShowDateSelection(for searchType: TrackedSearchType) -> Bool {
        switch searchType {
        case .flight:
            // For flight search: show date when flight number is entered
            return !trackedFlightNumber.isEmpty
        case .airport:
            // For airport search: show date when arrival airport is selected OR user chooses to continue
            return trackedArrivalAirport != nil || showDateForAirportSearch
        }
    }
    
    private func flightNumberField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Enter flight number (e.g., 6E 123)", text: $trackedFlightNumber)
                    .padding()
                    .onChange(of: trackedFlightNumber) { newValue in
                        // ADDED: Notify parent about flight number entry
                        onFlightNumberEntered?(newValue)
                    }
                
                if !trackedFlightNumber.isEmpty {
                    Button(action: {
                        trackedFlightNumber = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .padding(.trailing)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.orange, lineWidth: 1)
            )
        }
    }
    
    private func arrivalAirportField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Enter arrival airport", text: $arrivalAirportText)
                    .padding()
                    .onChange(of: arrivalAirportText) { newValue in
                        // Search for arrival airports
                        if newValue.count >= 2 {
                            Task {
                                do {
                                    let response = try await FlightTrackNetworkManager.shared.searchAirports(query: newValue)
                                    await MainActor.run {
                                        arrivalAirports = response.results
                                    }
                                } catch {
                                    print("Arrival airport search failed: \(error)")
                                }
                            }
                        } else {
                            arrivalAirports = []
                        }
                    }
                
                if !arrivalAirportText.isEmpty {
                    Button(action: {
                        arrivalAirportText = ""
                        arrivalAirports = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .padding(.trailing)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.orange, lineWidth: 1)
            )
            
            // Show arrival airport results
            if !arrivalAirports.isEmpty {
                VStack(spacing: 8) {
                    ForEach(arrivalAirports.prefix(3)) { airport in
                        airportRowView(airport)
                            .onTapGesture {
                                // ADDED: Set as arrival airport for tracked tab
                                if source == .trackedTab {
                                    trackedArrivalAirport = airport
                                    arrivalAirportText = "\(airport.iataCode) - \(airport.city)"
                                    arrivalAirports = []
                                    print("🛬 Selected arrival airport: \(airport.iataCode)")
                                }
                            }
                    }
                }
            }
        }
    }
    
    // UPDATED: Date selection view with loading and error states
    private func dateSelectionView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Date")
                .font(.system(size: 14))
                .fontWeight(.bold)
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    dateCard("Yesterday", "16 Jun, Mon", "yesterday")
                    dateCard("Today", "17 Jun, Tue", "today")
                }
                
                HStack(spacing: 12) {
                    dateCard("Tomorrow", "18 Jun, Wed", "tomorrow")
                    customDateCard() // NEW: Calendar integration
                }
            }
            .frame(maxWidth: .infinity)
            
            // NEW: Loading and Error States
            if isFlightDetailLoading {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.orange))
                            .scaleEffect(0.8)
                        
                        Text("Fetching flight details...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.orange)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .transition(.opacity.combined(with: .scale))
                    Spacer()
                }
            }
            
            if let error = flightDetailError {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                        
                        Text("Unable to find the flight details!")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                        
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        Button("Try Again") {
                            flightDetailError = nil
                            if let searchType = trackedSearchType,
                               let selectedDate = trackedSelectedDate {
                                retryFlightSearch(searchType: searchType, selectedDate: selectedDate)
                            }
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                    .transition(.opacity.combined(with: .scale))
                    Spacer()
                }
            }
        }
    }
    
    // ADDED: Custom date card with calendar integration
    private func customDateCard() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Custom Date")
                .font(.system(size: 14, weight: .medium))
            
            if let customDate = selectedCustomDate {
                Text(formatCustomDate(customDate))
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
            } else {
                Text("Pick another date")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(getSelectedDate() == "custom" ? Color.orange : Color.gray.opacity(0.5), lineWidth: getSelectedDate() == "custom" ? 2 : 1)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(getSelectedDate() == "custom" ? Color.orange.opacity(0.1) : Color.clear)
                )
        )
        .opacity(isFlightDetailLoading ? 0.6 : 1.0)
        .onTapGesture {
            if !isFlightDetailLoading {
                showingTrackCalendar = true
            }
        }
    }
    
    // ADDED: Format custom date helper
    private func formatCustomDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM, EEE"
        return formatter.string(from: date)
    }
    
    // UPDATED: Date card with loading state handling
    private func dateCard(_ title: String, _ date: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
            Text(date)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(getSelectedDate() == value ? Color.orange : Color.gray.opacity(0.5), lineWidth: getSelectedDate() == value ? 2 : 1)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(getSelectedDate() == value ? Color.orange.opacity(0.1) : Color.clear)
                )
        )
        .opacity(isFlightDetailLoading ? 0.6 : 1.0)
        .onTapGesture {
            // Disable interaction during loading
            if !isFlightDetailLoading {
                if source == .trackedTab {
                    trackedSelectedDate = value
                    print("📅 Selected date for tracked: \(value)")
                } else {
                    selectedDate = value
                    onDateSelected?(value)
                }
            }
        }
    }
    
    private func getSelectedDate() -> String? {
        if source == .trackedTab {
            return trackedSelectedDate
        } else {
            return selectedDate
        }
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
    
    // MARK: - Error View
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24))
                .foregroundColor(.orange)
            
            Text("Search Error")
                .font(.system(size: 16, weight: .semibold))
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
    
    // MARK: - Keep all existing methods unchanged...
    
    private func airlineRowView(_ airline: FlightTrackAirline) -> some View {
        HStack(spacing: 12) {
            // UPDATED: Use actual airline logo instead of text
            AirlineLogoView(
                iataCode: airline.iataCode, // Use API response IATA code
                fallbackImage: "FlightTrackLogo",
                size: 50
            )
            .background(Color.white)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(airline.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(airline.country)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
//            Image(systemName: "airplane")
//                .foregroundColor(.gray)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func airportRowView(_ airport: FlightTrackAirport) -> some View {
        HStack(spacing: 12) {
            Text(airport.iataCode)
                .font(.system(size: 14, weight: .semibold))
                .padding(8)
                .frame(width: 50, height: 50)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(airport.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                Text("\(airport.city), \(airport.country)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
//            Image(systemName: "location")
//                .foregroundColor(.gray)
        }
//        .padding(.horizontal)
        .padding(.vertical, 12)
//        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Scheduled Tab Content
    
    private func scheduledTabContent() -> some View {
        VStack(spacing: 16) {
            scheduledAirportSearchField()
            
            if !searchManager.searchResults.airports.isEmpty {
                scheduledAirportResultsList()
            } else if searchManager.isLoading {
                loadingView()
            }
        }
    }
    
    private func scheduledAirportSearchField() -> some View {
        HStack {
            TextField(getAirportSearchPlaceholder(), text: $searchText)
                .padding()
                .onChange(of: searchText) { newValue in
                    searchManager.performSearch(query: newValue, shouldPerformMixed: false)
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    searchManager.clearResults()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .padding(.trailing)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.orange, lineWidth: 1)
        )
    }
    
    private func scheduledAirportResultsList() -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(searchManager.searchResults.airports) { airport in
                    scheduledAirportRowView(airport)
                        .onTapGesture {
                            selectAirport(airport)
                        }
                    
                    if airport.id != searchManager.searchResults.airports.last?.id {
                        Divider()
                    }
                }
            }
        }
        .frame(maxHeight: 300)
    }
    
    private func scheduledAirportRowView(_ airport: FlightTrackAirport) -> some View {
        HStack(spacing: 12) {
            Text(airport.iataCode)
                .font(.system(size: 16, weight: .bold))
                .padding(8)
                .frame(width: 50, height: 50)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(airport.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                Text("\(airport.city), \(airport.country)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    
    private func defaultTrackedContent() -> some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Popular Airlines")
                        .font(.system(size: 18))
                        .fontWeight(.bold)
                    Spacer()
                }
                
                VStack(spacing: 8) {
//                    popularAirlineRow("vistara", "Vistara", "India")
                    popularAirlineRow("SG", "Spice Jet", "India")
                    popularAirlineRow("6E", "Indigo", "India")
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Popular Airports")
                        .font(.system(size: 18))
                        .fontWeight(.bold)
                    Spacer()
                }
                
                VStack(spacing: 8) {
                    popularAirportRow("COK", "Kochi International Airport")
                    popularAirportRow("DEL", "Indira Gandhi International Airport")
                    popularAirportRow("BOM", "Chhatrapati Shivaji Maharaj International Airport")
                }
            }
        }
    }
    
    private func popularAirlineRow(_ code: String, _ name: String, _ country: String) -> some View {
        HStack(spacing: 12) {
            Image(code)
                .font(.system(size: 14, weight: .bold))
                
                .frame(width: 50, height: 50)
                
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                Text(country)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .onTapGesture {
            searchText = code
        }
    }
    
    private func popularAirportRow(_ code: String, _ name: String) -> some View {
        HStack(spacing: 12) {
            Text(code)
                .font(.system(size: 14, weight: .semibold))
                .padding(8)
                .frame(width: 50, height: 50)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            Text(name)
                .font(.system(size: 14, weight: .semibold))
            
            Spacer()
        }
        
        .onTapGesture {
            searchText = code
        }
    }
    
    private func loadingView() -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Searching...")
                .font(.system(size: 16))
                .foregroundColor(.gray)
        }
        .frame(height: 100)
    }
    
    private func getSheetTitle() -> String {
        switch source {
        case .trackedTab:
            return "Track Flight"
        case .scheduledDeparture:
            return "Select Departure Airport"
        case .scheduledArrival:
            return "Select Arrival Airport"
        }
    }
    
    private func getAirportSearchPlaceholder() -> String {
        switch source {
        case .trackedTab:
            return "Enter flight or airport"
        case .scheduledDeparture:
            return "Enter departure airport"
        case .scheduledArrival:
            return "Enter arrival airport"
        }
    }
    
    private func selectAirport(_ airport: FlightTrackAirport) {
        selectedAirport = airport
        onLocationSelected(airport)
        isPresented = false
    }
}

// MARK: - Optimized Row Views
struct OptimizedAirlineRowView: View {
    let airline: FlightTrackAirline
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                AirlineLogoView(
                    iataCode: airline.iataCode,
                    fallbackImage: "FlightTrackLogo",
                    size: 40
                )
                .background(Color.white)
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(airline.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .lineLimit(1)
                    
                    Text(airline.country)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
//                Image(systemName: "airplane")
//                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
//            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct OptimizedAirportRowView: View {
    let airport: FlightTrackAirport
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(airport.iataCode)
                    .font(.system(size: 14, weight: .semibold))
                    .padding(8)
                    .frame(width: 50, height: 50)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(airport.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .lineLimit(2)
                    
                    Text("\(airport.city), \(airport.country)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
//                Image(systemName: "location")
//                    .foregroundColor(.gray)
            }
//            .padding(.horizontal)
            .padding(.vertical, 12)
//            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Convenience Initializers
extension trackLocationSheet {
    
    // UPDATED: Convenience initializer for preview with calendar callback
    init(forPreview: Bool = true) {
        self._isPresented = .constant(true)
        self.source = .trackedTab
        self.searchType = nil
        self.onLocationSelected = { _ in }
        self.onDateSelected = nil
        self.onFlightNumberEntered = nil
        self.onSearchCompleted = nil
        self.onCustomDateSelected = nil // ADDED: Calendar callback
    }
}

#Preview {
    trackLocationSheet(forPreview: true)
}
