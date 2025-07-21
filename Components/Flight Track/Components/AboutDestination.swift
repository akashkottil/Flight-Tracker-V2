//
//  AboutDestination.swift
//  AllFlights
//
//  Created by Akash Kottil on 21/07/25.
//

import SwiftUI

struct AboutDestination: View {
    let flight: FlightDetail
    
    var body: some View {
        VStack(alignment: .leading){
            Text("About your destination")
                .font(.system(size: 18, weight: .semibold))
                .padding(.vertical,10)
            HStack{
                VStack(alignment: .leading){
                    Text("29°C") // You might want to integrate weather API
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Weather in \(flight.arrival.airport.city ?? flight.arrival.airport.name)")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Image("Cloud")
            }
            .padding()
            .background(.blue)
            .cornerRadius(20)
            
            HStack {
                VStack(alignment: .leading,  spacing: 6) {
                    Text("Time Zone Change")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.black.opacity(0.7))
                    Text("+ 1h 39 min")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.black)
                    Text("Arrival at 18:00 Wed,30 May is 19:39 at Kochi")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.black.opacity(0.7))
                }
                Spacer()
            }
            .padding()
            
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.black.opacity(0.3), lineWidth: 1.4)
            )
            .cornerRadius(20)
        }
    }
}
