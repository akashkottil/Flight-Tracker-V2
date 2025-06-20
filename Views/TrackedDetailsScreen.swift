// Enhanced TrackedDetailsScreen.swift - Accept dynamic data

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
    
    // ADDED: Computed properties for dynamic header values
    private var fromText: String {
        if let flightDetail = flightDetail {
            return flightDetail.departure.airport.iataCode
        } else if let firstFlight = scheduleResults.first {
            return firstFlight.airport.iataCode
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
            // UPDATED: Use TrackCollapseHeader instead of CustomHeaderView
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
                    dismiss()
                },
                shouldShowBackButton: true
            )
            
            // Main Content
            ScrollView {
                LazyVStack(spacing: 12) {
                    if searchType == .flight, let flightDetail = flightDetail {
                        // Show single flight detail
                        SingleFlightCard(flightDetail: flightDetail)
                    } else if searchType == .airport, !scheduleResults.isEmpty {
                        // Show multiple flights from schedule
                        ForEach(scheduleResults.indices, id: \.self) { index in
                            ScheduleFlightCard(scheduleResult: scheduleResults[index])
                        }
                    } else {
                        // Empty state
                        VStack(spacing: 20) {
                            Spacer()
                            Image(systemName: "airplane.circle")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("No flight data available")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .frame(height: 400)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
        }
        .navigationBarHidden(true)
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

// MARK: - Single Flight Detail Card (for flight number search)
struct SingleFlightCard: View {
    let flightDetail: FlightDetail
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with airline info and status
            HStack {
                HStack(spacing: 8) {
                    // Airline logo
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue)
                            .frame(width: 28, height: 28)
                        
                        Text(flightDetail.airline.iataCode.prefix(2))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Text("\(flightDetail.airline.name) • \(flightDetail.flightIata)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // Status badge
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
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Flight details
            HStack(alignment: .center, spacing: 0) {
                // Departure
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatTime(flightDetail.departure.scheduled.local))
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 4) {
                        Text(flightDetail.departure.airport.iataCode)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatDate(flightDetail.departure.scheduled.local))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Flight path visualization
                VStack(spacing: 4) {
                    HStack(spacing: 0) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                    
                    Text(calculateDuration(
                        departure: flightDetail.departure.scheduled.local,
                        arrival: flightDetail.arrival.scheduled.local
                    ))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                // Arrival
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatTime(flightDetail.arrival.scheduled.local))
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 4) {
                        Text(flightDetail.arrival.airport.iataCode)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatDate(flightDetail.arrival.scheduled.local))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Direct flight indicator
            HStack {
                Text("Direct")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
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

// MARK: - Schedule Flight Card (for airport search results)
struct ScheduleFlightCard: View {
    let scheduleResult: ScheduleResult
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with airline info and status
            HStack {
                HStack(spacing: 8) {
                    // Airline logo
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue)
                            .frame(width: 28, height: 28)
                        
                        Text(scheduleResult.airline.iataCode?.prefix(2) ?? "??")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Text("\(scheduleResult.airline.name) • \(scheduleResult.flightNumber)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // Status badge
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
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Flight details
            HStack(alignment: .center, spacing: 0) {
                // Departure
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatTime(scheduleResult.departureTime))
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 4) {
                        Text("DEP")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatDate(scheduleResult.departureTime))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Flight path visualization
                VStack(spacing: 4) {
                    HStack(spacing: 0) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                    
                    Text(calculateScheduleDuration(
                        departure: scheduleResult.departureTime,
                        arrival: scheduleResult.arrivalTime
                    ))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                // Arrival
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatTime(scheduleResult.arrivalTime))
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 4) {
                        Text(scheduleResult.airport.iataCode)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatDate(scheduleResult.arrivalTime))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Direct flight indicator
            HStack {
                Text("Direct")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
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
