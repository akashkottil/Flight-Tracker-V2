import SwiftUI

struct TrackedFlightCard: View {
    let airlineLogo: String
    let airlineName: String
    let flightNumber: String
    let status: String
    let departureTime: String
    let departureAirport: String
    let departureDate: String
    let arrivalTime: String
    let arrivalAirport: String
    let arrivalDate: String
    let duration: String
    let flightType: String
    
    // ✅ CHANGE: Make this a stored property instead of computed
    let airlineIataCode: String?
    
    // ✅ UPDATE: Add airlineIataCode parameter to initializer
    init(
        airlineLogo: String,
        airlineName: String,
        flightNumber: String,
        status: String,
        departureTime: String,
        departureAirport: String,
        departureDate: String,
        arrivalTime: String,
        arrivalAirport: String,
        arrivalDate: String,
        duration: String,
        flightType: String,
        airlineIataCode: String? = nil
    ) {
        self.airlineLogo = airlineLogo
        self.airlineName = airlineName
        self.flightNumber = flightNumber
        self.status = status
        self.departureTime = departureTime
        self.departureAirport = departureAirport
        self.departureDate = departureDate
        self.arrivalTime = arrivalTime
        self.arrivalAirport = arrivalAirport
        self.arrivalDate = arrivalDate
        self.duration = duration
        self.flightType = flightType
        // ✅ NOW THIS WORKS: Assign to stored property
        self.airlineIataCode = airlineIataCode
    }
    
    // ✅ NEW: Computed property to get the best IATA code available
    private var displayAirlineIataCode: String? {
        // Use provided IATA code first, otherwise extract from flight number
        return airlineIataCode ?? flightNumber.airlineIataCode
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header section
            HStack {
                HStack(spacing: 8) {
                    // ✅ USE: displayAirlineIataCode instead of airlineIataCode
                    AirlineLogoView(
                        iataCode: displayAirlineIataCode,
                        fallbackImage: "FlightTrackLogo",
                        size: 24
                    )
                    
                    Text(airlineName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("• \(flightNumber)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Status badge
                VStack {
                    Text(status)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.rainForest)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.rainForest, lineWidth: 1)
                        )
                        .cornerRadius(6)
                }
            }
            
            // Flight timeline
            HStack(alignment: .center) {
                // Departure info
                VStack(alignment: .leading, spacing: 2) {
                    Text(departureTime)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Text(departureAirport)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                        Text(departureDate)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Flight path visualization
                VStack(spacing: 4) {
                    HStack{
                        // Departure circle
                        Circle()
                          .stroke(Color.primary, lineWidth: 1)
                          .frame(width: 8, height: 8)
                        
                        Rectangle()
                          .fill(Color.primary)
                          .frame(width: 10, height: 1)
                          .padding(.top, 4)
                          .padding(.bottom, 4)
                        
                        HStack {
                            Text(duration)
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                                .padding(.vertical,3)
                        }
                        .frame(width: 70)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black, lineWidth: 1)
                        )
                        
                        Rectangle()
                          .fill(Color.primary)
                          .frame(width: 10, height: 1)
                          .padding(.top, 4)
                          .padding(.bottom, 4)
                        
                        Circle()
                          .stroke(Color.primary, lineWidth: 1)
                          .frame(width: 8, height: 8)
                    }
                    
                    Text(flightType)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                // Arrival info
                VStack(alignment: .trailing, spacing: 2) {
                    Text(arrivalTime)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Text(arrivalAirport)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                        Text(arrivalDate)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// Usage examples:
struct TrackedFlightCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Example 1: With explicit IATA code
            TrackedFlightCard(
                airlineLogo: "6E",
                airlineName: "Indigo",
                flightNumber: "6E 6083",
                status: "Scheduled",
                departureTime: "17:10",
                departureAirport: "COK",
                departureDate: "10 Apr",
                arrivalTime: "18:30",
                arrivalAirport: "CNN",
                arrivalDate: "10 Apr",
                duration: "12h 30m",
                flightType: "Direct",
                airlineIataCode: "6E" // ✅ Explicit IATA code provided
            )
            
            // Example 2: Without IATA code (will extract from flight number)
            TrackedFlightCard(
                airlineLogo: "AI",
                airlineName: "Air India",
                flightNumber: "AI 131",
                status: "On Time",
                departureTime: "09:15",
                departureAirport: "DEL",
                departureDate: "10 Apr",
                arrivalTime: "11:45",
                arrivalAirport: "BOM",
                arrivalDate: "10 Apr",
                duration: "2h 30m",
                flightType: "Direct"
                // ✅ No airlineIataCode parameter - will extract "AI" from flight number
            )
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}
