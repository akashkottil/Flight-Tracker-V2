// Enhanced TrackedDetailsScreen.swift - Complete updated version with animations and optional airport handling

import SwiftUI

enum TrackedSearchResultType {
    case flight
    case airport
}

struct TrackedDetailsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Namespace private var searchCardNamespace
    
    // ADDED: Accept dynamic data instead of hardcoded
    let flightDetail: FlightDetail?
    let scheduleResults: [ScheduleResult]
    let searchType: TrackedSearchResultType
    
    // ADDED: Animation states
    @State private var isAppearing = false
    @State private var cardsAppeared = false
    
    // ADDED: Computed properties for dynamic header values
    private var fromText: String {
        if let flightDetail = flightDetail {
            return flightDetail.departure.airport.iataCode
        } else if let firstFlight = scheduleResults.first {
            // FIXED: Handle optional airport field
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
            // UPDATED: Use TrackCollapseHeader with animation
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
                        // Show single flight detail with animation
                        SingleFlightCard(flightDetail: flightDetail)
                            .opacity(cardsAppeared ? 1 : 0)
                            .offset(y: cardsAppeared ? 0 : 30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: cardsAppeared)
                    } else if searchType == .airport, !scheduleResults.isEmpty {
                        // Show multiple flights from schedule with staggered animation
                        ForEach(scheduleResults.indices, id: \.self) { index in
                            ScheduleFlightCard(scheduleResult: scheduleResults[index])
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
    
    // MARK: - Helper Methods
    
    private func formatHeaderDate(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "--" }
        
        let formatter = DateFormatter()
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss"
        ]
        
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                let headerFormatter = DateFormatter()
                headerFormatter.dateFormat = "dd MMM"
                return headerFormatter.string(from: date)
            }
        }
        return "--"
    }
}

// MARK: - Single Flight Detail Card (for flight number search) - Enhanced with Animation
struct SingleFlightCard: View {
    let flightDetail: FlightDetail
    @State private var isAnimated = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with airline info and status
            HStack {
                HStack(spacing: 8) {
                    // Airline logo with animation
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue)
                            .frame(width: 28, height: 28)
                            .scaleEffect(isAnimated ? 1.0 : 0.8)
                        
                        Text(flightDetail.airline.iataCode.prefix(2))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .opacity(isAnimated ? 1.0 : 0.0)
                    }
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: isAnimated)
                    
                    Text("\(flightDetail.airline.name) • \(flightDetail.flightIata)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .opacity(isAnimated ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.4).delay(0.2), value: isAnimated)
                }
                
                Spacer()
                
                // Status badge with animation
                Text(flightDetail.status ?? "Scheduled")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(statusColor(flightDetail.status))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(statusColor(flightDetail.status).opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(statusColor(flightDetail.status).opacity(0.3), lineWidth: 1)
                            )
                    )
                    .scaleEffect(isAnimated ? 1.0 : 0.8)
                    .opacity(isAnimated ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: isAnimated)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Flight details with staggered animation
            HStack(alignment: .center, spacing: 0) {
                // Departure
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatTime(flightDetail.departure.scheduled.local))
                        .font(.title2)
                        .fontWeight(.medium)
                        .opacity(isAnimated ? 1.0 : 0.0)
                        .offset(x: isAnimated ? 0 : -20)
                    
                    HStack(spacing: 4) {
                        Text(flightDetail.departure.airport.iataCode)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatDate(flightDetail.departure.scheduled.local))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .opacity(isAnimated ? 1.0 : 0.0)
                    .offset(x: isAnimated ? 0 : -20)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: isAnimated)
                
                // Flight path visualization with animation
                VStack(spacing: 4) {
                    HStack(spacing: 0) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(isAnimated ? 1.0 : 0.5)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                            .scaleEffect(x: isAnimated ? 1.0 : 0.1, y: 1.0)
                        
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(isAnimated ? 1.0 : 0.5)
                    }
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.6), value: isAnimated)
                    
                    Text(calculateDuration(
                        departure: flightDetail.departure.scheduled.local,
                        arrival: flightDetail.arrival.scheduled.local
                    ))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .opacity(isAnimated ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.3).delay(0.8), value: isAnimated)
                }
                .frame(maxWidth: .infinity)
                
                // Arrival
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatTime(flightDetail.arrival.scheduled.local))
                        .font(.title2)
                        .fontWeight(.medium)
                        .opacity(isAnimated ? 1.0 : 0.0)
                        .offset(x: isAnimated ? 0 : 20)
                    
                    HStack(spacing: 4) {
                        Text(flightDetail.arrival.airport.iataCode)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatDate(flightDetail.arrival.scheduled.local))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .opacity(isAnimated ? 1.0 : 0.0)
                    .offset(x: isAnimated ? 0 : 20)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: isAnimated)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Direct flight indicator
            HStack {
                Text("Direct")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                    .opacity(isAnimated ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.3).delay(0.9), value: isAnimated)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        .onAppear {
            isAnimated = true
        }
    }
    
    private func statusColor(_ status: String?) -> Color {
        guard let status = status?.lowercased() else { return .green }
        
        switch status {
        case "scheduled", "on time":
            return .green
        case "delayed":
            return .orange
        case "cancelled":
            return .red
        case "landed", "arrived":
            return .blue
        default:
            return .green
        }
    }
    
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
}

// MARK: - Schedule Flight Card (for airport search results) - UPDATED and Enhanced
struct ScheduleFlightCard: View {
    let scheduleResult: ScheduleResult
    @State private var isAnimated = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with airline info and status
            HStack {
                HStack(spacing: 8) {
                    // Airline logo with animation
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue)
                            .frame(width: 28, height: 28)
                            .scaleEffect(isAnimated ? 1.0 : 0.8)
                        
                        Text(scheduleResult.airline.iataCode?.prefix(2) ?? "??")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .opacity(isAnimated ? 1.0 : 0.0)
                    }
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: isAnimated)
                    
                    Text("\(scheduleResult.airline.name) • \(scheduleResult.flightNumber)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .opacity(isAnimated ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.4).delay(0.2), value: isAnimated)
                }
                
                Spacer()
                
                // Status badge with animation
                Text(scheduleResult.status.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(statusColor(scheduleResult.status))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(statusColor(scheduleResult.status).opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(statusColor(scheduleResult.status).opacity(0.3), lineWidth: 1)
                            )
                    )
                    .scaleEffect(isAnimated ? 1.0 : 0.8)
                    .opacity(isAnimated ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: isAnimated)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Flight details with staggered animation
            HStack(alignment: .center, spacing: 0) {
                // Departure
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatTime(scheduleResult.departureTime))
                        .font(.title2)
                        .fontWeight(.medium)
                        .opacity(isAnimated ? 1.0 : 0.0)
                        .offset(x: isAnimated ? 0 : -20)
                    
                    HStack(spacing: 4) {
                        Text("DEP")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatDate(scheduleResult.departureTime))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .opacity(isAnimated ? 1.0 : 0.0)
                    .offset(x: isAnimated ? 0 : -20)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: isAnimated)
                
                // Flight path visualization with animation
                VStack(spacing: 4) {
                    HStack(spacing: 0) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(isAnimated ? 1.0 : 0.5)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                            .scaleEffect(x: isAnimated ? 1.0 : 0.1, y: 1.0)
                        
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(isAnimated ? 1.0 : 0.5)
                    }
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.6), value: isAnimated)
                    
                    Text(calculateScheduleDuration(
                        departure: scheduleResult.departureTime,
                        arrival: scheduleResult.arrivalTime
                    ))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .opacity(isAnimated ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.3).delay(0.8), value: isAnimated)
                }
                .frame(maxWidth: .infinity)
                
                // Arrival - UPDATED: Handle optional airport
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatTime(scheduleResult.arrivalTime))
                        .font(.title2)
                        .fontWeight(.medium)
                        .opacity(isAnimated ? 1.0 : 0.0)
                        .offset(x: isAnimated ? 0 : 20)
                    
                    HStack(spacing: 4) {
                        // FIXED: Handle optional airport field
                        Text(scheduleResult.airport?.iataCode ?? "ARR")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatDate(scheduleResult.arrivalTime))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .opacity(isAnimated ? 1.0 : 0.0)
                    .offset(x: isAnimated ? 0 : 20)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: isAnimated)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Direct flight indicator and destination
            HStack {
                Text("Direct")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                    .opacity(isAnimated ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.3).delay(0.9), value: isAnimated)
                
                Spacer()
                
                // ADDED: Show destination if available
                if let airport = scheduleResult.airport {
                    Text("To \(airport.city)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .opacity(isAnimated ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.3).delay(1.0), value: isAnimated)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        .onAppear {
            isAnimated = true
        }
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "scheduled":
            return .green
        case "delayed":
            return .orange
        case "cancelled":
            return .red
        case "landed", "arrived":
            return .blue
        default:
            return .green
        }
    }
    
    private func formatTime(_ timeString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        if let date = formatter.date(from: timeString) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            return timeFormatter.string(from: date)
        }
        return timeString
    }
    
    private func formatDate(_ timeString: String) -> String {
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
