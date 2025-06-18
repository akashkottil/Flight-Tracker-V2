import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var placemark: CLPlacemark?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        isLoading = true
        errorMessage = nil
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            isLoading = false
            errorMessage = "Location access is restricted. Please enable it in settings."
        @unknown default:
            isLoading = false
            errorMessage = "Unexpected authorization status."
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            currentLocation = location
            fetchPlacemark(for: location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoading = false
        errorMessage = error.localizedDescription
    }
    
    private func fetchPlacemark(for location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                if let placemark = placemarks?.first {
                    self?.placemark = placemark
                }
            }
        }
    }
    
    func createAutoCompleteItem() -> AutocompleteItem? {
        guard let placemark = placemark,
              let location = currentLocation else {
            return nil
        }
        
        let city = placemark.locality ?? "Unknown City"
        let country = placemark.country ?? "Unknown Country"
        let iata = String(city.prefix(3)).uppercased() // Approximation for demo
        
        return AutocompleteItem(
            iataCode: iata,
            airportName: "Nearest Airport",
            type: "city",
            displayName: "\(city), \(country)",
            cityName: city,
            countryName: country,
            countryCode: placemark.isoCountryCode ?? "??",
            imageUrl: "",
            coordinates: AutocompleteItem.Coordinates(
                latitude: String(location.coordinate.latitude),
                longitude: String(location.coordinate.longitude)
            )
        )
    }
}
