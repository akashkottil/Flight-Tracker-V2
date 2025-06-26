// Enhanced TrackedDetailsScreen.swift - Updated to use TrackedFlightCard with API data mapping

import SwiftUI

enum TrackedSearchResultType {
    case flight
    case airport
}

struct TrackedDetailsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Namespace private var searchCardNamespace
    
    // Accept dynamic data instead of hardcoded
    let flightDetail: FlightDetail?
    let scheduleResults: [ScheduleResult]
    let searchType: TrackedSearchResultType
    
    // Animation states
    @State private var isAppearing = false
    @State private var cardsAppeared = false
    
    // Computed properties for dynamic header values
    private var fromText: String {
        if let flightDetail = flightDetail {
            return flightDetail.departure.airport.iataCode
        } else if let firstFlight = scheduleResults.first {
            // Handle optional airport field
            return firstFlight.airport?.iataCode ?? "DEP"
        } else {
            return "---"
        }
    }
    
    private var toText: String {
        if let flightDetail = flightDetail {
            return flightDetail.arrival.airport.iataCode
        } else if !scheduleResults.isEmpty {
            return "Flights"
        } else {
            return "---"
        }
    }
    
    private var dateText: String {
        if let flightDetail = flightDetail {
            return formatHeaderDate(flightDetail.departure.scheduled.local)
        } else if let firstFlight = scheduleResults.first {
            return formatHeaderDate(firstFlight.departureTime)
        } else {
            return "--"
        }
    }
    
    private var passengerCount: Int {
        return 1 // Default value, you can make this dynamic if needed
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Use TrackCollapseHeader with animation
            TrackCollapseHeader(
                fromText: fromText,
                toText: toText,
                dateText: dateText,
                passengerCount: passengerCount,
                searchCardNamespace: searchCardNamespace,
                onTap: {
                    // Handle tap action - could expand/collapse or navigate
                    print("Header tapped")
                },
                handleBackNavigation: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        dismiss()
                    }
                },
                shouldShowBackButton: true
            )
            .opacity(isAppearing ? 1 : 0)
            .offset(y: isAppearing ? 0 : -50)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: isAppearing)
            
            // Main Content with enhanced animations
            ScrollView {
                LazyVStack(spacing: 12) {
                    if searchType == .flight, let flightDetail = flightDetail {
                        // UPDATED: Use TrackedFlightCard instead of SingleFlightCard
                        TrackedFlightCard(
                            airlineLogo: "FlightTrackLogo",
                            airlineName: flightDetail.airline.name,
                            flightNumber: flightDetail.flightIata,
                            status: flightDetail.status ?? "Unknown",
                            departureTime: formatTime(flightDetail.departure.scheduled.local),
                            departureAirport: flightDetail.departure.airport.iataCode,
                            departureDate: formatDate(flightDetail.departure.scheduled.local),
                            arrivalTime: formatTime(flightDetail.arrival.scheduled.local),
                            arrivalAirport: flightDetail.arrival.airport.iataCode,
                            arrivalDate: formatDate(flightDetail.arrival.scheduled.local),
                            duration: calculateDuration(
                                departure: flightDetail.departure.scheduled.local,
                                arrival: flightDetail.arrival.scheduled.local
                            ),
                            flightType: "Direct" // You can enhance this logic based on actual data
                        )
                        .opacity(cardsAppeared ? 1 : 0)
                        .offset(y: cardsAppeared ? 0 : 30)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: cardsAppeared)
                        
                    } else if searchType == .airport, !scheduleResults.isEmpty {
                        // Show multiple flights from schedule with staggered animation
                        ForEach(scheduleResults.indices, id: \.self) { index in
                            // UPDATED: Use TrackedFlightCard for schedule results too
                            TrackedFlightCard(
                                airlineLogo: "FlightTrackLogo",
                                airlineName: scheduleResults[index].airline.name,
                                flightNumber: scheduleResults[index].flightNumber,
                                status: scheduleResults[index].status.capitalized,
                                departureTime: formatScheduleTime(scheduleResults[index].departureTime),
                                departureAirport: "DEP", // You might want to add departure airport to ScheduleResult
                                departureDate: formatScheduleDate(scheduleResults[index].departureTime),
                                arrivalTime: formatScheduleTime(scheduleResults[index].arrivalTime),
                                arrivalAirport: scheduleResults[index].airport?.iataCode ?? "ARR",
                                arrivalDate: formatScheduleDate(scheduleResults[index].arrivalTime),
                                duration: calculateScheduleDuration(
                                    departure: scheduleResults[index].departureTime,
                                    arrival: scheduleResults[index].arrivalTime
                                ),
                                flightType: "Direct",
                                airlineIataCode: scheduleResults[index].airline.iataCode // ✅ Use IATA code from API response
                            )
                            .opacity(cardsAppeared ? 1 : 0)
                            .offset(y: cardsAppeared ? 0 : 30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3 + Double(index) * 0.1), value: cardsAppeared)
                        }
                    } else {
                        // Empty state with animation
                        emptyStateView
                            .opacity(cardsAppeared ? 1 : 0)
                            .offset(y: cardsAppeared ? 0 : 30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: cardsAppeared)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
        }
        .navigationBarHidden(true)
        .onAppear {
            // Trigger animations on appear
            withAnimation {
                isAppearing = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation {
                    cardsAppeared = true
                }
            }
        }
    }
    
    // MARK: - Enhanced Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "airplane.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
                .scaleEffect(cardsAppeared ? 1.0 : 0.5)
                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: cardsAppeared)
            
            VStack(spacing: 8) {
                Text("No flight data available")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text("Please try searching again with different criteria")
                    .font(.subheadline)
                    .foregroundColor(.gray.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .opacity(cardsAppeared ? 1 : 0)
            .animation(.easeInOut(duration: 0.4).delay(0.5), value: cardsAppeared)
            
            Spacer()
        }
        .frame(height: 400)
    }
    
    // MARK: - Helper Methods for FlightDetail API Data
    
    private func formatTime(_ timeString: String?) -> String {
        guard let timeString = timeString else { return "--:--" }
        
        let formatter = DateFormatter()
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss"
        ]
        
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: timeString) {
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                return timeFormatter.string(from: date)
            }
        }
        return timeString
    }
    
    private func formatDate(_ timeString: String?) -> String {
        guard let timeString = timeString else { return "--" }
        
        let formatter = DateFormatter()
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss"
        ]
        
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: timeString) {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd MMM"
                return dateFormatter.string(from: date)
            }
        }
        return timeString
    }
    
    private func formatHeaderDate(_ timeString: String?) -> String {
        guard let timeString = timeString else { return "--" }
        
        let formatter = DateFormatter()
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss"
        ]
        
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: timeString) {
                let headerFormatter = DateFormatter()
                headerFormatter.dateFormat = "dd MMM"
                return headerFormatter.string(from: date)
            }
        }
        return "--"
    }
    
    private func calculateDuration(departure: String?, arrival: String?) -> String {
        guard let depString = departure, let arrString = arrival else { return "--h --min" }
        
        let formatter = DateFormatter()
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss"
        ]
        
        var depDate: Date?
        var arrDate: Date?
        
        for format in formats {
            formatter.dateFormat = format
            if depDate == nil {
                depDate = formatter.date(from: depString)
            }
            if arrDate == nil {
                arrDate = formatter.date(from: arrString)
            }
            if depDate != nil && arrDate != nil {
                break
            }
        }
        
        guard let departureDate = depDate, let arrivalDate = arrDate else { return "--h --min" }
        
        let duration = arrivalDate.timeIntervalSince(departureDate)
        let hours = Int(duration) / 3600
        let minutes = Int(duration.truncatingRemainder(dividingBy: 3600)) / 60
        
        return "\(hours)h \(minutes)min"
    }
    
    // MARK: - Helper Methods for ScheduleResult API Data
    
    private func formatScheduleTime(_ timeString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        if let date = formatter.date(from: timeString) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            return timeFormatter.string(from: date)
        }
        return timeString
    }
    
    private func formatScheduleDate(_ timeString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        if let date = formatter.date(from: timeString) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd MMM"
            return dateFormatter.string(from: date)
        }
        return timeString
    }
    
    private func calculateScheduleDuration(departure: String, arrival: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        guard let depDate = formatter.date(from: departure),
              let arrDate = formatter.date(from: arrival) else {
            return "--h --min"
        }
        
        let duration = arrDate.timeIntervalSince(depDate)
        let hours = Int(duration) / 3600
        let minutes = Int(duration.truncatingRemainder(dividingBy: 3600)) / 60
        
        return "\(hours)h \(minutes)min"
    }
}

// MARK: - Convenience Initializers
extension TrackedDetailsScreen {
    
    // Convenience initializer for flight detail only
    init(withFlightDetail flightDetail: FlightDetail) {
        self.flightDetail = flightDetail
        self.scheduleResults = []
        self.searchType = .flight
    }
    
    // Convenience initializer for schedule results only
    init(withScheduleResults scheduleResults: [ScheduleResult]) {
        self.flightDetail = nil
        self.scheduleResults = scheduleResults
        self.searchType = .airport
    }
}

// MARK: - Preview
struct TrackedDetailsScreen_Previews: PreviewProvider {
    static var previews: some View {
        // Example with empty data
        TrackedDetailsScreen(
            flightDetail: nil,
            scheduleResults: [],
            searchType: .flight
        )
    }
}
