//
//  AirlinesInfo.swift
//  AllFlights
//
//  Created by Akash Kottil on 21/07/25.
//
import SwiftUI

struct AirlinesInfo: View {
    let airline: FlightDetailAirline
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Airline Information")
                .font(.system(size: 18, weight: .semibold))
                .padding(.top, 15)
            
            HStack(spacing: 12) {
                AirlineLogoView(
                    iataCode: airline.iataCode,
                    fallbackImage: "FlightTrackLogo",
                    size: 34
                )
                Text(airline.name)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
            }
            
            HStack(spacing: 8) {
                VStack(spacing: 8) {
                    Text("ATC Callsign")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                    Text(airline.callsign ?? "N/A")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
                
                VStack(spacing: 8) {
                    Text("Fleet Size")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                    Text("\(airline.totalAircrafts ?? 0)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
                
                VStack(spacing: 8) {
                    Text("Fleet Age")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                    Text("\(String(format: "%.1f", airline.averageFleetAge ?? 0.0))y")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
            }
            
            Text("Flight performance")
                .font(.system(size: 18, weight: .semibold))
                .padding(.top, 8)
            
            HStack {
                Text("On-time")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                Text("90%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            CustomProgressBar(progress: 0.9)
                .frame(height: 8)
                .padding(.vertical, 4)
            
            Text("Based on data for the past 10 days")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
                .padding(.bottom, 8)
        }
        .padding(.vertical, 5)
    }
}
