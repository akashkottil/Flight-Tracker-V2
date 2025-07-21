import SwiftUICore
import CoreLocation
import Combine
import Foundation
import SwiftUI


class CurrentLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = CurrentLocationManager()
    
    @Published var locationState: LocationState = .idle
    @Published var currentLocation: CLLocation?
    @Published var locationName: String = ""
    @Published var nearestAirportCode: String = ""
    
    private let locationManager = CLLocationManager()
    private var completion: ((Result<LocationResult, LocationError>) -> Void)?
    private var cancellables = Set<AnyCancellable>()
    
    enum LocationState: Equatable {
        case idle
        case requesting
        case locating
        case geocoding
        case success
        case error(LocationError)
        
        static func == (lhs: LocationState, rhs: LocationState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.requesting, .requesting), (.locating, .locating), (.geocoding, .geocoding), (.success, .success):
                return true
            case (.error(let lhsError), .error(let rhsError)):
                return lhsError.localizedDescription == rhsError.localizedDescription
            default:
                return false
            }
        }
    }
    
    enum LocationError: LocalizedError {
        case permissionDenied
        case locationUnavailable
        case geocodingFailed
        case cityNotFound
        case timeout
        
        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Location access denied. Please enable in Settings."
            case .locationUnavailable:
                return "Unable to get your location. Please try again."
            case .geocodingFailed:
                return "Unable to determine your location."
            case .cityNotFound:
                return "No nearby cities found."
            case .timeout:
                return "Location request timed out. Please try again."
            }
        }
    }
    
    struct LocationResult {
        let locationName: String
        let airportCode: String
        let coordinates: CLLocationCoordinate2D
        let cityName: String? // Add city name from API
    }
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 100
    }
    
    func getCurrentLocation(completion: @escaping (Result<LocationResult, LocationError>) -> Void) {
        self.completion = completion
        
        // FIXED: Check authorization status without calling locationServicesEnabled on main thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch self.locationManager.authorizationStatus {
                case .notDetermined:
                    self.locationState = .requesting
                    self.locationManager.requestWhenInUseAuthorization()
                case .denied, .restricted:
                    self.locationState = .error(.permissionDenied)
                    completion(.failure(.permissionDenied))
                case .authorizedWhenInUse, .authorizedAlways:
                    self.startLocationUpdate()
                @unknown default:
                    self.locationState = .error(.locationUnavailable)
                    completion(.failure(.locationUnavailable))
                }
            }
        }
    }
    
    private func startLocationUpdate() {
        // FIXED: Check location services on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let isLocationServicesEnabled = CLLocationManager.locationServicesEnabled()
            
            DispatchQueue.main.async {
                guard isLocationServicesEnabled else {
                    self.locationState = .error(.locationUnavailable)
                    self.completion?(.failure(.locationUnavailable))
                    return
                }
                
                self.locationState = .locating
                self.locationManager.requestLocation()
                
                // Set timeout
                DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                    if case .locating = self.locationState {
                        self.locationState = .error(.timeout)
                        self.completion?(.failure(.timeout))
                    }
                }
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        currentLocation = location
        locationState = .geocoding
        
        // Reverse geocode to get location name
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    print("Geocoding error: \(error)")
                    self.locationState = .error(.geocodingFailed)
                    self.completion?(.failure(.geocodingFailed))
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    self.locationState = .error(.geocodingFailed)
                    self.completion?(.failure(.geocodingFailed))
                    return
                }
                
                // Create location name
                let locationName = self.createLocationName(from: placemark)
                self.locationName = locationName
                
                // MODIFIED: Find nearest city instead of airport
                self.findNearestCity(to: location.coordinate, placemark: placemark) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let cityCode):
                            self.nearestAirportCode = cityCode.0
                            self.locationState = .success
                            
                            let locationResult = LocationResult(
                                locationName: locationName,
                                airportCode: cityCode.0,
                                coordinates: location.coordinate, cityName: cityCode.1
                            )
                            self.completion?(.success(locationResult))
                            
                        case .failure(let error):
                            self.locationState = .error(error)
                            self.completion?(.failure(error))
                        }
                    }
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationState = .error(.locationUnavailable)
            self.completion?(.failure(.locationUnavailable))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            if case .requesting = locationState {
                startLocationUpdate()
            }
        case .denied, .restricted:
            locationState = .error(.permissionDenied)
            completion?(.failure(.permissionDenied))
        default:
            break
        }
    }
    
    // MARK: - Helper Methods
    
    private func createLocationName(from placemark: CLPlacemark) -> String {
        // Prioritize district (subAdministrativeArea) over locality for your use case
        if let district = placemark.subAdministrativeArea {
            return district
        } else if let locality = placemark.locality {
            return locality
        } else if let administrativeArea = placemark.administrativeArea {
            return administrativeArea
        } else {
            return "Current Location"
        }
    }
    
    // MODIFIED: New method to find nearest city using specific API endpoint
    private func findNearestCity(to coordinate: CLLocationCoordinate2D, placemark: CLPlacemark, completion: @escaping (Result<(String, String?), LocationError>) -> Void) {
        // Get the district name from the placemark (subAdministrativeArea is typically the district)
        let districtName = placemark.subAdministrativeArea ?? placemark.locality ?? "Current Location"
        
        // Get country code from placemark (ISO country code)
        let countryCode = placemark.isoCountryCode ?? "IN" // Default to India if not available
        
        // Use the specific autocomplete API with district name and country
        searchDistrictWithAPI(district: districtName, countryCode: countryCode) { result in
            completion(result)
        }
    }
    
    // New method to call the specific autocomplete API
    private func searchDistrictWithAPI(district: String, countryCode: String, completion: @escaping (Result<(String, String?), LocationError>) -> Void) {
        // Construct the API URL
        guard let encodedDistrict = district.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://staging.plane.lascade.com/api/autocomplete/?country=\(countryCode)&search=\(encodedDistrict)&language=en-GB") else {
            completion(.failure(.cityNotFound))
            return
        }
        
        // Create URL request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Make the API call
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("API Error: \(error.localizedDescription)")
                    // Fallback to original method if this API fails
                    self.fallbackToOriginalAPI(district: district, completion: completion)
                    return
                }
                
                guard let data = data else {
                    print("No data received from API")
                    self.fallbackToOriginalAPI(district: district, completion: completion)
                    return
                }
                
                do {
                    // Parse the JSON response with the correct structure
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let dataArray = json["data"] as? [[String: Any]] {
                        
                        // Take the first result and get both iataCode and cityName
                        if let firstResult = dataArray.first,
                           let iataCode = firstResult["iataCode"] as? String,
                           !iataCode.isEmpty {
                            
                            let cityName = firstResult["cityName"] as? String
                            print("Found IATA code from API: \(iataCode), City: \(cityName ?? "N/A")")
                            completion(.success((iataCode, cityName)))
                            return
                        }
                        
                        // If no iataCode found in first result, try other results
                        for item in dataArray {
                            if let iataCode = item["iataCode"] as? String, !iataCode.isEmpty {
                                let cityName = item["cityName"] as? String
                                print("Found IATA code from API (fallback): \(iataCode), City: \(cityName ?? "N/A")")
                                completion(.success((iataCode, cityName)))
                                return
                            }
                        }
                        
                        // If no IATA code found at all, fallback
                        print("No IATA code found in API response")
                        self.fallbackToOriginalAPI(district: district, completion: completion)
                        
                    } else {
                        print("Unexpected JSON structure")
                        self.fallbackToOriginalAPI(district: district, completion: completion)
                    }
                    
                } catch {
                    print("JSON parsing error: \(error.localizedDescription)")
                    self.fallbackToOriginalAPI(district: district, completion: completion)
                }
            }
        }.resume()
    }
    
    // Fallback method using the original ExploreAPIService
    private func fallbackToOriginalAPI(district: String, completion: @escaping (Result<(String, String?), LocationError>) -> Void) {
        ExploreAPIService.shared.fetchAutocomplete(query: district)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { result in
                    if case .failure = result {
                        // If both APIs fail, generate a fallback code
                        let fallbackCode = self.generateFallbackCityCode(from: district)
                        completion(.success((fallbackCode, district)))
                    }
                },
                receiveValue: { results in
                    // First, try to find a city result
                    if let cityResult = results.first(where: { $0.type == "city" }) {
                        completion(.success((cityResult.iataCode, cityResult.cityName)))
                        return
                    }
                    
                    // If no city found, try to find any result
                    if let firstResult = results.first {
                        completion(.success((firstResult.iataCode, firstResult.cityName)))
                    } else {
                        // Generate fallback code
                        let fallbackCode = self.generateFallbackCityCode(from: district)
                        completion(.success((fallbackCode, district)))
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // Helper method to generate a fallback district code
    private func generateFallbackCityCode(from districtName: String) -> String {
        // Clean the district name and take first 3 characters, or use "LOC" as ultimate fallback
        let cleanedName = districtName.uppercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
        
        if cleanedName.count >= 3 {
            return String(cleanedName.prefix(3))
        } else if !cleanedName.isEmpty {
            return cleanedName + String(repeating: "X", count: 3 - cleanedName.count)
        } else {
            return "LOC"
        }
    }
}


// MARK: - Enhanced Current Location Button (Updated to use cityName from API)
struct EnhancedCurrentLocationButton: View {
    @StateObject private var locationManager = CurrentLocationManager.shared
    @State private var isAnimating = false
    @State private var buttonScale: CGFloat = 1.0
    @State private var pulseScale: CGFloat = 1.0
    @State private var showError = false
    @State private var errorMessage = ""
    
    let onLocationSelected: (CurrentLocationManager.LocationResult) -> Void
    
    var body: some View {
        Button(action: handleLocationRequest) {
            HStack(spacing: 12) {
                ZStack {
                    if case .locating = locationManager.locationState {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                            .scaleEffect(pulseScale)
                            .animation(
                                .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                                value: pulseScale
                            )
                    } else if case .geocoding = locationManager.locationState {
                        Image(systemName: "location.magnifyingglass")
                            .foregroundColor(.blue)
                            .offset(y: isAnimating ? -3 : 0)
                            .animation(
                                .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                    } else if case .requesting = locationManager.locationState {
                        Image(systemName: "location.circle")
                            .foregroundColor(.orange)
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .opacity(isAnimating ? 0.7 : 1.0)
                            .animation(
                                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                    } else {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                    }
                }
                .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(getLocationButtonText())
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                        
                        if isLocationLoading {
                            Spacer()
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        }
                    }
                    
                    if case .geocoding = locationManager.locationState {
                        Text("Finding Airport near you...")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(getBackgroundColor().opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(getBackgroundColor().opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(buttonScale)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: buttonScale)
        }
        .disabled(isLocationLoading)
        .alert("Location Error", isPresented: $showError) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: locationManager.locationState) { _, newState in
            handleLocationStateChange(newState)
        }
    }
    
    private var isLocationLoading: Bool {
        switch locationManager.locationState {
        case .requesting, .locating, .geocoding:
            return true
        default:
            return false
        }
    }
    
    private func getLocationButtonText() -> String {
        switch locationManager.locationState {
        case .idle:
            return "Use Current Location"
        case .requesting:
            return "Requesting Permission..."
        case .locating:
            return "Getting Your Location..."
        case .geocoding:
            return "Finding Your Airport..."
        case .success:
            return "Location Found!"
        case .error:
            return "Try Again"
        }
    }
    
    private func getBackgroundColor() -> Color {
        switch locationManager.locationState {
        case .requesting:
            return .orange
        case .locating, .geocoding:
            return .blue
        case .success:
            return .green
        case .error:
            return .red
        default:
            return .blue
        }
    }
    
    private func handleLocationRequest() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            buttonScale = 0.95
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                buttonScale = 1.0
            }
        }
        
        locationManager.getCurrentLocation { result in
            switch result {
            case .success(let locationResult):
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    buttonScale = 1.05
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        buttonScale = 1.0
                    }
                    onLocationSelected(locationResult)
                }
                
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    buttonScale = 0.95
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        buttonScale = 1.0
                    }
                }
            }
        }
    }
    
    private func handleLocationStateChange(_ newState: CurrentLocationManager.LocationState) {
        switch newState {
        case .locating:
            pulseScale = 1.2
            isAnimating = true
        case .geocoding:
            isAnimating = true
        case .requesting:
            isAnimating = true
        case .success, .error, .idle:
            isAnimating = false
            pulseScale = 1.0
        }
    }
}



// MARK: - Fixed Home Multi-City Segment View
struct HomeMultiCitySegmentView: View {
    
    @ObservedObject var searchViewModel: SharedFlightSearchViewModel
    let trip: MultiCityTrip
    let index: Int
    let canRemove: Bool
    let isLastRow: Bool
    let onFromTap: () -> Void
    let onToTap: () -> Void
    let onDateTap: () -> Void
    let onRemove: () -> Void
    
    // Helper methods for dynamic colors
    private func getFromLocationTextColor() -> Color {
        if trip.fromIataCode.isEmpty {
            return .gray
        }
        return .primary
    }
    
    private func getFromLocationNameTextColor() -> Color {
        if trip.fromLocation.isEmpty {
            return .gray
        }
        return .primary
    }
    
    private func getToLocationTextColor() -> Color {
        if trip.toIataCode.isEmpty {
            return .gray
        }
        return .primary
    }
    
    private func getToLocationNameTextColor() -> Color {
        if trip.toLocation.isEmpty {
            return .gray
        }
        return .primary
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top horizontal line - always drawn
            Divider()
                .background(Color.gray.opacity(0.3))
                .padding(.vertical, 8)
                .padding(.horizontal,-20)
            
            HStack(spacing: 0) {
                // From Location Column
                Button(action: onFromTap) {
                    HStack( spacing: 2) {
                        Text(trip.fromIataCode.isEmpty ? "" : trip.fromIataCode)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(getFromLocationTextColor())
                        Text(trip.fromLocation.isEmpty || trip.fromLocation == "Departure?" ? "Departure?" : trip.fromLocation)
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .foregroundColor(getFromLocationNameTextColor())
                    }
                    .padding(.horizontal, 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .frame(width: 1, height: 76)
                    .background(Color.gray.opacity(0.3))
                    .padding(.top, 10)
                
                // To Location Column
                Button(action: onToTap) {
                    HStack( spacing: 2) {
                        Text(trip.toIataCode.isEmpty ? "" : trip.toIataCode)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(getToLocationTextColor())
                        Text(trip.toLocation.isEmpty || trip.toLocation == "Destination?" ? "Destination?" : trip.toLocation)
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .foregroundColor(getToLocationNameTextColor())
                    }
                    .padding(.horizontal, 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .frame(width: 1, height: 76)
                    .background(Color.gray.opacity(0.3))
                    .padding(.top, 10)
                
                // Date Column
                Button(action: onDateTap) {
                    Text(trip.compactDisplayDate)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: 100, alignment: .leading)
                }
                
                // FIXED: Only show the right divider when there's a delete button
                if canRemove {
                    Divider()
                        .frame(width: 1, height: 76)
                        .background(Color.gray.opacity(0.3))
                        .padding(.top, 10)
                    
                    // Remove Button Column - only when canRemove is true
                    Button(action: onRemove) {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                    }
                }
            }
            .frame(height: 48)
        }
    }
}




// MARK: - Updated Home Multi-City Location Sheet with Recent Searches

struct HomeMultiCityLocationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var searchViewModel: SharedFlightSearchViewModel
    let tripIndex: Int
    let isFromLocation: Bool
    
    @State private var searchText = ""
    @State private var results: [AutocompleteResult] = []
    @State private var isSearching = false
    @State private var searchError: String? = nil
    @FocusState private var isTextFieldFocused: Bool
    @State private var cancellables = Set<AnyCancellable>()
    @State private var showRecentSearches = true
    
    // Add recent search manager
    @ObservedObject private var recentSearchManager = RecentLocationSearchManager.shared
    
    private let searchDebouncer = SearchDebouncer(delay: 0.3)

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18))
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                Text(isFromLocation ? "From Where?" : "Where to?")
                    .font(.headline)
                
                Spacer()
                
                // Empty space to balance the X button
                Image(systemName: "xmark")
                    .font(.system(size: 18))
                    .foregroundColor(.clear)
            }
            .padding()
            
            // Search bar
            HStack {
                TextField(isFromLocation ? "Origin City, Airport or place" : "Destination City, Airport or place", text: $searchText)
                    .padding(12)
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange, lineWidth: 2)
                    )
                    .cornerRadius(8)
                    .focused($isTextFieldFocused)
                    .onChange(of: searchText) {
                        handleTextChange()
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        results = []
                        showRecentSearches = true
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)
            
Spacer()
            
            // Results section with recent searches
            if isSearching {
                VStack {
                    ProgressView()
                    Text("Searching...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                Spacer()
            } else if let error = searchError {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding()
                Spacer()
            } else if !results.isEmpty {
                // Show search results
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(results) { result in
                            LocationResultRow(result: result)
                                .onTapGesture {
                                    selectLocation(result: result)
                                }
                        }
                    }
                }
            } else if showRecentSearches && searchText.isEmpty {
                // UPDATED: Pass appropriate search type based on isFromLocation
                RecentLocationSearchView(
                    onLocationSelected: { result in
                        selectLocation(result: result)
                    },
                    showAnywhereOption: false,
                    searchType: isFromLocation ? .departure : .destination
                )
                Spacer()
            }else if shouldShowNoResults() {
                Text("No results found")
                    .foregroundColor(.gray)
                    .padding()
                Spacer()
            } else {
                // UPDATED: Pass appropriate search type based on isFromLocation
                RecentLocationSearchView(
                    onLocationSelected: { result in
                        selectLocation(result: result)
                    },
                    showAnywhereOption: false,
                    searchType: isFromLocation ? .departure : .destination
                )
                Spacer()
            }
        }
        .background(Color.white)
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
    private func handleTextChange() {
        showRecentSearches = searchText.isEmpty
        
        if !searchText.isEmpty {
            searchDebouncer.debounce {
                searchLocations(query: searchText)
            }
        } else {
            results = []
        }
    }
    
    private func shouldShowNoResults() -> Bool {
        return results.isEmpty && !searchText.isEmpty && !showRecentSearches
    }
    
    private func selectLocation(result: AutocompleteResult) {
        let searchType: LocationSearchType = isFromLocation ? .departure : .destination
               recentSearchManager.addRecentSearch(result, searchType: searchType)
        
        if isFromLocation {
            searchViewModel.multiCityTrips[tripIndex].fromLocation = result.cityName
            searchViewModel.multiCityTrips[tripIndex].fromIataCode = result.iataCode
        } else {
            searchViewModel.multiCityTrips[tripIndex].toLocation = result.cityName
            searchViewModel.multiCityTrips[tripIndex].toIataCode = result.iataCode
        }
        
        searchText = result.cityName
        dismiss()
    }
    
    private func searchLocations(query: String) {
        guard !query.isEmpty else {
            results = []
            return
        }
        
        isSearching = true
        searchError = nil
        
        ExploreAPIService.shared.fetchAutocomplete(query: query)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                isSearching = false
                if case .failure(let error) = completion {
                    searchError = error.localizedDescription
                }
            }, receiveValue: { results in
                self.results = results
            })
            .store(in: &cancellables)
    }
}



// MARK: - Home Collapsible Search Input (matching style)
// MARK: - Home Collapsible Search Input (Updated for transformation)
struct HomeCollapsibleSearchInput: View {
    @Binding var isExpanded: Bool
    @ObservedObject var searchViewModel: SharedFlightSearchViewModel
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded = true
            }
        }) {
            // Route display
            HStack(spacing: 8) {
                // From
                Text(searchViewModel.fromIataCode.isEmpty ? "FROM" : searchViewModel.fromIataCode)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
               Text("-")
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                // To
                Text(searchViewModel.toIataCode.isEmpty ? "TO" : searchViewModel.toIataCode)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 4, height: 4)
                
                // Date display (always show, will display "Anytime" when no dates selected)
                Text(formatDatesForCollapsed())
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                Text("Search")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: 105)
                    .frame(height: 44)
                    .background(
                        RoundedCornerss(tl: 8, tr: 26, bl: 8, br: 26)
                            .fill(Color.orange)
                    )
            }
            .padding(4)
            .padding(.leading,16)
            
        .background(Color.white)
        .cornerRadius(26)
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(Color.orange, lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal, 16)
    }
    
    private func formatDatesForDisplay() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E,d MMM"
        
        if searchViewModel.selectedDates.count >= 2 {
            let sortedDates = searchViewModel.selectedDates.sorted()
            return "\(formatter.string(from: sortedDates[0])) - \(formatter.string(from: sortedDates[1]))"
        } else if searchViewModel.selectedDates.count == 1 {
            return formatter.string(from: searchViewModel.selectedDates[0])
        }
        return "Anytime"  // Changed from "Select dates"
    }

    // UPDATED: formatDatesForCollapsed with new format
    private func formatDatesForCollapsed() -> String {
        if searchViewModel.selectedDates.count >= 2 {
            let sortedDates = searchViewModel.selectedDates.sorted()
            let startDate = sortedDates[0]
            let endDate = sortedDates[1]
            
            let calendar = Calendar.current
            let startMonth = calendar.component(.month, from: startDate)
            let endMonth = calendar.component(.month, from: endDate)
            let startYear = calendar.component(.year, from: startDate)
            let endYear = calendar.component(.year, from: endDate)
            
            if startMonth == endMonth && startYear == endYear {
                // Same month: "Jun 15-22"
                let monthFormatter = DateFormatter()
                monthFormatter.dateFormat = "MMM"
                let month = monthFormatter.string(from: startDate)
                
                let dayFormatter = DateFormatter()
                dayFormatter.dateFormat = "d"
                let startDay = dayFormatter.string(from: startDate)
                let endDay = dayFormatter.string(from: endDate)
                
                return "\(month) \(startDay)-\(endDay)"
            } else {
                // Different months: "Jun 15-Jul 22"
                let startFormatter = DateFormatter()
                startFormatter.dateFormat = "MMM d"
                let startFormatted = startFormatter.string(from: startDate)
                
                let endFormatter = DateFormatter()
                endFormatter.dateFormat = "MMM d"
                let endFormatted = endFormatter.string(from: endDate)
                
                return "\(startFormatted)-\(endFormatted)"
            }
        } else if searchViewModel.selectedDates.count == 1 {
            // Single date: "Jun 15"
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: searchViewModel.selectedDates[0])
        } else {
            // No dates: "Anytime"
            return "Anytime"
        }
    }
}

// MARK: - RoundedCorners Helper
struct RoundedCornerss: Shape {
    var tl: CGFloat = 0.0
    var tr: CGFloat = 0.0
    var bl: CGFloat = 0.0
    var br: CGFloat = 0.0

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let w = rect.size.width
        let h = rect.size.height

        // Make sure we do not exceed the size of the rectangle
        let tr = min(min(self.tr, h/2), w/2)
        let tl = min(min(self.tl, h/2), w/2)
        let bl = min(min(self.bl, h/2), w/2)
        let br = min(min(self.br, h/2), w/2)

        path.move(to: CGPoint(x: w / 2.0, y: 0))
        path.addLine(to: CGPoint(x: w - tr, y: 0))
        path.addArc(center: CGPoint(x: w - tr, y: tr), radius: tr, startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)
        path.addLine(to: CGPoint(x: w, y: h - br))
        path.addArc(center: CGPoint(x: w - br, y: h - br), radius: br, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)
        path.addLine(to: CGPoint(x: bl, y: h))
        path.addArc(center: CGPoint(x: bl, y: h - bl), radius: bl, startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)
        path.addLine(to: CGPoint(x: 0, y: tl))
        path.addArc(center: CGPoint(x: tl, y: tl), radius: tl, startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
        path.closeSubpath()

        return path
    }
}



// MARK: - Corrected Home From Location Search Sheet
struct HomeFromLocationSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var searchViewModel: SharedFlightSearchViewModel
    @State private var searchText = ""
    @State private var results: [AutocompleteResult] = []
    @State private var isSearching = false
    @State private var searchError: String? = nil
    @FocusState private var isTextFieldFocused: Bool
    @State private var cancellables = Set<AnyCancellable>()
    @State private var showRecentSearches = true
    
    // Add recent search manager
    @ObservedObject private var recentSearchManager = RecentLocationSearchManager.shared
    
    private let searchDebouncer = SearchDebouncer(delay: 0.3)

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18))
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                Text("From Where?")
                    .font(.headline)
                
                Spacer()
                
                // Empty space to balance the X button
                Image(systemName: "xmark")
                    .font(.system(size: 18))
                    .foregroundColor(.clear)
            }
            .padding()
            
            // UPDATED: Search bar with embedded dismiss button
            HStack {
                // Search field container with embedded clear button
                ZStack(alignment: .trailing) {
                    TextField("Origin City, Airport or place", text: $searchText)
                        .padding(12)
                        .padding(.trailing, !searchText.isEmpty ? 40 : 12) // Add right padding when clear button is visible
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.orange, lineWidth: 2)
                        )
                        .cornerRadius(8)
                        .focused($isTextFieldFocused)
                        .onChange(of: searchText) {
                            handleTextChange()
                        }
                    
                    // Clear button positioned inside the search box
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            results = []
                            showRecentSearches = true
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 18))
                        }
                        .padding(.trailing, 12)
                    }
                }
            }
            .padding(.horizontal)
            
            // Current location button
            // Enhanced Current Location Button
            EnhancedCurrentLocationButton { locationResult in
                // Handle successful location selection with animation
                withAnimation(.easeInOut(duration: 0.3)) {
                    // FIXED: Use cityName from API if available, otherwise use locationName
                    let displayName = locationResult.cityName ?? locationResult.locationName
                    searchViewModel.fromLocation = displayName
                    searchViewModel.fromIataCode = locationResult.airportCode
                    searchText = displayName
                }
                
                // Add to recent searches
                let autocompleteResult = AutocompleteResult(
                    iataCode: locationResult.airportCode,
                    airportName: "Current Location",
                    type: "airport",
                    displayName: locationResult.cityName ?? locationResult.locationName,
                    cityName: locationResult.cityName ?? locationResult.locationName.components(separatedBy: ",").first ?? "",
                    countryName: locationResult.locationName.components(separatedBy: ",").last ?? "",
                    countryCode: "IN",
                    imageUrl: "",
                    coordinates: AutocompleteCoordinates(
                        latitude: String(locationResult.coordinates.latitude),
                        longitude: String(locationResult.coordinates.longitude)
                    )
                )
                
                recentSearchManager.addRecentSearch(autocompleteResult, searchType: .departure)
                
                // Dismiss with a slight delay for better UX
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    dismiss()
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Spacer()
            
            // Results section with recent searches
            if isSearching {
                VStack {
                    ProgressView()
                    Text("Searching...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                Spacer()
            } else if let error = searchError {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding()
                Spacer()
            } else if !results.isEmpty {
                // Show search results
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(results) { result in
                            LocationResultRow(result: result)
                                .onTapGesture {
                                    selectLocation(result: result)
                                }
                        }
                    }
                }
            } else if showRecentSearches && searchText.isEmpty {
                // Show recent searches when no active search - UPDATED: Filter for departure
                RecentLocationSearchView(
                    onLocationSelected: { result in
                        selectLocation(result: result)
                    },
                    showAnywhereOption: false,
                    searchType: .departure  // ADD: Filter for departure searches only
                )
                Spacer()
            }  else if shouldShowNoResults() {
                Image("noresultIcon")
                Text("No result found.search something else.")
                    .foregroundColor(.gray)
                    .padding()
                Spacer()
            }else {
                // UPDATED: Filter for departure searches only
                RecentLocationSearchView(
                    onLocationSelected: { result in
                        selectLocation(result: result)
                    },
                    showAnywhereOption: false,
                    searchType: .departure  // ADD: Filter for departure searches only
                )
                Spacer()
            }
        }
        .background(Color.white)
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
    private func handleTextChange() {
        showRecentSearches = searchText.isEmpty
        
        if !searchText.isEmpty {
            searchDebouncer.debounce {
                searchLocations(query: searchText)
            }
        } else {
            results = []
        }
    }
    
    private func shouldShowNoResults() -> Bool {
        return results.isEmpty && !searchText.isEmpty && !showRecentSearches
    }
    
    private func selectLocation(result: AutocompleteResult) {
        // IMPORTANT: Add to recent searches before processing
        recentSearchManager.addRecentSearch(result, searchType: .departure)
        
        // Check if this would match the current destination
        if !searchViewModel.toIataCode.isEmpty && result.iataCode == searchViewModel.toIataCode {
            searchError = "Origin and destination cannot be the same"
            return
        }
        
        searchViewModel.fromLocation = result.cityName
        searchViewModel.fromIataCode = result.iataCode
        searchText = result.cityName
        dismiss()
    }
    
    private func searchLocations(query: String) {
        guard !query.isEmpty else {
            results = []
            return
        }
        
        isSearching = true
        searchError = nil
        
        ExploreAPIService.shared.fetchAutocomplete(query: query)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                isSearching = false
                if case .failure(let error) = completion {
                    searchError = error.localizedDescription
                }
            }, receiveValue: { results in
                self.results = results
            })
            .store(in: &cancellables)
    }
}

struct HomeToLocationSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var searchViewModel: SharedFlightSearchViewModel
    @State private var searchText = ""
    @State private var results: [AutocompleteResult] = []
    @State private var isSearching = false
    @State private var searchError: String? = nil
    @FocusState private var isTextFieldFocused: Bool
    @State private var cancellables = Set<AnyCancellable>()
    @State private var showRecentSearches = true
    
    // Add recent search manager
    @ObservedObject private var recentSearchManager = RecentLocationSearchManager.shared
    
    private let searchDebouncer = SearchDebouncer(delay: 0.3)

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18))
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                Text("Where to?")
                    .font(.headline)
                
                Spacer()
                
                // Empty space to balance the X button
                Image(systemName: "xmark")
                    .font(.system(size: 18))
                    .foregroundColor(.clear)
            }
            .padding()
            
            // UPDATED: Search bar with embedded dismiss button
            HStack {
                // Search field container with embedded clear button
                ZStack(alignment: .trailing) {
                    TextField("Destination City, Airport or place", text: $searchText)
                        .padding(12)
                        .padding(.trailing, !searchText.isEmpty ? 40 : 12) // Add right padding when clear button is visible
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.orange, lineWidth: 2)
                        )
                        .cornerRadius(8)
                        .focused($isTextFieldFocused)
                        .onChange(of: searchText) {
                            handleTextChange()
                        }
                    
                    // Clear button positioned inside the search box
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            results = []
                            showRecentSearches = true
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 18))
                        }
                        .padding(.trailing, 12)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Results section with recent searches (NO ANYWHERE OPTION)
            if isSearching {
                VStack {
                    ProgressView()
                    Text("Searching...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                Spacer()
            } else if !results.isEmpty {
                // Show search results with Anywhere option at top
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // ADDED: Anywhere option at top of search results
                        AnywhereOptionRow()
                            .onTapGesture {
                                selectAnywhereLocation()
                            }
                        
                        Divider()
                            .padding(.horizontal)
                        
                        ForEach(results) { result in
                            LocationResultRow(result: result)
                                .onTapGesture {
                                    selectLocation(result: result)
                                }
                        }
                    }
                }
            } else if showRecentSearches && searchText.isEmpty {
                // Show recent searches with Anywhere option at top
                VStack(spacing: 0) {
                    // ADDED: Anywhere option at top of recent searches
                    AnywhereOptionRow()
                        .onTapGesture {
                            selectAnywhereLocation()
                        }
                    
                    Spacer()
                    
                    RecentLocationSearchView(
                        onLocationSelected: { result in
                            selectLocation(result: result)
                        },
                        showAnywhereOption: false,
                        searchType: .destination
                    )
                }
                Spacer()
            } else if shouldShowNoResults() {
                Text("No results found")
                    .foregroundColor(.gray)
                    .padding()
                Spacer()
            } else {
                // Default state with Anywhere option
                VStack(spacing: 0) {
                    AnywhereOptionRow()
                        .onTapGesture {
                            selectAnywhereLocation()
                        }
                    
                    Spacer()
                    
                    RecentLocationSearchView(
                        onLocationSelected: { result in
                            selectLocation(result: result)
                        },
                        showAnywhereOption: false,
                        searchType: .destination
                    )
                }
                Spacer()
            }
        }
        .background(Color.white)
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
    private func handleTextChange() {
        showRecentSearches = searchText.isEmpty
        
        if !searchText.isEmpty {
            searchDebouncer.debounce {
                searchLocations(query: searchText)
            }
        } else {
            results = []
        }
    }
    
    private func selectAnywhereLocation() {
        searchViewModel.toLocation = "Anywhere"
        searchViewModel.toIataCode = ""
        dismiss()
    }
    
    private func shouldShowNoResults() -> Bool {
        return results.isEmpty && !searchText.isEmpty && !showRecentSearches
    }
    
    private func selectLocation(result: AutocompleteResult) {
        // IMPORTANT: Add to recent searches before processing
        recentSearchManager.addRecentSearch(result, searchType: .destination)
        
        // Check if this would match the current origin
        if !searchViewModel.fromIataCode.isEmpty && result.iataCode == searchViewModel.fromIataCode {
            searchError = "Origin and destination cannot be the same"
            return
        }
        
        searchViewModel.toLocation = result.cityName
        searchViewModel.toIataCode = result.iataCode
        searchText = result.cityName
        dismiss()
    }
    
    private func searchLocations(query: String) {
        guard !query.isEmpty else {
            results = []
            return
        }
        
        isSearching = true
        searchError = nil
        
        ExploreAPIService.shared.fetchAutocomplete(query: query)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                isSearching = false
                if case .failure(let error) = completion {
                    searchError = error.localizedDescription
                }
            }, receiveValue: { results in
                self.results = results
            })
            .store(in: &cancellables)
    }
}
// MARK: - Home Calendar Sheet
// MARK: - Home Calendar Sheet
struct HomeCalendarSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var searchViewModel: SharedFlightSearchViewModel
    
    var body: some View {
        CalendarView(
            fromiatacode: $searchViewModel.fromIataCode,
            toiatacode: $searchViewModel.toIataCode,
            parentSelectedDates: $searchViewModel.selectedDates,
            onAnytimeSelection: { results in
                // Clear the selected dates when anytime is selected
                searchViewModel.selectedDates = []
                dismiss()
            },
            onTripTypeChange: { newIsRoundTrip in
                searchViewModel.isRoundTrip = newIsRoundTrip
                searchViewModel.selectedTab = newIsRoundTrip ? 1 : 0
            }
        )
    }
}

// MARK: - Wrapper for Explore Results
struct ExploreResultsWrapperView: View {
    @ObservedObject var searchViewModel: SharedFlightSearchViewModel
    
    var body: some View {
        ExploreScreenWithSearchData(
            fromLocation: searchViewModel.fromLocation,
            toLocation: searchViewModel.toLocation,
            fromIataCode: searchViewModel.fromIataCode,
            toIataCode: searchViewModel.toIataCode,
            selectedDates: searchViewModel.selectedDates,
            isRoundTrip: searchViewModel.isRoundTrip,
            adultsCount: searchViewModel.adultsCount,
            childrenCount: searchViewModel.childrenCount,
            childrenAges: searchViewModel.childrenAges,
            selectedCabinClass: searchViewModel.selectedCabinClass,
            selectedTab: searchViewModel.selectedTab,
            multiCityTrips: searchViewModel.multiCityTrips
        )
        .navigationBarHidden(true)
    }
}

// MARK: - Explore Screen with Search Data
struct ExploreScreenWithSearchData: View {
    // Search parameters
    let fromLocation: String
    let toLocation: String
    let fromIataCode: String
    let toIataCode: String
    let selectedDates: [Date]
    let isRoundTrip: Bool
    let adultsCount: Int
    let childrenCount: Int
    let childrenAges: [Int?]
    let selectedCabinClass: String
    let selectedTab: Int
    let multiCityTrips: [MultiCityTrip]
    
    @StateObject private var viewModel = ExploreViewModel()
    @State private var currentSelectedTab: Int = 0
    @State private var currentIsRoundTrip: Bool = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        // Use the existing ExploreScreen body content
        VStack(spacing: 0) {
            // Custom navigation bar
            VStack(spacing: 0) {
                HStack {
                    // Back button (goes back to home)
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                            .font(.system(size: 18, weight: .semibold))
                    }
                    
                    Spacer()
                                        
                    // Centered trip type tabs
                    TripTypeTabView(selectedTab: $currentSelectedTab, isRoundTrip: $currentIsRoundTrip, viewModel: viewModel)
                        .frame(width: UIScreen.main.bounds.width * 0.55)
                                        
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .padding(.top,5)
                
                // Search card with dynamic values
                SearchCard(viewModel: viewModel, isRoundTrip: $currentIsRoundTrip, selectedTab: currentSelectedTab)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                    
                    // Animated or static stroke based on loading state
                    if viewModel.isLoading ||
                       viewModel.isLoadingFlights ||
                       (viewModel.isLoadingDetailedFlights && !viewModel.hasInitialResultsLoaded) {
                        LoadingBorderView()
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange, lineWidth: 2)
                    }
                }
            )
            .padding()
            
            ScrollView {
                VStack(alignment: .center, spacing: 16) {
                    // Show detailed flight list directly
                    ModifiedDetailedFlightListView(
                           viewModel: viewModel
                          // ADD: Pass the collapse state
                       )
                        .edgesIgnoringSafeArea(.all)
                        .background(Color(.systemBackground))
                }
                .background(Color("scroll"))
            }
            .background(Color(.systemBackground))
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            // Initialize local state with passed values
            currentSelectedTab = selectedTab
            currentIsRoundTrip = isRoundTrip
            transferSearchDataAndInitiateSearch()
        }
    }
    
    private func transferSearchDataAndInitiateSearch() {
        // Transfer all search data to the view model
        viewModel.fromLocation = fromLocation
        viewModel.toLocation = toLocation
        viewModel.fromIataCode = fromIataCode
        viewModel.toIataCode = toIataCode
        viewModel.dates = selectedDates
        viewModel.isRoundTrip = isRoundTrip
        viewModel.adultsCount = adultsCount
        viewModel.childrenCount = childrenCount
        viewModel.childrenAges = childrenAges
        viewModel.selectedCabinClass = selectedCabinClass
        viewModel.multiCityTrips = multiCityTrips
        
        // Set the selected origin and destination codes
        viewModel.selectedOriginCode = fromIataCode
        viewModel.selectedDestinationCode = toIataCode
        
        // Mark as direct search to show detailed flight list
        viewModel.isDirectSearch = true
        viewModel.showingDetailedFlightList = true
        
        // Handle multi-city vs regular search
        if selectedTab == 2 && !multiCityTrips.isEmpty {
            // Multi-city search
            viewModel.searchMultiCityFlights()
        } else {
            // Regular search - format dates for API
            if !selectedDates.isEmpty {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                
                if selectedDates.count >= 2 {
                    let sortedDates = selectedDates.sorted()
                    viewModel.selectedDepartureDatee = formatter.string(from: sortedDates[0])
                    viewModel.selectedReturnDatee = formatter.string(from: sortedDates[1])
                } else if selectedDates.count == 1 {
                    viewModel.selectedDepartureDatee = formatter.string(from: selectedDates[0])
                    if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: selectedDates[0]) {
                        viewModel.selectedReturnDatee = formatter.string(from: nextDay)
                    }
                }
            }
            
            // Initiate the regular search
            viewModel.searchFlightsForDates(
                origin: fromIataCode,
                destination: toIataCode,
                returnDate: isRoundTrip ? viewModel.selectedReturnDatee : "",
                departureDate: viewModel.selectedDepartureDatee,
                isDirectSearch: true
            )
        }
    }
}

// MARK: - Helper Classes (renamed to avoid conflicts)
class SearchDebouncer {
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?
    
    init(delay: TimeInterval) {
        self.delay = delay
    }
    
    func debounce(action: @escaping () -> Void) {
        workItem?.cancel()
        
        let workItem = DispatchWorkItem(block: action)
        self.workItem = workItem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }
}

// MARK: - Scroll Offset Preference Key
 struct ScrollOffsetPreferenceKeyy: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Custom Transition for Search Results
struct SearchResultsTransition: ViewModifier {
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isActive ? 1 : 0)
            .offset(y: isActive ? 0 : UIScreen.main.bounds.height * 0.3)
            .scaleEffect(isActive ? 1 : 0.95)
    }
}

extension AnyTransition {
    static var searchResults: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom)
                .combined(with: .opacity)
                .combined(with: .scale(scale: 0.95)),
            removal: .move(edge: .bottom)
                .combined(with: .opacity)
                .combined(with: .scale(scale: 0.95))
        )
    }
}



// MARK: - Smooth Animation Extensions
extension View {
    func smoothTransform(isActive: Bool, duration: Double = 0.6) -> some View {
        self.modifier(SmoothTransformModifier(isActive: isActive, duration: duration))
    }
}

struct SmoothTransformModifier: ViewModifier {
    let isActive: Bool
    let duration: Double
    
    func body(content: Content) -> some View {
        content
            .animation(.spring(response: duration, dampingFraction: 0.8), value: isActive)
    }
}

// MARK: - Search Card Transform States
struct SearchCardTransform {
    var scale: CGFloat = 1.0
    var offset: CGSize = .zero
    var rotation: Double = 0.0
    var opacity: Double = 1.0
    
    static let expanded = SearchCardTransform()
    static let collapsed = SearchCardTransform(scale: 0.95, offset: CGSize(width: 0, height: -20), opacity: 0.8)
    static let hidden = SearchCardTransform(scale: 0.8, offset: CGSize(width: 0, height: -100), opacity: 0)
}

// MARK: - Home Content States for Animation
enum HomeContentState {
    case visible
    case movingUp
    case hidden
    
    var offset: CGFloat {
        switch self {
        case .visible: return 0
        case .movingUp: return -50
        case .hidden: return -UIScreen.main.bounds.height
        }
    }
    
    var opacity: Double {
        switch self {
        case .visible: return 1.0
        case .movingUp: return 0.7
        case .hidden: return 0.0
        }
    }
    
    var scale: CGFloat {
        switch self {
        case .visible: return 1.0
        case .movingUp: return 0.98
        case .hidden: return 0.95
        }
    }
}

// MARK: - Results Content States
enum ResultsContentState {
    case hidden
    case appearing
    case visible
    
    var offset: CGFloat {
        switch self {
        case .hidden: return UIScreen.main.bounds.height
        case .appearing: return UIScreen.main.bounds.height * 0.3
        case .visible: return 0
        }
    }
    
    var opacity: Double {
        switch self {
        case .hidden: return 0.0
        case .appearing: return 0.5
        case .visible: return 1.0
        }
    }
    
    var scale: CGFloat {
        switch self {
        case .hidden: return 0.9
        case .appearing: return 0.95
        case .visible: return 1.0
        }
    }
}

// MARK: - Animation Timing Helper
struct AnimationTiming {
    static let searchTransform: Double = 0.6
    static let contentSlide: Double = 0.5
    static let cardExpansion: Double = 0.4
    static let resultsAppear: Double = 0.5
    
    static func spring(duration: Double) -> Animation {
        .spring(response: duration, dampingFraction: 0.8, blendDuration: 0.1)
    }
    
    static func easeInOut(duration: Double) -> Animation {
        .easeInOut(duration: duration)
    }
}

// MARK: - Transform Coordinator
@MainActor
class SearchTransformCoordinator: ObservableObject {
    @Published var isTransforming = false
    @Published var homeContentState: HomeContentState = .visible
    @Published var resultsContentState: ResultsContentState = .hidden
    @Published var searchCardTransform: SearchCardTransform = .expanded
    
    func performTransformToResults() {
        guard !isTransforming else { return }
        
        isTransforming = true
        
        // Phase 1: Scale and move search card
        withAnimation(AnimationTiming.spring(duration: AnimationTiming.cardExpansion)) {
            searchCardTransform = .collapsed
        }
        
        // Phase 2: Move home content up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(AnimationTiming.spring(duration: AnimationTiming.contentSlide)) {
                self.homeContentState = .hidden
            }
        }
        
        // Phase 3: Show results content
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(AnimationTiming.spring(duration: AnimationTiming.resultsAppear)) {
                self.resultsContentState = .visible
                self.searchCardTransform = .expanded
            }
        }
        
        // Complete transformation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isTransforming = false
        }
    }
    
    func performTransformToHome() {
        guard !isTransforming else { return }
        
        isTransforming = true
        
        // Phase 1: Hide results content
        withAnimation(AnimationTiming.spring(duration: AnimationTiming.resultsAppear)) {
            resultsContentState = .hidden
            searchCardTransform = .collapsed
        }
        
        // Phase 2: Bring back home content
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(AnimationTiming.spring(duration: AnimationTiming.contentSlide)) {
                self.homeContentState = .visible
                self.searchCardTransform = .expanded
            }
        }
        
        // Complete transformation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.isTransforming = false
        }
    }
    
    func reset() {
        isTransforming = false
        homeContentState = .visible
        resultsContentState = .hidden
        searchCardTransform = .expanded
    }
}

// MARK: - Enhanced ScrollView Offset Detection for Better Transformations
struct TransformableScrollView<Content: View>: View {
    @Binding var offset: CGFloat
    @State private var scrollViewHeight: CGFloat = 0
    let content: () -> Content
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                ZStack {
                    // Offset detection
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKeyy.self,
                                      value: proxy.frame(in: .named("scrollView")).minY)
                    }
                    .frame(height: 0)
                    
                    // Actual content
                    content()
                }
                .onPreferenceChange(ScrollOffsetPreferenceKeyy.self) { value in
                    offset = value
                }
            }
            .coordinateSpace(name: "scrollView")
            .onAppear {
                scrollViewHeight = geometry.size.height
            }
        }
    }
}

