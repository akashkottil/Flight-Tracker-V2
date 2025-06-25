//
//  AirlineLogoView.swift
//  AllFlights
//
//  Created by Akash Kottil on 25/06/25.
//


// MARK: - AirlineLogoView.swift
// Create this as a new file: Views/Components/AirlineLogoView.swift

import SwiftUI

struct AirlineLogoView: View {
    let iataCode: String?
    let fallbackImage: String
    let size: CGFloat
    
    init(iataCode: String?, fallbackImage: String = "FlightTrackLogo", size: CGFloat = 34) {
        self.iataCode = iataCode
        self.fallbackImage = fallbackImage
        self.size = size
    }
    
    var body: some View {
        Group {
            if let iataCode = iataCode?.uppercased(), !iataCode.isEmpty {
                if Bundle.main.path(forResource: iataCode, ofType: "png", inDirectory: "Resource/airlinesicons") != nil {
                    // Airline-specific logo exists
                    Image(iataCode, bundle: .main)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    // Fallback to default logo
                    Image(fallbackImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            } else {
                // No IATA code provided, use fallback
                Image(fallbackImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        .frame(width: size, height: size)
        .cornerRadius(6)
    }
}

// MARK: - Alternative approach using Image extension
extension Image {
    static func airlineLogo(iataCode: String?, fallback: String = "FlightTrackLogo") -> Image {
        guard let iataCode = iataCode?.uppercased(), !iataCode.isEmpty else {
            return Image(fallback)
        }
        
        // Check if the airline-specific image exists
        if Bundle.main.path(forResource: iataCode, ofType: "png", inDirectory: "Resource/airlinesicons") != nil {
            return Image(iataCode, bundle: .main)
        } else {
            return Image(fallback)
        }
    }
}

// MARK: - Updated TrackedFlightCard.swift
struct UpdatedTrackedFlightCard: View {
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
    
    // ADDED: Extract IATA code from airline data
    private var airlineIataCode: String? {
        // Extract IATA code from flight number (e.g., "6E 703" -> "6E")
        let components = flightNumber.components(separatedBy: " ")
        if let firstComponent = components.first, firstComponent.count <= 3 {
            return firstComponent
        }
        // Alternative: extract from airline name if it contains code
        return nil
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header section
            HStack {
                HStack(spacing: 8) {
                    // UPDATED: Dynamic airline logo
                    AirlineLogoView(
                        iataCode: airlineIataCode,
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
            
            // Flight timeline (rest of the code remains the same)
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

// MARK: - Usage Examples for different views

// For FlightDetailScreen.swift - Update the header section:
struct FlightDetailHeaderExample: View {
    let flight: FlightDetail
    
    var body: some View {
        HStack{
            // UPDATED: Use dynamic airline logo
            AirlineLogoView(
                iataCode: flight.airline.iataCode,
                fallbackImage: "FlightTrackLogo",
                size: 34
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(flight.flightIata)
                    .font(.headline)
                    .fontWeight(.semibold)
                Text(flight.airline.name)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text(flight.status ?? "Unknown")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.rainForest)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.rainForest, lineWidth: 1)
                )
        }
    }
}

// For FlightTracker.swift - Update flight row content:
struct FlightRowContentExample: View {
    let flight: FlightInfo
    let schedule: ScheduleResult // When using API data
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // UPDATED: Use dynamic airline logo with API data
            AirlineLogoView(
                iataCode: schedule.airline.iataCode,
                fallbackImage: "FlightTrackLogo",
                size: 60
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(flight.flightNumber)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                
                Text(flight.airline)
                    .font(.system(size: 14))
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
            }
            
            // ... rest of the row content
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Helper function for parsing IATA codes from flight numbers
extension String {
    var airlineIataCode: String? {
        // Parse flight number to extract airline code
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle space-separated format (e.g., "6E 703")
        if trimmed.contains(" ") {
            let components = trimmed.components(separatedBy: " ")
            if let firstComponent = components.first, firstComponent.count >= 2 && firstComponent.count <= 3 {
                return firstComponent
            }
        }
        
        // Handle no-space format (e.g., "6E703")
        if trimmed.count >= 3 {
            let airlineCode = String(trimmed.prefix(2))
            // Validate that it contains at least one letter
            if airlineCode.contains(where: { $0.isLetter }) {
                return airlineCode
            }
        }
        
        return nil
    }
}
