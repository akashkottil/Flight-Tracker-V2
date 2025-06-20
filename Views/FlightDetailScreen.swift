import SwiftUI

struct FlightDetailScreen: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Flight parameters
    let flightNumber: String
    let date: String
    let onFlightViewed: ((TrackedFlightData) -> Void)?
    
    // State for API data
    @State private var flightDetail: FlightDetail?
    @State private var isLoading = true
    @State private var error: String?
    
    private let networkManager = FlightTrackNetworkManager.shared

    // ADDED: Default initializer for backward compatibility
    init(flightNumber: String, date: String, onFlightViewed: ((TrackedFlightData) -> Void)? = nil) {
        self.flightNumber = flightNumber
        self.date = date
        self.onFlightViewed = onFlightViewed
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if isLoading {
                        FlightDetailsShimmer()
                    } else if let error = error {
                        errorView(error)
                    } else if let flightDetail = flightDetail {
                        flightDetailContent(flightDetail)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "0C243E"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image("FliterBack")
                    }
                }
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        if let flightDetail = flightDetail {
                            Text("\(flightDetail.departure.airport.city ?? flightDetail.departure.airport.name) - \(flightDetail.arrival.airport.city ?? flightDetail.arrival.airport.name)")  // FIXED: Handle optional city
                                .font(.system(size: 18))
                                .fontWeight(.bold)
                        } else {
                            Text("Flight Details")
                                .font(.system(size: 18))
                                .fontWeight(.bold)
                        }
                        Text(formatDateForDisplay(date))
                            .font(.system(size: 14))
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Share action
                    }) {
                        Image("FilterShare")
                    }
                }
            }
        }
        .onAppear {
            Task {
                await fetchFlightDetails()
            }
        }
        .onDisappear {
            // ADDED: Add flight to recently viewed when user leaves this screen
            if let flightDetail = flightDetail, let onFlightViewed = onFlightViewed {
                addToRecentlyViewed(flightDetail)
            }
        }
    }
    
    // ADDED: Add flight to recently viewed when screen is dismissed
    private func addToRecentlyViewed(_ flight: FlightDetail) {
        let trackedFlight = TrackedFlightData(
            id: "\(flightNumber)_\(date)",
            flightNumber: flight.flightIata,
            airlineName: flight.airline.name,
            status: flight.status ?? "Unknown",  // FIXED: Handle optional status
            departureTime: formatTime(flight.departure.scheduled.local),
            departureAirport: flight.departure.airport.iataCode,
            departureDate: formatDateOnly(flight.departure.scheduled.local),
            arrivalTime: formatTime(flight.arrival.scheduled.local),
            arrivalAirport: flight.arrival.airport.iataCode,
            arrivalDate: formatDateOnly(flight.arrival.scheduled.local),
            duration: calculateDuration(departure: flight.departure.scheduled.local, arrival: flight.arrival.scheduled.local),
            flightType: "Direct", // You might want to determine this based on actual data
            date: date
        )
        
        onFlightViewed?(trackedFlight)
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            Text("Error loading flight details")
                .font(.system(size: 18, weight: .semibold))
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Retry") {
                Task {
                    await fetchFlightDetails()
                }
            }
            .padding()
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(8)
            Spacer()
        }
    }
    
    private func flightDetailContent(_ flight: FlightDetail) -> some View {
        VStack(spacing: 16) {
            // Flight Info Header
            VStack {
                HStack{
                    Image("FlightTrackLogo") // Placeholder for airline icon
                        .resizable()
                        .frame(width: 34, height: 34)
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
                        title: "\(flight.departure.airport.city ?? flight.departure.airport.name), \(flight.departure.airport.country ?? "Unknown")",  // FIXED: Handle optional fields
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
                        title: "\(flight.arrival.airport.city ?? flight.arrival.airport.name), \(flight.arrival.airport.country ?? "Unknown")",  // FIXED: Handle optional fields
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
    
    // MARK: - API Methods
    
    @MainActor
    private func fetchFlightDetails() async {
        isLoading = true
        error = nil
        
        do {
            let response = try await networkManager.fetchFlightDetail(flightNumber: flightNumber, date: date)
            flightDetail = response.result
        } catch {
            self.error = error.localizedDescription
            print("Flight detail fetch error: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
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
}

// MARK: - Supporting Views (keeping original design)

struct AirlinesInfo: View {
    let airline: FlightDetailAirline
    
    var body: some View {
        VStack(alignment:.leading, spacing: 12){
            Text("Airline Information")
                .font(.system(size: 18, weight: .semibold))
                .padding(.top, 15)
            HStack{
                Image("FlightTrackLogo")
                    .frame(width: 34, height: 34)
                Text(airline.name)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
            }
            HStack{
                VStack {
                    Text("ATC Callsign")
                    Text(airline.callsign ?? "N/A")  // FIXED: Handle optional callsign
                        .fontWeight(.bold)
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack {
                    Text("Fleet Size")
                    Text("\(airline.totalAircrafts ?? 0)")  // FIXED: Handle optional totalAircrafts
                        .fontWeight(.bold)
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack {
                    Text("Fleet Age")
                    Text("\(String(format: "%.1f", airline.averageFleetAge ?? 0.0))y")  // FIXED: Handle optional averageFleetAge
                        .fontWeight(.bold)
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            Text("Flight performance")
                .font(.system(size: 16, weight: .semibold))
            HStack{
                Text("On-time")
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Text("90%") // You might want to calculate this from real data
                    .font(.system(size: 12, weight: .bold))
            }
            // Custom Progress Bar
            CustomProgressBar(progress: 0.9) // 90%
                .padding(.vertical, 4)
            
            Text("Based on data for the past 10 days")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
        }
    }
}

struct AboutDestination: View {
    let flight: FlightDetail
    
    var body: some View {
        VStack(alignment: .leading){
            Text("About your destination")
                .font(.system(size: 18, weight: .semibold))
            HStack{
                VStack(alignment: .leading){
                    Text("29°C") // You might want to integrate weather API
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Weather in \(flight.arrival.airport.city ?? flight.arrival.airport.name)")  // FIXED: Handle optional city
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
                VStack(alignment: .leading) {
                    Text("Distance")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.black.opacity(0.7))
                    Text("\(String(format: "%.0f", flight.greatCircleDistance.km)) km")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.black)
                    Text("Great circle distance")
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

struct CustomProgressBar: View {
    let progress: Double // Value between 0.0 and 1.0
    let height: CGFloat = 8
    let cornerRadius: CGFloat = 4
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background (wrapped box)
                RoundedRectangle(cornerRadius: cornerRadius*2)
                    .fill(Color(red: 0.827, green: 0.827, blue: 0.827, opacity: 0.4)) // #D3D3D366
                    .frame(height: height*2)
                
                // Progress fill
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(red: 0.0, green: 0.424, blue: 0.890)) // #006CE3
                    .frame(width: geometry.size.width * CGFloat(progress), height: height)
                    .padding(.horizontal,5)
            }
        }
        .frame(height: height)
    }
}

#Preview {
    FlightDetailScreen(flightNumber: "6E 703", date: "20250618")
}
