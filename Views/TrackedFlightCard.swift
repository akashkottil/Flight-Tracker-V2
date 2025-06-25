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
    
    var body: some View {
        VStack(spacing: 16) {
            // Header section
            HStack {
                HStack(spacing: 8) {
                    // Airline logo
                    ZStack {
                        Image("FlightTrackLogo")
                            .frame(width: 24, height: 24)
                            .cornerRadius(6)
                    }
                    
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
//                                .padding(.horizontal,4)
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

// Usage example:
struct TrackedFlightCard_Previews: PreviewProvider {
    static var previews: some View {
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
            flightType: "Direct"
        )
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}
