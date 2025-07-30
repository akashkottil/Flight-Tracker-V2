//
//  FAEditSheet.swift
//  AllFlights
//
//  Created by Akash Kottil on 03/07/25.
//

import SwiftUI
import Combine

struct FAEditSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var originText = ""
    @State private var destinationText = ""
    
    @State private var hasPerformedOriginSearch = false
    @State private var hasPerformedDestinationSearch = false

    
    // Alert data to edit
    let alertToEdit: AlertResponse
    let onAlertUpdated: ((AlertResponse) -> Void)?
    
    // Search functionality states
    @State private var originSearchResults: [FlightTrackAirport] = []
    @State private var destinationSearchResults: [FlightTrackAirport] = []
    @State private var isSearchingOrigin = false
    @State private var isSearchingDestination = false
    @State private var originSearchError: String?
    @State private var destinationSearchError: String?
    
    // Selected airports
    @State private var selectedOriginAirport: FlightTrackAirport?
    @State private var selectedDestinationAirport: FlightTrackAirport?
    
    // Active search field tracking
    @State private var activeSearchField: SearchField?
    
    // Search tasks for cancellation
    @State private var originSearchTask: Task<Void, Never>?
    @State private var destinationSearchTask: Task<Void, Never>?
    
    // Alert update states
    @State private var isUpdatingAlert = false
    @State private var alertUpdateError: String?
    
    // Network managers
    private let networkManager = FlightTrackNetworkManager.shared
    private let alertNetworkManager = AlertNetworkManager.shared
    
    // Search debounce timer
    @State private var searchTimer: Timer?
    private let searchDebounceTime: TimeInterval = 0.3
    
    enum SearchField {
        case origin
        case destination
    }
    
    init(alertToEdit: AlertResponse, onAlertUpdated: ((AlertResponse) -> Void)? = nil) {
        self.alertToEdit = alertToEdit
        self.onAlertUpdated = onAlertUpdated
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
                Text("Edit Alert")
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
                            // Only search if this looks like user-typed content, not pre-populated
                            if !originText.isEmpty && !isPrePopulatedText(originText) {
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
                            // Only search if this looks like user-typed content, not pre-populated
                            if !destinationText.isEmpty && !isPrePopulatedText(destinationText) {
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
                    
                   
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(destinationText.isEmpty ? Color.gray.opacity(0.8) : Color.orange, lineWidth: 1)
                )
                .padding(.horizontal)
                .padding(.top)
            }
            
            // Divider
            Divider()
                .padding(.horizontal)
                .padding(.top)
            
            // Alert update error display
            if let error = alertUpdateError {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("Update Failed")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.orange)
                    }
                    
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                    
                    Button("Try Again") {
                        alertUpdateError = nil
                        if let origin = selectedOriginAirport, let destination = selectedDestinationAirport {
                            updateAlert(origin: origin, destination: destination)
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
            
            // Dynamic search results list
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
                    } else if selectedOriginAirport != nil && selectedDestinationAirport != nil {
                        // FIXED: Show nothing when both airports are selected
                        EmptyView()
                    } else {
                        // Show default/popular airports when no active search
                        defaultAirportsSection()
                    }
                }
            }
            
            // Confirm button
            VStack {
                Spacer()
                
                Button(action: {
                    confirmUpdate()
                }) {
                    HStack {
                        Text("Confirm Update")
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .medium))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(canConfirmUpdate() ? Color("FABlue") : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(!canConfirmUpdate() || isUpdatingAlert)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
            }
        }
        .background(Color.white)
        .disabled(isUpdatingAlert)
        .onAppear {
            setupInitialValues()
        }
        .onDisappear {
            cancelAllSearches()
        }
        .alert("Update Failed", isPresented: .constant(alertUpdateError != nil)) {
            Button("OK") {
                alertUpdateError = nil
            }
        } message: {
            if let error = alertUpdateError {
                Text(error)
            }
        }
    }
    
    // MARK: - Setup Initial Values
    
    private func setupInitialValues() {
        // Pre-populate with current alert data
        originText = "\(alertToEdit.route.origin.uppercased()) - \(alertToEdit.route.origin_name)"
        destinationText = "\(alertToEdit.route.destination.uppercased()) - \(alertToEdit.route.destination_name)"
        
        // Create airport objects from current alert data
        selectedOriginAirport = FlightTrackAirport(
            iataCode: alertToEdit.route.origin.uppercased(),
            icaoCode: nil,
            name: alertToEdit.route.origin_name,
            country: "",
            countryCode: "",
            isInternational: nil,
            isMajor: nil,
            city: alertToEdit.route.origin_name,
            location: FlightTrackLocation(lat: 0.0, lng: 0.0),
            timezone: FlightTrackTimezone(timezone: "", countryCode: "", gmt: 0.0, dst: 0.0)
        )
        
        selectedDestinationAirport = FlightTrackAirport(
            iataCode: alertToEdit.route.destination.uppercased(),
            icaoCode: nil,
            name: alertToEdit.route.destination_name,
            country: "",
            countryCode: "",
            isInternational: nil,
            isMajor: nil,
            city: alertToEdit.route.destination_name,
            location: FlightTrackLocation(lat: 0.0, lng: 0.0),
            timezone: FlightTrackTimezone(timezone: "", countryCode: "", gmt: 0.0, dst: 0.0)
        )
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
        if let error = error {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
                Text("Search Error")
                    .font(.system(size: 16, weight: .semibold))
                Text("Please enter the airport name or code correctly to search")
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
        } else if !searchText.isEmpty && isPrePopulatedText(searchText) {
            // FIXED: Show EmptyView if searchText is not empty and has already selected location
            EmptyView()
        } else if results.isEmpty && !searchText.isEmpty && hasUserSearched() {
            // Only show "No airports found" if user has actually searched (not pre-populated)
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
        } else {
            // Show nothing for other cases
            EmptyView()
        }
    }

    
    // MARK: - Default Airports Section
    
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
        }
    }
    
    // MARK: - Location Result Row
    
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
                    Text(iataCode)
                        .font(.system(size: 12, weight: .medium))
                        .padding(8)
                        .frame(width: 44, height: 44)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(cityName), \(countryName)")
                            .font(.headline)
                            .foregroundColor(.black)
                        
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
        .disabled(isUpdatingAlert)
    }
    
    // MARK: - Search Functionality
    
    private func handleOriginTextChange(_ newValue: String) {
        activeSearchField = .origin
        
        searchTimer?.invalidate()
        
        if newValue.isEmpty {
            clearOriginSearch()
            return
        }
        
        // Don't immediately mark as searched - wait for actual search
        searchTimer = Timer.scheduledTimer(withTimeInterval: searchDebounceTime, repeats: false) { _ in
            performOriginSearch(query: newValue)
        }
    }
    
    private func handleDestinationTextChange(_ newValue: String) {
        activeSearchField = .destination
        
        searchTimer?.invalidate()
        
        if newValue.isEmpty {
            clearDestinationSearch()
            return
        }
        
        // Don't immediately mark as searched - wait for actual search
        searchTimer = Timer.scheduledTimer(withTimeInterval: searchDebounceTime, repeats: false) { _ in
            performDestinationSearch(query: newValue)
        }
    }
    
    // MARK: - SINGLE VERSION: Search Functions (Removed Duplicates)
    
    private func performOriginSearch(query: String) {
        guard !query.isEmpty && query.count >= 2 else {
            originSearchResults = []
            hasPerformedOriginSearch = false
            return
        }
        
        originSearchTask?.cancel()
        
        isSearchingOrigin = true
        originSearchError = nil
        hasPerformedOriginSearch = true // Mark that search has been performed
        
        originSearchTask = Task {
            do {
                let response = try await networkManager.searchAirports(query: query)
                
                await MainActor.run {
                    if !Task.isCancelled {
                        self.originSearchResults = response.results
                        self.isSearchingOrigin = false
                    }
                }
            } catch {
                await MainActor.run {
                    if !Task.isCancelled {
                        self.originSearchError = error.localizedDescription
                        self.originSearchResults = []
                        self.isSearchingOrigin = false
                    }
                }
            }
        }
    }
    
    private func performDestinationSearch(query: String) {
        guard !query.isEmpty && query.count >= 2 else {
            destinationSearchResults = []
            hasPerformedDestinationSearch = false
            return
        }
        
        destinationSearchTask?.cancel()
        
        isSearchingDestination = true
        destinationSearchError = nil
        hasPerformedDestinationSearch = true // Mark that search has been performed
        
        destinationSearchTask = Task {
            do {
                let response = try await networkManager.searchAirports(query: query)
                
                await MainActor.run {
                    if !Task.isCancelled {
                        self.destinationSearchResults = response.results
                        self.isSearchingDestination = false
                    }
                }
            } catch {
                await MainActor.run {
                    if !Task.isCancelled {
                        self.destinationSearchError = error.localizedDescription
                        self.destinationSearchResults = []
                        self.isSearchingDestination = false
                    }
                }
            }
        }
    }
    
    // MARK: - Airport Selection
    
    private func selectOriginAirport(_ airport: FlightTrackAirport) {
        selectedOriginAirport = airport
        originText = "\(airport.iataCode) - \(airport.city)"
        originSearchResults = []
        activeSearchField = nil
    }
    
    private func selectDestinationAirport(_ airport: FlightTrackAirport) {
        selectedDestinationAirport = airport
        destinationText = "\(airport.iataCode) - \(airport.city)"
        destinationSearchResults = []
        activeSearchField = nil
    }
    
    private func handlePopularAirportSelection(_ airport: FlightTrackAirport) {
        if activeSearchField == .origin {
            selectOriginAirport(airport)
        } else if activeSearchField == .destination {
            selectDestinationAirport(airport)
        } else {
            // Default to origin if no active field
            selectOriginAirport(airport)
        }
    }
    
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
    
    // MARK: - Update Alert Logic
    
    private func canConfirmUpdate() -> Bool {
        return selectedOriginAirport != nil && selectedDestinationAirport != nil
    }
    
    private func confirmUpdate() {
        guard let origin = selectedOriginAirport,
              let destination = selectedDestinationAirport else {
            return
        }
        
        updateAlert(origin: origin, destination: destination)
    }
    
    private func updateAlert(origin: FlightTrackAirport, destination: FlightTrackAirport) {
        withAnimation(.easeInOut(duration: 0.3)) {
            isUpdatingAlert = true
            alertUpdateError = nil
        }
        
        Task {
            do {
                print("🚀 Making edit alert API call...")
                let updatedAlert = try await alertNetworkManager.editAlert(
                    alertId: alertToEdit.id,
                    origin: origin.iataCode,
                    destination: destination.iataCode,
                    originName: origin.city,
                    destinationName: destination.city,
                    currency: alertToEdit.route.currency
                )
                
                await MainActor.run {
                    print("✅ Alert updated successfully! Closing sheet...")
                    
                    onAlertUpdated?(updatedAlert)
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.isUpdatingAlert = false
                        self.alertUpdateError = error.localizedDescription
                    }
                    print("❌ Alert update failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func hasUserSearched() -> Bool {
        if activeSearchField == .origin {
            return hasPerformedOriginSearch
        } else if activeSearchField == .destination {
            return hasPerformedDestinationSearch
        }
        return false
    }
    
    private func isPrePopulatedText(_ text: String) -> Bool {
        // Pre-populated text has format "COK - Kochi"
        return text.contains(" - ") && text.count > 5
    }
    
    // MARK: - Clear Functions
    
    private func clearOriginSearch() {
        originText = ""
        originSearchResults = []
        isSearchingOrigin = false
        originSearchError = nil
        originSearchTask?.cancel()
        activeSearchField = nil
        alertUpdateError = nil
        hasPerformedOriginSearch = false // Reset search state
    }

    private func clearDestinationSearch() {
        destinationText = ""
        destinationSearchResults = []
        isSearchingDestination = false
        destinationSearchError = nil
        destinationSearchTask?.cancel()
        activeSearchField = nil
        alertUpdateError = nil
        hasPerformedDestinationSearch = false // Reset search state
    }
    
    private func cancelAllSearches() {
        searchTimer?.invalidate()
        originSearchTask?.cancel()
        destinationSearchTask?.cancel()
    }
}

// MARK: - Preview
//#Preview {
//    FAEditSheet(
//        alertToEdit: AlertResponse(
//            id: "sample-id",
//            user: AlertUserResponse(
//                id: "testId",
//                push_token: "token",
//                created_at: "2025-06-27T14:06:14.919574Z",
//                updated_at: "2025-06-27T14:06:14.919604Z"
//            ),
//            route: AlertRouteResponse(
//                id: 151,
//                origin: "COK",
//                destination: "DXB",
//                currency: "INR",
//                origin_name: "Kochi",
//                destination_name: "Dubai",
//                created_at: "2025-06-25T09:32:47.398234Z",
//                updated_at: "2025-06-27T14:06:14.932802Z"
//            ),
//            cheapest_flight: nil,
//            image_url: nil,
//            target_price: nil,
//            last_notified_price: nil,
//            created_at: "2025-06-27T14:06:14.947629Z",
//            updated_at: "2025-06-27T14:06:14.947659Z"
//        )
//    ) { updatedAlert in
//        print("Alert updated: \(updatedAlert.id)")
//    }
//}
