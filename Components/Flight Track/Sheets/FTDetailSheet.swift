import SwiftUI

struct FlightDetailBottomSheet: View {
    let flight: FlightDetail
    
    var body: some View {
        ScrollView {
            flightDetailContent(flight)
                .padding(.bottom, 40) // extra space for drag indicator area
        }
    }

    private func flightDetailContent(_ flight: FlightDetail) -> some View {
        VStack(spacing: 16) {
            // Flight Info Header
            VStack {
                HStack{
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
                
                Image("DottedLine")
   
                // Flight Route Timeline with updated design
                HStack(alignment: .top, spacing: 16) {
                    // Timeline positioned to align with airport codes
                    VStack(spacing: 0) {
                        // Spacing for alignment
                        Spacer()
                        // Departure circle
                        Circle()
                            .stroke(Color.primary, lineWidth: 1)
                            .frame(width: 8, height: 8)
                        // Connecting line
                        Rectangle()
                            .fill(Color.primary)
                            .frame(width: 1, height: 120)
                            .padding(.top, 4)
                            .padding(.bottom, 4)
                        // Arrival circle
                        Circle()
                            .stroke(Color.primary, lineWidth: 1)
                            .frame(width: 8, height: 8)
                        // Space for remaining content
                        Spacer()
                    }
                    
                    // Flight details
                    VStack(alignment: .leading, spacing: 10) {
                        // Departure
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(flight.departure.airport.iataCode)
                                        .font(.system(size: 34, weight: .bold))
                                       
                                    Text(flight.departure.airport.name)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.gray)
                                    if let terminal = flight.departure.terminal, let gate = flight.departure.gate {
                                        Text("Terminal: \(terminal) • Gate: \(gate)")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.gray)
                                    } else if let terminal = flight.departure.terminal {
                                        Text("Terminal: \(terminal) • Gate: --")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(formatTime(flight.departure.scheduled.local))
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.rainForest)
                                    if let actual = flight.departure.actual?.local {
                                        Text(getTimeStatus(scheduled: flight.departure.scheduled.local, actual: actual))
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.rainForest)
                                    } else {
                                        Text("On time")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.rainForest)
                                    }
                                    Text(formatDateOnly(flight.departure.scheduled.local))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        
                        // Duration (centered between departure and arrival)
                        HStack {
                            Spacer()
                            Text(calculateDuration(departure: flight.departure.scheduled.local, arrival: flight.arrival.scheduled.local))
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.vertical, 8)
                            Spacer()
                        }
                        
                        // Arrival
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(flight.arrival.airport.iataCode)
                                        .font(.system(size: 34, weight: .bold))
                                        .fontWeight(.bold)
                                    Text(flight.arrival.airport.name)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.gray)
                                    if let terminal = flight.arrival.terminal {
                                        let gateText = flight.arrival.gate ?? "--"
                                        Text("Terminal: \(terminal) • Gate: \(gateText)")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.gray)
                                    } else {
                                        Text("Terminal: -- • Gate: --")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    if let estimated = flight.arrival.estimated?.local {
                                        Text(formatTime(estimated))
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.rainForest)
                                        Text(getArrivalStatus(scheduled: flight.arrival.scheduled.local ?? "", estimated: estimated))
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.rainForest)
                                    } else {
                                        Text(formatTime(flight.arrival.scheduled.local))
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.rainForest)
                                        Text("On time")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.rainForest)
                                    }
                                    Text(formatDateOnly(flight.arrival.scheduled.local))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 16)
                }
                .padding()
                
                Divider()
                    .padding(.bottom,20)
                
                // Status Cards
                VStack(spacing: 12) {
                    flightStatusCard(
                        title: "\(flight.departure.airport.city ?? flight.departure.airport.name), \(flight.departure.airport.country ?? "Unknown")",
                        gateTime: formatTime(flight.departure.scheduled.local),
                        estimatedGateTime: flight.departure.estimated?.local != nil ? formatTime(flight.departure.estimated?.local) : nil,
                        gateStatus: flight.departure.actual != nil ? "Departed" : "On time",
                        runwayTime: flight.departure.actual?.local != nil ? formatTime(flight.departure.actual?.local) : "Unavailable",
                        runwayStatus: flight.departure.actual != nil ? "Departed" : "Unavailable",
                        isDeparture: true
                    )
                    
                    Divider()
                        .padding(.vertical,20)
                    
                    flightStatusCard(
                        title: "\(flight.arrival.airport.city ?? flight.arrival.airport.name), \(flight.arrival.airport.country ?? "Unknown")",
                        gateTime: formatTime(flight.arrival.scheduled.local),
                        estimatedGateTime: flight.arrival.estimated?.local != nil ? formatTime(flight.arrival.estimated?.local) : nil,
                        gateStatus: flight.arrival.actual != nil ? "Arrived" : (flight.arrival.estimated != nil ? getArrivalStatus(scheduled: flight.arrival.scheduled.local ?? "", estimated: flight.arrival.estimated?.local ?? "") : "On time"),
                        runwayTime: flight.arrival.actual?.local != nil ? formatTime(flight.arrival.actual?.local) : "Unavailable",
                        runwayStatus: flight.arrival.actual != nil ? "Arrived" : "Unavailable",
                        isDeparture: false
                    )
                }
                
                AirlinesInfo(airline: flight.airline)
                
                AboutDestination(flight: flight)
                
                // Notification & Delete section (keeping original design)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Notification")
                            .font(.system(size: 18, weight: .semibold))
                        Spacer()
                        Toggle("", isOn: .constant(false))
                            .labelsHidden()
                    }
                    Divider()
                    HStack {
                        Text("Add to Calendar")
                            .font(.system(size: 18, weight: .semibold))
                        Spacer()
                        Toggle("", isOn: .constant(false))
                            .labelsHidden()
                    }
                    Divider()
                    HStack {
                        Button(action: {
                            // delete action
                        }) {
                            HStack(spacing: 4) {
                                Text("Delete")
                                    .foregroundColor(.red)
                                    .font(.system(size: 18, weight: .semibold))
                                Spacer()
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                        Spacer()
                    }
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.black.opacity(0.3), lineWidth: 1.4)
                )
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.05), radius: 4)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4)
        }
    }
}

private func formatTime(_ timeString: String?) -> String {
    guard let timeString = timeString else { return "--:--" }
    
    // Handle different time formats
    let formatter = DateFormatter()
    
    // Try different formats
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

private func formatDateOnly(_ timeString: String?) -> String {
    guard let timeString = timeString else { return "--" }
    
    let formatter = DateFormatter()
    
    // Try different formats
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

private func formatDateForDisplay(_ dateString: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd"
    
    if let date = formatter.date(from: dateString) {
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "dd MMM, yyyy"
        return displayFormatter.string(from: date)
    }
    
    return dateString
}

private func calculateDuration(departure: String?, arrival: String?) -> String {
    guard let depString = departure, let arrString = arrival else { return "--h --min" }
    
    let formatter = DateFormatter()
    
    // Try different formats
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

private func getTimeStatus(scheduled: String?, actual: String?) -> String {
    guard let scheduledString = scheduled, let actualString = actual else { return "On time" }
    
    let formatter = DateFormatter()
    
    // Try different formats
    let formats = [
        "yyyy-MM-dd'T'HH:mm:ssZ",
        "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
        "yyyy-MM-dd'T'HH:mm:ss",
        "yyyy-MM-dd HH:mm:ss"
    ]
    
    var scheduledDate: Date?
    var actualDate: Date?
    
    for format in formats {
        formatter.dateFormat = format
        if scheduledDate == nil {
            scheduledDate = formatter.date(from: scheduledString)
        }
        if actualDate == nil {
            actualDate = formatter.date(from: actualString)
        }
        if scheduledDate != nil && actualDate != nil {
            break
        }
    }
    
    guard let schedDate = scheduledDate, let actDate = actualDate else { return "On time" }
    
    let difference = actDate.timeIntervalSince(schedDate)
    let minutes = Int(difference) / 60
    
    if minutes > 0 {
        return "\(minutes)m delayed"
    } else if minutes < 0 {
        return "\(-minutes)m early"
    } else {
        return "On time"
    }
}

private func getArrivalStatus(scheduled: String, estimated: String) -> String {
    let formatter = DateFormatter()
    
    // Try different formats
    let formats = [
        "yyyy-MM-dd'T'HH:mm:ssZ",
        "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
        "yyyy-MM-dd'T'HH:mm:ss",
        "yyyy-MM-dd HH:mm:ss"
    ]
    
    var scheduledDate: Date?
    var estimatedDate: Date?
    
    for format in formats {
        formatter.dateFormat = format
        if scheduledDate == nil {
            scheduledDate = formatter.date(from: scheduled)
        }
        if estimatedDate == nil {
            estimatedDate = formatter.date(from: estimated)
        }
        if scheduledDate != nil && estimatedDate != nil {
            break
        }
    }
    
    guard let schedDate = scheduledDate, let estDate = estimatedDate else { return "On time" }
    
    let difference = estDate.timeIntervalSince(schedDate)
    let minutes = Int(difference) / 60
    
    if minutes > 0 {
        return "\(minutes)m delayed"
    } else if minutes < 0 {
        return "\(-minutes)m early"
    } else {
        return "On time"
    }
}


private func flightStatusCard(title: String, gateTime: String, estimatedGateTime: String?, gateStatus: String, runwayTime: String, runwayStatus: String, isDeparture: Bool) -> some View {
    VStack(alignment: .leading, spacing: 16) {
        // Header with plane icon and city
        HStack(spacing: 12) {
            Image(systemName: isDeparture ? "airplane.departure" : "airplane.arrival")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            Text(isDeparture ? "Departure" : "Arrival")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
        }
        
        // Gate Time section
        VStack(alignment: .leading, spacing: 12) {
            Text("Gate Time")
                .font(.system(size: 18, weight: .semibold))
            
            // Three columns layout
            HStack(spacing: 0) {
                // Scheduled column
                VStack(alignment: .center, spacing: 8) {
                    Text("Scheduled")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text(gateTime)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                
                // Estimated column
                VStack(alignment: .center, spacing: 8) {
                    Text("Estimated")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text(estimatedGateTime ?? "-")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                
                // Status column
                VStack(alignment: .center, spacing: 8) {
                    Text("Status")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text(gateStatus)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(gateStatus.lowercased().contains("time") ? .green : .gray)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray, lineWidth: 1)
            )
        }
        
        // Runway Time section
        VStack(alignment: .leading, spacing: 12) {
            Text("Runway Time")
                .font(.system(size: 18, weight: .semibold))
            
            // Three columns layout
            HStack(spacing: 0) {
                // Scheduled column
                VStack(alignment: .center, spacing: 8) {
                    Text("Scheduled")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text(runwayTime)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                
                // Estimated column
                VStack(alignment: .center, spacing: 8) {
                    Text("Estimated")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text("-")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                
                // Status column
                VStack(alignment: .center, spacing: 8) {
                    Text("Status")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text(runwayStatus)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(runwayStatus.contains("delayed") ? .red : runwayStatus.lowercased().contains("time") ? .green : .gray)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray, lineWidth: 1)
            )
        }
    }
}
