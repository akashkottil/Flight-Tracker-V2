// Enhanced FlightSearchBottomSheet.swift - Add tracked tab completion logic

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
    
    @StateObject private var viewModel = AirportSearchViewModel()
    @State private var selectedAirport: FlightTrackAirport?
    
    // ADDED: Track completion state for tracked tab
    @State private var trackedDepartureAirport: FlightTrackAirport?
    @State private var trackedArrivalAirport: FlightTrackAirport?
    @State private var trackedFlightNumber: String = ""
    @State private var trackedSelectedDate: String?
    @State private var trackedSearchType: TrackedSearchType?
    
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
            viewModel.shouldPerformMixedSearch = (source == .trackedTab)
        }
    }
    
    // MARK: - Enhanced Tracked Tab Content
    
    @ViewBuilder
    private func trackedTabContent() -> some View {
        VStack(spacing: 20) {
            // Primary search field
            primarySearchField()
            
            // Show search results if available
            if viewModel.isLoading {
                loadingView()
            } else if !viewModel.searchText.isEmpty && (!viewModel.airports.isEmpty || !viewModel.airlines.isEmpty) {
                searchResultsView()
            } else if viewModel.searchText.isEmpty {
                defaultTrackedContent()
            }
            
            // Show additional fields based on selection
            if let searchType = viewModel.selectedSearchType {
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
                TextField("Enter flight or airport", text: $viewModel.searchText)
                    .padding()
                
                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.clearSearch()
                        // ADDED: Clear tracked data when search is cleared
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
            
            if !viewModel.searchText.isEmpty {
                Text("Search results for \"\(viewModel.searchText)\"")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }
        }
    }
    
    private func searchResultsView() -> some View {
        VStack(spacing: 12) {
            // Airlines results (filter out airlines without iata_code)
            let validAirlines = viewModel.airlines.filter { $0.iataCode != nil }
            if !validAirlines.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Airlines")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    ForEach(validAirlines.prefix(3)) { airline in
                        airlineRowView(airline)
                            .onTapGesture {
                                // ADDED: Enhanced airline selection for tracked tab
                                if source == .trackedTab {
                                    selectAirlineForTracked(airline)
                                } else {
                                    viewModel.selectAirline(airline)
                                }
                            }
                    }
                }
            }
            
            // Airports results
            if !viewModel.airports.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Airports")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    ForEach(viewModel.airports.prefix(3)) { airport in
                        airportRowView(airport)
                            .onTapGesture {
                                // ADDED: Enhanced airport selection for tracked tab
                                if source == .trackedTab {
                                    selectAirportForTracked(airport)
                                } else {
                                    viewModel.selectAirport(airport)
                                }
                            }
                    }
                }
            }
        }
    }
    
    // ADDED: Enhanced selection handlers for tracked tab
    private func selectAirlineForTracked(_ airline: FlightTrackAirline) {
        trackedSearchType = .flight
        viewModel.selectedSearchType = .flight
        let airlineCode = airline.iataCode ?? airline.icaoCode ?? "??"
        viewModel.searchText = "\(airlineCode) - \(airline.name)"
        print("✈️ Selected airline for tracked: \(airlineCode)")
    }
    
    private func selectAirportForTracked(_ airport: FlightTrackAirport) {
        trackedSearchType = .airport
        viewModel.selectedSearchType = .airport
        
        // Always set as departure airport first
        if trackedDepartureAirport == nil {
            trackedDepartureAirport = airport
            viewModel.searchText = "\(airport.iataCode) - \(airport.city)"
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
    }
    
    private func additionalFieldsView(for searchType: TrackedSearchType) -> some View {
        VStack(spacing: 16) {
            // Additional field based on search type
            if searchType == .flight {
                flightNumberField()
            } else if searchType == .airport {
                arrivalAirportField()
            }
            
            // Date selection (show for both types)
            dateSelectionView()
        }
    }
    
    private func flightNumberField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Flight Number")
                .font(.system(size: 16, weight: .semibold))
            
            HStack {
                TextField("Enter flight number (e.g., 6E 123)", text: $trackedFlightNumber)
                    .padding()
                    .onChange(of: trackedFlightNumber) { newValue in
                        // ADDED: Notify parent about flight number entry
                        onFlightNumberEntered?(newValue)
                        // Update viewModel as well
                        viewModel.flightNumber = newValue
                    }
                
                if !trackedFlightNumber.isEmpty {
                    Button(action: {
                        trackedFlightNumber = ""
                        viewModel.flightNumber = ""
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
            Text("Arrival Airport (Optional)")
                .font(.system(size: 16, weight: .semibold))
            
            HStack {
                TextField("Enter arrival airport", text: $viewModel.arrivalAirportText)
                    .padding()
                
                if !viewModel.arrivalAirportText.isEmpty {
                    Button(action: {
                        viewModel.arrivalAirportText = ""
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
            if !viewModel.arrivalAirports.isEmpty {
                VStack(spacing: 8) {
                    ForEach(viewModel.arrivalAirports.prefix(3)) { airport in
                        airportRowView(airport)
                            .onTapGesture {
                                // ADDED: Set as arrival airport for tracked tab
                                if source == .trackedTab {
                                    trackedArrivalAirport = airport
                                    viewModel.arrivalAirportText = "\(airport.iataCode) - \(airport.city)"
                                    viewModel.arrivalAirports = []
                                    print("🛬 Selected arrival airport: \(airport.iataCode)")
                                } else {
                                    viewModel.selectArrivalAirport(airport)
                                }
                            }
                    }
                }
            }
        }
    }
    
    private func dateSelectionView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Date")
                .font(.system(size: 18))
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    dateCard("Yesterday", "16 Jun, Mon", "yesterday")
                    dateCard("Today", "17 Jun, Tue", "today")
                }
                
                HStack(spacing: 12) {
                    dateCard("Tomorrow", "18 Jun, Wed", "tomorrow")
                    dateCard("Day After", "19 Jun, Thu", "dayafter")
                }
            }
        }
    }
    
    private func dateCard(_ title: String, _ date: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
            Text(date)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
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
                viewModel.selectedDate = value
                onDateSelected?(value)
            }
        }
    }
    
    private func getSelectedDate() -> String? {
        if source == .trackedTab {
            return trackedSelectedDate
        } else {
            return viewModel.selectedDate
        }
    }
    
    // MARK: - Keep all existing methods unchanged...
    
    private func airlineRowView(_ airline: FlightTrackAirline) -> some View {
        HStack(spacing: 12) {
            Text(airline.iataCode ?? "??")
                .font(.system(size: 16, weight: .bold))
                .padding(8)
                .frame(width: 50, height: 50)
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
    
    // ... (Keep all other existing methods exactly the same)
    
    private func scheduledTabContent() -> some View {
        VStack(spacing: 16) {
            scheduledAirportSearchField()
            
            if !viewModel.airports.isEmpty {
                scheduledAirportResultsList()
            } else if viewModel.isLoading {
                loadingView()
            }
        }
    }
    
    private func scheduledAirportSearchField() -> some View {
        HStack {
            TextField(getAirportSearchPlaceholder(), text: $viewModel.searchText)
                .padding()
            
            if !viewModel.searchText.isEmpty {
                Button(action: {
                    viewModel.clearSearch()
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
                ForEach(viewModel.airports) { airport in
                    scheduledAirportRowView(airport)
                        .onTapGesture {
                            selectAirport(airport)
                        }
                    
                    if airport.id != viewModel.airports.last?.id {
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
            viewModel.searchText = code
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
            viewModel.searchText = code
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

// MARK: - Convenience Initializers
extension trackLocationSheet {
    
    // Convenience initializer for preview
    init(forPreview: Bool = true) {
        self._isPresented = .constant(true)
        self.source = .trackedTab
        self.searchType = nil
        self.onLocationSelected = { _ in }
        self.onDateSelected = nil
        self.onFlightNumberEntered = nil
        self.onSearchCompleted = nil
    }
}

#Preview {
    trackLocationSheet(forPreview: true)
}
