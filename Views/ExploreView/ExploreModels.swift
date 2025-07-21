import Foundation



// MARK: - Updated Models for the new API Response Structure

struct ExploreApiResponse: Codable {
    let origin: String
    let currency: CurrencyDetail
    let data: [ExploreDestinationData]
}

struct CurrencyDetail: Codable {
    let code: String
    let symbol: String
    let thousandsSeparator: String
    let decimalSeparator: String
    let symbolOnLeft: Bool
    let spaceBetweenAmountAndSymbol: Bool
    let decimalDigits: Int
    
    enum CodingKeys: String, CodingKey {
        case code
        case symbol
        case thousandsSeparator = "thousands_separator"
        case decimalSeparator = "decimal_separator"
        case symbolOnLeft = "symbol_on_left"
        case spaceBetweenAmountAndSymbol = "space_between_amount_and_symbol"
        case decimalDigits = "decimal_digits"
    }
}

struct ExploreDestinationData: Codable {
    let price: Int
    let location: ExploreLocationData
    let is_direct: Bool
}

struct ExploreLocationData: Codable {
    let entityId: String
    let name: String
    let iata: String
}

// Filter request model that matches the API requirements
struct FlightFilterRequest: Codable {
    var durationMax: Int?
    var stopCountMax: Int?
    var arrivalDepartureRanges: [ArrivalDepartureRange]?
    var iataCodesExclude: [String]?
    var iataCodesInclude: [String]?
    var sortBy: String?
    var sortOrder: String?
    var agencyExclude: [String]?
    var agencyInclude: [String]?
    var priceMin: Int?
    var priceMax: Int?
    
    enum CodingKeys: String, CodingKey {
        case durationMax = "duration_max"
        case stopCountMax = "stop_count_max"
        case arrivalDepartureRanges = "arrival_departure_ranges"
        case iataCodesExclude = "iata_codes_exclude"
        case iataCodesInclude = "iata_codes_include"
        case sortBy = "sort_by"
        case sortOrder = "sort_order"
        case agencyExclude = "agency_exclude"
        case agencyInclude = "agency_include"
        case priceMin = "price_min"
        case priceMax = "price_max"
    }
}

struct ArrivalDepartureRange: Codable {
    var arrival: TimeRange?
    var departure: TimeRange?
}

struct TimeRange: Codable {
    var min: Int?
    var max: Int?
}

struct MultiCityTrip: Identifiable, Codable {
    var id = UUID()
    var fromLocation: String = ""
    var fromIataCode: String = ""
    var toLocation: String = ""
    var toIataCode: String = ""
    var date: Date = Date()
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM"
        return formatter.string(from: date)
    }
    
    var compactDisplayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E,d MMM" // Produces "Sat,7 Jun" format
        return formatter.string(from: date)
    }
    
    // Optional: Custom initializer to maintain existing functionality
    init(fromLocation: String = "", fromIataCode: String = "",
         toLocation: String = "", toIataCode: String = "", date: Date = Date()) {
        self.id = UUID()
        self.fromLocation = fromLocation
        self.fromIataCode = fromIataCode
        self.toLocation = toLocation
        self.toIataCode = toIataCode
        self.date = date
    }
}

// MARK: - Search API Response Models
struct SearchResponse: Codable {
    let searchId: String
    let language: String
    let currency: String
    let mode: Int
    let currencyInfo: CurrencyInfo
    
    enum CodingKeys: String, CodingKey {
        case searchId = "search_id"
        case language
        case currency
        case mode
        case currencyInfo = "currency_info"
    }
}

struct CurrencyInfo: Codable {
    let code: String
    let symbol: String
    let thousandsSeparator: String
    let decimalSeparator: String
    let symbolOnLeft: Bool
    let spaceBetweenAmountAndSymbol: Bool
    let decimalDigits: Int
    
    enum CodingKeys: String, CodingKey {
        case code
        case symbol
        case thousandsSeparator = "thousands_separator"
        case decimalSeparator = "decimal_separator"
        case symbolOnLeft = "symbol_on_left"
        case spaceBetweenAmountAndSymbol = "space_between_amount_and_symbol"
        case decimalDigits = "decimal_digits"
    }
}

// MARK: - Poll API Response Models
struct FlightPollResponse: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let cache: Bool
    let passengerCount: Int
    let minDuration: Int
    let maxDuration: Int
    let minPrice: Double
    let maxPrice: Double
    let airlines: [PollAirline]
    let agencies: [Agency]
    let cheapestFlight: FlightSummary
    let bestFlight: FlightSummary
    let fastestFlight: FlightSummary
    let results: [FlightDetailResult]
    
    enum CodingKeys: String, CodingKey {
        case count
        case next
        case previous
        case cache
        case passengerCount = "passenger_count"
        case minDuration = "min_duration"
        case maxDuration = "max_duration"
        case minPrice = "min_price"
        case maxPrice = "max_price"
        case airlines
        case agencies
        case cheapestFlight = "cheapest_flight"
        case bestFlight = "best_flight"
        case fastestFlight = "fastest_flight"
        case results
    }
}

struct PollAirline: Codable {
    let airlineName: String
    let airlineIata: String
    let airlineLogo: String
}

struct Agency: Codable {
    let code: String
    let name: String
    let image: String
}

struct FlightSummary: Codable {
    let price: Double
    let duration: Int
}

struct FlightDetailResult: Codable {
    let id: String
    let totalDuration: Int
    let minPrice: Double
    let maxPrice: Double
    let legs: [FlightLegDetail]
    let providers: [FlightProvider]
    let isBest: Bool
    let isCheapest: Bool
    let isFastest: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case totalDuration = "total_duration"
        case minPrice = "min_price"
        case maxPrice = "max_price"
        case legs
        case providers
        case isBest = "is_best"
        case isCheapest = "is_cheapest"
        case isFastest = "is_fastest"
    }
}

struct FlightLegDetail: Codable {
    let arriveTimeAirport: Int
    let departureTimeAirport: Int
    let duration: Int
    let origin: String
    let originCode: String
    let destination: String
    let destinationCode: String
    let stopCount: Int
    let segments: [FlightSegment]
    
    enum CodingKeys: String, CodingKey {
        case arriveTimeAirport
        case departureTimeAirport
        case duration
        case origin
        case originCode
        case destination
        case destinationCode
        case stopCount = "stopCount"
        case segments
    }
}

struct FlightSegment: Codable {
    let id: String
    let arriveTimeAirport: Int
    let departureTimeAirport: Int
    let duration: Int
    let flightNumber: String
    let airlineName: String
    let airlineIata: String
    let airlineLogo: String
    let originCode: String
    let origin: String
    let destinationCode: String
    let destination: String
    let arrivalDayDifference: Int
    let wifi: Bool
    let cabinClass: String?
    let aircraft: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case arriveTimeAirport
        case departureTimeAirport
        case duration
        case flightNumber
        case airlineName
        case airlineIata
        case airlineLogo
        case originCode
        case origin
        case destinationCode
        case destination
        case arrivalDayDifference = "arrival_day_difference"
        case wifi
        case cabinClass
        case aircraft
    }
}

struct FlightProvider: Codable {
    let isSplit: Bool
    let transferType: String
    let price: Double
    let splitProviders: [SplitProvider]
    
    enum CodingKeys: String, CodingKey {
        case isSplit
        case transferType
        case price
        case splitProviders
    }
}

struct SplitProvider: Codable {
    let name: String
    let imageURL: String
    let price: Double
    let deeplink: String
    let rating: Double?
    let ratingCount: Int?
    let fareFamily: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case imageURL = "imageURL"
        case price
        case deeplink
        case rating
        case ratingCount
        case fareFamily
    }
}


// MARK: - Autocomplete Models
struct AutocompleteCoordinates: Codable {
    let latitude: String
    let longitude: String
}

struct AutocompleteResult: Codable, Identifiable {
    let iataCode: String
    let airportName: String
    let type: String
    let displayName: String
    let cityName: String
    let countryName: String
    let countryCode: String
    let imageUrl: String
    let coordinates: AutocompleteCoordinates
    
    var id: String { iataCode }
}

struct AutocompleteResponse: Codable {
    let data: [AutocompleteResult]
    let language: String
}
// MARK: - Flight API Response Models
struct Location: Codable {
    let iata: String
    let name: String
    let country: String
    
    // Add custom initializer to handle empty strings
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        iata = try container.decode(String.self, forKey: .iata)
        name = try container.decode(String.self, forKey: .name)
        country = try container.decode(String.self, forKey: .country)
    }
}

struct Airline: Codable {
    let iata: String
    let name: String
    let logo: String
    
    // Add custom initializer to handle empty strings
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        iata = try container.decode(String.self, forKey: .iata)
        name = try container.decode(String.self, forKey: .name)
        logo = try container.decode(String.self, forKey: .logo)
    }
}

struct FlightLeg: Codable {
    let origin: Location
    let destination: Location
    let airline: Airline
    let departure: Int?  // Make this optional to handle null values
    let departure_datetime: String?  // Make this optional too
    let direct: Bool
    
    // Add custom initializer to handle potential nulls
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        origin = try container.decode(Location.self, forKey: .origin)
        destination = try container.decode(Location.self, forKey: .destination)
        airline = try container.decode(Airline.self, forKey: .airline)
        direct = try container.decode(Bool.self, forKey: .direct)
        
        // Handle potentially null values
        departure = try container.decodeIfPresent(Int.self, forKey: .departure) ?? 0
        departure_datetime = try container.decodeIfPresent(String.self, forKey: .departure_datetime)
    }
    
    enum CodingKeys: String, CodingKey {
        case origin
        case destination
        case airline
        case departure
        case departure_datetime
        case direct
    }
}

struct PriceStats: Codable {
    let mean: Double
    let std_dev: Double
    let lower_threshold: Double
    let upper_threshold: Double
}

struct FlightResult: Codable, Identifiable {
    let date: Int
    let price: Int
    let currency: String
    let outbound: FlightLeg
    let inbound: FlightLeg?
    let price_category: String
    
    var id: String {
        return UUID().uuidString
    }
}

struct FlightSearchResponse: Codable {
    let price_stats: PriceStats
    let results: [FlightResult]
}

// MARK: - API Models
struct ExploreLocation: Codable {
    let entityId: String
    let name: String
    let iata: String
}

struct ExploreDestination: Codable, Identifiable {
    let price: Int
    let location: ExploreLocation
    let is_direct: Bool
    
    var id: String {
        return location.entityId
    }
}
