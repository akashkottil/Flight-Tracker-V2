// Enhanced FlightSearchBottomSheet.swift - Complete optimized version
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
                        .background(Circle().fill(Color.gray.opacity(0.1)))
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
            onSearchCompleted?(
                searchType,
                searchType == .flight ? trackedFlightNumber : nil,
                trackedDepartureAirport,
                trackedArrivalAirport,
                selectedDate
            )
            
            // Close the sheet
            isPresented = false
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
    
    // UPDATED: Date selection view with calendar integration
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
        .onTapGesture {
            showingTrackCalendar = true
        }
    }
    
    // ADDED: Format custom date helper
    private func formatCustomDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM, EEE"
        return formatter.string(from: date)
    }
    
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
        .onTapGesture {
            // ADDED: Enhanced date selection for tracked tab
            if source == .trackedTab {
                trackedSelectedDate = value
                print("📅 Selected date for tracked: \(value)")
            } else {
                selectedDate = value
                onDateSelected?(value)
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
            .background(Color.green.opacity(0.1))
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
            
            Image(systemName: "airplane")
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func airportRowView(_ airport: FlightTrackAirport) -> some View {
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
            
            Image(systemName: "location")
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.05))
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
                    popularAirlineRow("6E", "IndiGo", "India")
                    popularAirlineRow("AI", "Air India", "India")
                    popularAirlineRow("SG", "SpiceJet", "India")
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
            Text(code)
                .font(.system(size: 14, weight: .bold))
                .padding(8)
                .frame(width: 50, height: 50)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                Text(country)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .onTapGesture {
            searchText = code
        }
    }
    
    private func popularAirportRow(_ code: String, _ name: String) -> some View {
        HStack(spacing: 12) {
            Text(code)
                .font(.system(size: 14, weight: .bold))
                .padding(8)
                .frame(width: 50, height: 50)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            
            Text(name)
                .font(.system(size: 14, weight: .semibold))
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
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
                .background(Color.green.opacity(0.1))
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
                
                Image(systemName: "airplane")
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.05))
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
                    .font(.system(size: 16, weight: .bold))
                    .padding(8)
                    .frame(width: 50, height: 50)
                    .background(Color.blue.opacity(0.1))
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
                
                Image(systemName: "location")
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.05))
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
