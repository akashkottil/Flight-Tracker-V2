import SwiftUI
import Combine

struct FALocationSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var originText = ""
    @State private var destinationText = ""
    
    // ADDED: Callback for when alert is created successfully
    let onAlertCreated: ((AlertResponse) -> Void)?
    
    // ADDED: Search functionality states
    @State private var originSearchResults: [FlightTrackAirport] = []
    @State private var destinationSearchResults: [FlightTrackAirport] = []
    @State private var isSearchingOrigin = false
    @State private var isSearchingDestination = false
    @State private var originSearchError: String?
    @State private var destinationSearchError: String?
    
    // ADDED: Selected airports
    @State private var selectedOriginAirport: FlightTrackAirport?
    @State private var selectedDestinationAirport: FlightTrackAirport?
    
    // ADDED: Active search field tracking
    @State private var activeSearchField: SearchField?
    
    // ADDED: Search tasks for cancellation
    @State private var originSearchTask: Task<Void, Never>?
    @State private var destinationSearchTask: Task<Void, Never>?
    
    // ADDED: Alert creation states
    @State private var isCreatingAlert = false
    @State private var alertCreationError: String?
    
    // ADDED: Network managers
    private let networkManager = FlightTrackNetworkManager.shared
    private let alertNetworkManager = AlertNetworkManager.shared
    
    // ADDED: Search debounce timer
    @State private var searchTimer: Timer?
    private let searchDebounceTime: TimeInterval = 0.3
    
    enum SearchField {
        case origin
        case destination
    }
    
    // ADDED: Initializers
    init(onAlertCreated: ((AlertResponse) -> Void)? = nil) {
        self.onAlertCreated = onAlertCreated
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar design
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                        .padding(10)
                        .background(Circle().fill(Color.gray.opacity(0.1)))
                }
                Spacer()
                Text("From Where??")
                    .bold()
                    .font(.title2)
                Spacer()
                // Empty view for balance
                Color.clear.frame(width: 40, height: 40)
            }
            .padding()
            
            // Origin search field
            VStack(spacing: 0) {
                HStack {
                    TextField("Origin City, Airport or place", text: $originText)
                        .padding()
                        .onChange(of: originText) { newValue in
                            handleOriginTextChange(newValue)
                        }
                        .onTapGesture {
                            activeSearchField = .origin
                            if !originText.isEmpty {
                                performOriginSearch(query: originText)
                            }
                        }
                    
                    if !originText.isEmpty {
                        Button(action: {
                            clearOriginSearch()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing)
                    }
                    
                    // ADDED: Loading indicator for origin
                    if isSearchingOrigin {
                        ProgressView()
                            .scaleEffect(0.8)
                            .padding(.trailing)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(originText.isEmpty ? Color.gray.opacity(0.8) : Color.orange, lineWidth: 1)
                )
                .padding(.horizontal)
                .padding(.top)
            }
            
            // Destination search field
            VStack(spacing: 0) {
                HStack {
                    TextField("Destination City, Airport or place", text: $destinationText)
                        .padding()
                        .onChange(of: destinationText) { newValue in
                            handleDestinationTextChange(newValue)
                        }
                        .onTapGesture {
                            activeSearchField = .destination
                            if !destinationText.isEmpty {
                                performDestinationSearch(query: destinationText)
                            }
                        }
                    
                    if !destinationText.isEmpty {
                        Button(action: {
                            clearDestinationSearch()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing)
                    }
                    
                    // ADDED: Loading indicator for destination
                    if isSearchingDestination {
                        ProgressView()
                            .scaleEffect(0.8)
                            .padding(.trailing)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(destinationText.isEmpty ? Color.gray.opacity(0.8) : Color.orange, lineWidth: 1)
                )
                .padding(.horizontal)
                .padding(.top)
            }
            
            // Use current location button design
            Button(action: {
                // TODO: Implement current location functionality
                print("Use current location tapped")
            }) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                    Text("Use Current Location")
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding()
                .padding(.vertical,10)
            }
            
            // Divider
            Divider()
                .padding(.horizontal)
            
            // ENHANCED: Alert creation status display
            if isCreatingAlert {
                VStack(spacing: 8) {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Creating flight alert...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    
                    if let origin = selectedOriginAirport, let destination = selectedDestinationAirport {
                        Text("\(origin.city) → \(destination.city)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
                .transition(.opacity.combined(with: .scale))
            }
            
            // ENHANCED: Alert creation error display
            if let error = alertCreationError {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("Alert Creation Failed")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.orange)
                    }
                    
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                    
                    Button("Try Again") {
                        alertCreationError = nil
                        if let origin = selectedOriginAirport, let destination = selectedDestinationAirport {
                            createAlert(origin: origin, destination: destination)
                        }
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
                .transition(.opacity.combined(with: .scale))
            }
            
            // ENHANCED: Dynamic search results list
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Show search results based on active field and search state
                    if activeSearchField == .origin {
                        searchResultsSection(
                            results: originSearchResults,
                            isSearching: isSearchingOrigin,
                            error: originSearchError,
                            searchText: originText,
                            onAirportSelected: { airport in
                                selectOriginAirport(airport)
                            }
                        )
                    } else if activeSearchField == .destination {
                        searchResultsSection(
                            results: destinationSearchResults,
                            isSearching: isSearchingDestination,
                            error: destinationSearchError,
                            searchText: destinationText,
                            onAirportSelected: { airport in
                                selectDestinationAirport(airport)
                            }
                        )
                    } else {
                        // Show default/popular airports when no active search
                        defaultAirportsSection()
                    }
                }
            }
        }
        .background(Color.white)
        .disabled(isCreatingAlert) // Disable interaction while creating alert
        .onDisappear {
            // ADDED: Cancel any ongoing searches when view disappears
            cancelAllSearches()
        }
    }
    
    // MARK: - Search Results Section
    
    @ViewBuilder
    private func searchResultsSection(
        results: [FlightTrackAirport],
        isSearching: Bool,
        error: String?,
        searchText: String,
        onAirportSelected: @escaping (FlightTrackAirport) -> Void
    ) -> some View {
        if isSearching {
            // Show loading state
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Searching airports...")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .frame(height: 100)
        } else if let error = error {
            // Show error state
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
                Text("Search Error")
                    .font(.system(size: 16, weight: .semibold))
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(height: 120)
        } else if results.isEmpty && !searchText.isEmpty {
            // Show no results state
            VStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
                Text("No airports found")
                    .font(.system(size: 16, weight: .semibold))
                Text("Try searching with a different airport name or code")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(height: 120)
        } else if !results.isEmpty {
            // Show search results
            ForEach(results) { airport in
                locationResultRow(
                    iataCode: airport.iataCode,
                    cityName: airport.city,
                    countryName: airport.country,
                    airportName: airport.name,
                    onTap: {
                        onAirportSelected(airport)
                    }
                )
            }
        }
    }
    
    // MARK: - ENHANCED Default Airports Section (Now Functional)
    
    @ViewBuilder
    private func defaultAirportsSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Popular Airports")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .padding(.top, 8)
                Spacer()
            }
            
            // MADE FUNCTIONAL: Popular airports with proper airport objects
            locationResultRow(
                iataCode: "COK",
                cityName: "Kochi",
                countryName: "India",
                airportName: "Cochin International Airport"
            ) {
                let airport = createPopularAirport(
                    iataCode: "COK",
                    name: "Cochin International Airport",
                    city: "Kochi",
                    country: "India"
                )
                handlePopularAirportSelection(airport)
            }
            
            locationResultRow(
                iataCode: "DXB",
                cityName: "Dubai",
                countryName: "United Arab Emirates",
                airportName: "Dubai International Airport"
            ) {
                let airport = createPopularAirport(
                    iataCode: "DXB",
                    name: "Dubai International Airport",
                    city: "Dubai",
                    country: "United Arab Emirates"
                )
                handlePopularAirportSelection(airport)
            }
            
            locationResultRow(
                iataCode: "JFK",
                cityName: "New York",
                countryName: "United States",
                airportName: "John F. Kennedy International Airport"
            ) {
                let airport = createPopularAirport(
                    iataCode: "JFK",
                    name: "John F. Kennedy International Airport",
                    city: "New York",
                    country: "United States"
                )
                handlePopularAirportSelection(airport)
            }
            
            locationResultRow(
                iataCode: "LAX",
                cityName: "Los Angeles",
                countryName: "United States",
                airportName: "Los Angeles International Airport"
            ) {
                let airport = createPopularAirport(
                    iataCode: "LAX",
                    name: "Los Angeles International Airport",
                    city: "Los Angeles",
                    country: "United States"
                )
                handlePopularAirportSelection(airport)
            }
            
            locationResultRow(
                iataCode: "LHR",
                cityName: "London",
                countryName: "United Kingdom",
                airportName: "Heathrow Airport"
            ) {
                let airport = createPopularAirport(
                    iataCode: "LHR",
                    name: "Heathrow Airport",
                    city: "London",
                    country: "United Kingdom"
                )
                handlePopularAirportSelection(airport)
            }
        }
    }
    
    // MARK: - Location Result Row (Enhanced)
    
    @ViewBuilder
    private func locationResultRow(
        iataCode: String,
        cityName: String,
        countryName: String,
        airportName: String,
        onTap: @escaping () -> Void = {}
    ) -> some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                HStack(spacing: 15) {
                    // Airport code badge
                    Text(iataCode)
                        .font(.system(size: 14, weight: .medium))
                        .padding(8)
                        .frame(width: 44, height: 44)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // Main location name
                        Text("\(cityName), \(countryName)")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        // Subtitle with airport name
                        Text(airportName)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 12)
                .padding(.horizontal)
            }
        }
        .contentShape(Rectangle())
        .disabled(isCreatingAlert) // Disable selection while creating alert
    }
    
    // MARK: - Search Functionality
    
    private func handleOriginTextChange(_ newValue: String) {
        activeSearchField = .origin
        
        // Cancel previous search timer
        searchTimer?.invalidate()
        
        // Clear previous results if text is empty
        if newValue.isEmpty {
            clearOriginSearch()
            return
        }
        
        // Start new debounced search
        searchTimer = Timer.scheduledTimer(withTimeInterval: searchDebounceTime, repeats: false) { _ in
            performOriginSearch(query: newValue)
        }
    }
    
    private func handleDestinationTextChange(_ newValue: String) {
        activeSearchField = .destination
        
        // Cancel previous search timer
        searchTimer?.invalidate()
        
        // Clear previous results if text is empty
        if newValue.isEmpty {
            clearDestinationSearch()
            return
        }
        
        // Start new debounced search
        searchTimer = Timer.scheduledTimer(withTimeInterval: searchDebounceTime, repeats: false) { _ in
            performDestinationSearch(query: newValue)
        }
    }
    
    private func performOriginSearch(query: String) {
        guard !query.isEmpty && query.count >= 2 else {
            originSearchResults = []
            return
        }
        
        // Cancel previous search
        originSearchTask?.cancel()
        
        isSearchingOrigin = true
        originSearchError = nil
        
        originSearchTask = Task {
            do {
                let response = try await networkManager.searchAirports(query: query)
                
                await MainActor.run {
                    if !Task.isCancelled {
                        self.originSearchResults = response.results
                        self.isSearchingOrigin = false
                        print("✅ Origin search completed: \(response.results.count) airports found for '\(query)'")
                    }
                }
            } catch {
                await MainActor.run {
                    if !Task.isCancelled {
                        self.originSearchError = error.localizedDescription
                        self.originSearchResults = []
                        self.isSearchingOrigin = false
                        print("❌ Origin search failed for '\(query)': \(error)")
                    }
                }
            }
        }
    }
    
    private func performDestinationSearch(query: String) {
        guard !query.isEmpty && query.count >= 2 else {
            destinationSearchResults = []
            return
        }
        
        // Cancel previous search
        destinationSearchTask?.cancel()
        
        isSearchingDestination = true
        destinationSearchError = nil
        
        destinationSearchTask = Task {
            do {
                let response = try await networkManager.searchAirports(query: query)
                
                await MainActor.run {
                    if !Task.isCancelled {
                        self.destinationSearchResults = response.results
                        self.isSearchingDestination = false
                        print("✅ Destination search completed: \(response.results.count) airports found for '\(query)'")
                    }
                }
            } catch {
                await MainActor.run {
                    if !Task.isCancelled {
                        self.destinationSearchError = error.localizedDescription
                        self.destinationSearchResults = []
                        self.isSearchingDestination = false
                        print("❌ Destination search failed for '\(query)': \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - Airport Selection with Alert Creation
    
    private func selectOriginAirport(_ airport: FlightTrackAirport) {
        selectedOriginAirport = airport
        originText = "\(airport.iataCode) - \(airport.city)"
        originSearchResults = []
        activeSearchField = nil
        
        print("✅ Selected origin airport: \(airport.iataCode) - \(airport.city)")
        
        // Check if both airports are selected to create alert
        checkAndCreateAlert()
    }
    
    private func selectDestinationAirport(_ airport: FlightTrackAirport) {
        selectedDestinationAirport = airport
        destinationText = "\(airport.iataCode) - \(airport.city)"
        destinationSearchResults = []
        activeSearchField = nil
        
        print("✅ Selected destination airport: \(airport.iataCode) - \(airport.city)")
        
        // Check if both airports are selected to create alert
        checkAndCreateAlert()
    }
    
    // ADDED: Handle popular airport selection
    private func handlePopularAirportSelection(_ airport: FlightTrackAirport) {
        if selectedOriginAirport == nil {
            selectOriginAirport(airport)
        } else if selectedDestinationAirport == nil {
            selectDestinationAirport(airport)
        } else {
            // Both are filled, replace the destination
            selectDestinationAirport(airport)
        }
    }
    
    // ADDED: Create FlightTrackAirport object for popular airports
    private func createPopularAirport(iataCode: String, name: String, city: String, country: String) -> FlightTrackAirport {
        return FlightTrackAirport(
            iataCode: iataCode,
            icaoCode: nil,
            name: name,
            country: country,
            countryCode: "",
            isInternational: true,
            isMajor: true,
            city: city,
            location: FlightTrackLocation(lat: 0.0, lng: 0.0),
            timezone: FlightTrackTimezone(timezone: "", countryCode: "", gmt: 0.0, dst: 0.0)
        )
    }
    
    // MARK: - FIXED Alert Creation Logic
    
    private func checkAndCreateAlert() {
        guard let origin = selectedOriginAirport,
              let destination = selectedDestinationAirport,
              !isCreatingAlert else {
            return
        }
        
        // Ensure origin and destination are different
        guard origin.iataCode != destination.iataCode else {
            alertCreationError = "Origin and destination must be different"
            return
        }
        
        print("🚨 Both airports selected - creating alert...")
        print("   Origin: \(origin.iataCode) - \(origin.city)")
        print("   Destination: \(destination.iataCode) - \(destination.city)")
        
        createAlert(origin: origin, destination: destination)
    }
    
    private func createAlert(origin: FlightTrackAirport, destination: FlightTrackAirport) {
        withAnimation(.easeInOut(duration: 0.3)) {
            isCreatingAlert = true
            alertCreationError = nil
        }
        
        Task {
            do {
                print("🚀 Making alert API call...")
                let alertResponse = try await alertNetworkManager.createAlert(
                    origin: origin.iataCode,
                    destination: destination.iataCode,
                    originName: origin.city,
                    destinationName: destination.city,
                    currency: "INR"
                )
                
                await MainActor.run {
                    print("✅ Alert created successfully! Closing sheet and showing result...")
                    
                    // Call the callback with the response
                    onAlertCreated?(alertResponse)
                    
                    // Close the sheet
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.isCreatingAlert = false
                        self.alertCreationError = error.localizedDescription
                    }
                    print("❌ Alert creation failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Clear Functions
    
    private func clearOriginSearch() {
        originText = ""
        originSearchResults = []
        selectedOriginAirport = nil
        isSearchingOrigin = false
        originSearchError = nil
        originSearchTask?.cancel()
        activeSearchField = nil
        
        // Clear alert error when changing inputs
        alertCreationError = nil
    }
    
    private func clearDestinationSearch() {
        destinationText = ""
        destinationSearchResults = []
        selectedDestinationAirport = nil
        isSearchingDestination = false
        destinationSearchError = nil
        destinationSearchTask?.cancel()
        activeSearchField = nil
        
        // Clear alert error when changing inputs
        alertCreationError = nil
    }
    
    private func cancelAllSearches() {
        searchTimer?.invalidate()
        originSearchTask?.cancel()
        destinationSearchTask?.cancel()
    }
}

// MARK: - Preview
#Preview {
    FALocationSheet { alertResponse in
        print("Alert created: \(alertResponse.id)")
    }
}
