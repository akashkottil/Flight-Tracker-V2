// Views/Flight Tracker/FlightSearchBottomSheet.swift
import SwiftUI

struct trackLocationSheet: View {
    @Binding var isPresented: Bool
    let source: SheetSource
    let searchType: FlightSearchType?
    let onLocationSelected: (FlightTrackAirport) -> Void
    let onDateSelected: ((String) -> Void)?
    
    @StateObject private var viewModel = AirportSearchViewModel()
    @State private var selectedAirport: FlightTrackAirport?
    
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
            // Set search type based on source
            viewModel.shouldPerformMixedSearch = (source == .trackedTab)
        }
    }
    
    // MARK: - Tracked Tab Content
    
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
                // Show default content when no search
                defaultTrackedContent()
            }
            
            // Show additional fields based on selection
            if let searchType = viewModel.selectedSearchType {
                additionalFieldsView(for: searchType)
            }
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
                                viewModel.selectAirline(airline)
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
                                viewModel.selectAirport(airport)
                            }
                    }
                }
            }
        }
    }
    
    private func airlineRowView(_ airline: FlightTrackAirline) -> some View {
        HStack(spacing: 12) {
            // Airline Code - safely unwrap iataCode
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
            // Airport Code
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
                TextField("Enter flight number (e.g., 6E 123)", text: $viewModel.flightNumber)
                    .padding()
                
                if !viewModel.flightNumber.isEmpty {
                    Button(action: {
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
            Text("Arrival Airport")
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
                                viewModel.selectArrivalAirport(airport)
                            }
                    }
                }
            }
        }
    }
    
    private func defaultTrackedContent() -> some View {
        VStack(spacing: 24) {
            // Popular Airlines
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
            
            // Popular Airports
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
    
    // MARK: - Scheduled Tab Content (existing functionality)
    
    private func scheduledTabContent() -> some View {
        VStack(spacing: 16) {
            // Airport search field for scheduled tabs
            scheduledAirportSearchField()
            
            // Airport Search Results
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
            // Airport Code
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
    
    // MARK: - Common Components
    
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
                .stroke(viewModel.selectedDate == value ? Color.orange : Color.gray.opacity(0.5), lineWidth: viewModel.selectedDate == value ? 2 : 1)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.selectedDate == value ? Color.orange.opacity(0.1) : Color.clear)
                )
        )
        .onTapGesture {
            viewModel.selectedDate = value
            // Notify parent about date selection for tracked tab
            if source == .trackedTab {
                onDateSelected?(value)
            }
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
    
    // MARK: - Helper Methods
    
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

// MARK: - Default Initializer for Preview
extension trackLocationSheet {
    init() {
        self._isPresented = .constant(true)
        self.source = .trackedTab
        self.searchType = nil
        self.onLocationSelected = { _ in }
        self.onDateSelected = nil
    }
}

#Preview {
    trackLocationSheet()
}
