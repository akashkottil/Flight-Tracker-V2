// Models/FlightTrack/FlightTrackModels.swift
import Foundation

// MARK: - Flight Track Airport Response Models
struct FlightTrackAirportResponse: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [FlightTrackAirport]
}

struct FlightTrackAirport: Codable, Identifiable {
    let id = UUID() // For SwiftUI List identification
    let iataCode: String
    let icaoCode: String? // Make this optional since it can be null
    let name: String
    let country: String
    let countryCode: String
    let isInternational: Bool?
    let isMajor: Bool?
    let city: String
    let location: FlightTrackLocation
    let timezone: FlightTrackTimezone
    
    enum CodingKeys: String, CodingKey {
        case iataCode = "iata_code"
        case icaoCode = "icao_code"
        case name, country
        case countryCode = "country_code"
        case isInternational = "is_international"
        case isMajor = "is_major"
        case city, location, timezone
    }
}

struct FlightTrackLocation: Codable {
    let lat: Double
    let lng: Double
}

// FIXED: Made timezone fields optional based on swagger documentation
struct FlightTrackTimezone: Codable {
    let timezone: String
    let countryCode: String?        // FIXED: x-nullable: true
    let gmt: Double?               // FIXED: x-nullable: true
    let dst: Double?               // FIXED: x-nullable: true
    
    enum CodingKeys: String, CodingKey {
        case timezone
        case countryCode = "country_code"
        case gmt, dst
    }
}

// MARK: - Airline Response Models
struct AirlineResponse: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [FlightTrackAirline]
}

struct FlightTrackAirline: Codable, Identifiable {
    let id = UUID() // For SwiftUI List identification
    let name: String
    let iataCode: String? // Make this optional since it can be null
    let icaoCode: String?
    let isInternational: Bool?
    let website: String?
    let country: String
    let callsign: String?
    let isPassenger: Bool?
    let isCargo: Bool?
    let totalAircrafts: Int?
    let averageFleetAge: Double?
    let accidentsLast5y: Int?
    let crashesLast5y: Int?
    
    enum CodingKeys: String, CodingKey {
        case name
        case iataCode = "iata_code"
        case icaoCode = "icao_code"
        case isInternational = "is_international"
        case website, country, callsign
        case isPassenger = "is_passenger"
        case isCargo = "is_cargo"
        case totalAircrafts = "total_aircrafts"
        case averageFleetAge = "average_fleet_age"
        case accidentsLast5y = "accidents_last_5y"
        case crashesLast5y = "crashes_last_5y"
    }
}

// MARK: - Sheet Source Types
enum SheetSource {
    case trackedTab
    case scheduledDeparture
    case scheduledArrival
}

enum FlightSearchType {
    case departure
    case arrival
}

// MARK: - Schedule Response Models
struct ScheduleResponse: Codable {
    let page: Int
    let totalPages: Int
    let count: Int
    let departureAirport: FlightTrackAirport?
    let arrivalAirport: FlightTrackAirport?
    let results: [ScheduleResult]
    
    enum CodingKeys: String, CodingKey {
        case page
        case totalPages = "total_pages"
        case count
        case departureAirport = "departure_airport"
        case arrivalAirport = "arrival_airport"
        case results
    }
}

struct ScheduleResult: Codable, Identifiable {
    let id = UUID()
    let airline: ScheduleAirline
    let flightNumber: String
    let status: String
    let operatedBy: String?
    let departureTime: String
    let arrivalTime: String
    let airport: ScheduleAirport
    
    enum CodingKeys: String, CodingKey {
        case airline
        case flightNumber = "flight_number"
        case status
        case operatedBy = "operated_by"
        case departureTime = "departure_time"
        case arrivalTime = "arrival_time"
        case airport
    }
}

struct ScheduleAirline: Codable {
    let name: String
    let iataCode: String?
    let icaoCode: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case iataCode = "iata_code"
        case icaoCode = "icao_code"
    }
}

struct ScheduleAirport: Codable {
    let iataCode: String
    let icaoCode: String?
    let name: String
    let city: String
    let timezone: FlightTrackTimezone
    
    enum CodingKeys: String, CodingKey {
        case iataCode = "iata_code"
        case icaoCode = "icao_code"
        case name, city, timezone
    }
}

// MARK: - Tracked Tab Search Types
enum TrackedSearchType {
    case flight    // User entered airline code
    case airport   // User entered airport
}

enum SearchEntityType {
    case airport
    case airline
    case unknown
}

// MARK: - Flight Detail Response Models
struct FlightDetailResponse: Codable {
    let result: FlightDetail
}

// FIXED: Made more fields optional based on swagger documentation
struct FlightDetail: Codable {
    let greatCircleDistance: GreatCircleDistance
    let departure: FlightLocation
    let arrival: FlightLocation
    let lastUpdated: String
    let flightIata: String
    let callSign: String?
    let status: String?             // FIXED: x-nullable: true
    let codeshareStatus: String?    // FIXED: x-nullable: true
    let isCargo: Bool?             // FIXED: x-nullable: true
    let aircraft: Aircraft?
    let airline: FlightDetailAirline
    
    enum CodingKeys: String, CodingKey {
        case greatCircleDistance = "great_circle_distance"
        case departure, arrival
        case lastUpdated = "last_updated"
        case flightIata = "flight_iata"
        case callSign = "call_sign"
        case status
        case codeshareStatus = "codeshare_status"
        case isCargo = "is_cargo"
        case aircraft, airline
    }
}

struct GreatCircleDistance: Codable {
    let meter: Double
    let km: Double
    let mile: Double
    let nm: Double
    let feet: Double
}

struct FlightLocation: Codable {
    let airport: FlightDetailAirport
    let scheduled: FlightTime
    let estimated: FlightTime?
    let taxiing: FlightTime?
    let actual: FlightTime?
    let terminal: String?
    let gate: String?
    let baggageBelt: String?
    
    enum CodingKeys: String, CodingKey {
        case airport, scheduled, estimated, taxiing, actual, terminal, gate
        case baggageBelt = "baggage_belt"
    }
}

// FIXED: Made more fields optional based on swagger documentation
struct FlightDetailAirport: Codable {
    let iataCode: String
    let icaoCode: String?            // x-nullable: true
    let name: String
    let country: String?             // FIXED: x-nullable: true
    let countryCode: String
    let isInternational: Bool?       // FIXED: x-nullable: true
    let isMajor: Bool?              // FIXED: x-nullable: true
    let city: String?               // FIXED: x-nullable: true
    let location: FlightTrackLocation
    let timezone: FlightTrackTimezone
    
    enum CodingKeys: String, CodingKey {
        case iataCode = "iata_code"
        case icaoCode = "icao_code"
        case name, country
        case countryCode = "country_code"
        case isInternational = "is_international"
        case isMajor = "is_major"
        case city, location, timezone
    }
}

struct FlightTime: Codable {
    let utc: String?
    let local: String?
}

// FIXED: Made all aircraft fields properly optional based on swagger documentation
struct Aircraft: Codable {
    let hex: String?               // FIXED: x-nullable: true (despite being marked required)
    let regNumber: String?
    let country: String?
    let built: Int?               // FIXED: Changed to Int? as swagger shows integer
    let engine: String?
    let engineCount: Int?         // FIXED: Changed to Int? as swagger shows integer
    let model: String?
    let manufacturer: String?
    let msn: String?
    let type: String?
    let category: String?
    let line: String?
    let imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case hex
        case regNumber = "reg_number"
        case country, built, engine
        case engineCount = "engine_count"
        case model, manufacturer, msn, type, category, line
        case imageUrl = "image_url"
    }
}

// FIXED: Made more airline fields optional based on swagger documentation
struct FlightDetailAirline: Codable {
    let name: String
    let iataCode: String
    let icaoCode: String?          // x-nullable: true (already optional)
    let isInternational: Bool?     // FIXED: x-nullable: true
    let website: String?           // x-nullable: true (already optional)
    let country: String?           // FIXED: x-nullable: true
    let callsign: String?          // x-nullable: true (already optional)
    let isPassenger: Bool?
    let isCargo: Bool?
    let totalAircrafts: Int?
    let averageFleetAge: Double?
    let accidentsLast5y: Int?
    let crashesLast5y: Int?
    
    enum CodingKeys: String, CodingKey {
        case name
        case iataCode = "iata_code"
        case icaoCode = "icao_code"
        case isInternational = "is_international"
        case website, country, callsign
        case isPassenger = "is_passenger"
        case isCargo = "is_cargo"
        case totalAircrafts = "total_aircrafts"
        case averageFleetAge = "average_fleet_age"
        case accidentsLast5y = "accidents_last_5y"
        case crashesLast5y = "crashes_last_5y"
    }
}
