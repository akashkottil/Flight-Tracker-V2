import Foundation

// Trip model to handle multiple trips for multi-city
struct Trip: Identifiable {
    var id = UUID()
    var originCode: String
    var originCity: String
    var destinationCode: String
    var destinationCity: String
    var date: Date
    
    static func createDefault() -> Trip {
        return Trip(
            originCode: "COK",
            originCity: "Cochin",
            destinationCode: "DXB",
            destinationCity: "Dubai",
            date: Date()
        )
    }
}

// Enum for trip types
enum TripType: String, CaseIterable {
    case returnTrip = "Return"
    case oneWay = "One way"
    case multiCity = "Multi city"
}

// Enum for travel classes
enum TravelClass: String, CaseIterable {
    case economy = "Economy"
    case business = "Business"
    case firstClass = "First Class"
}
