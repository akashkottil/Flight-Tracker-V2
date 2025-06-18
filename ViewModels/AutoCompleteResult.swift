import Foundation

struct AutocompleteItem: Codable, Identifiable {
    var id: String { iataCode }
    let iataCode: String
    let airportName: String
    let type: String
    let displayName: String
    let cityName: String
    let countryName: String
    let countryCode: String
    let imageUrl: String
    let coordinates: Coordinates
    
    struct Coordinates: Codable {
        let latitude: String
        let longitude: String
    }
    
    enum CodingKeys: String, CodingKey {
        case iataCode
        case airportName
        case type
        case displayName
        case cityName
        case countryName
        case countryCode
        case imageUrl
        case coordinates
    }
}

//struct AutocompleteResponse: Codable {
//    let data: [AutocompleteItem]
//}
