import SwiftUI
import MapKit

// MARK: - Stretchy Header Extension
extension View {
    func stretchy() -> some View {
        visualEffect { effect, geometry in
            let currentHeight = geometry.size.height
            let scrollOffset = geometry.frame(in: .scrollView).minY
            let positiveOffset = max(0, scrollOffset)
            
            let newHeight = currentHeight + positiveOffset
            let scaleFactor = newHeight / currentHeight
            
            return effect.scaleEffect(
                x: scaleFactor, y: scaleFactor,
                anchor: .bottom
            )
        }
    }
}

struct FlightDetailDesignScreen: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Map-related state
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7589, longitude: -73.9851), // NYC coordinates
        span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
    )
    @State private var flightRoute: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 40.7589, longitude: -73.9851), // JFK
        CLLocationCoordinate2D(latitude: 51.4700, longitude: -0.4543)   // LHR
    ]
    @State private var departureAnnotation: FlightDetailAnnotation? = FlightDetailAnnotation(
        id: "departure",
        coordinate: CLLocationCoordinate2D(latitude: 40.7589, longitude: -73.9851),
        airportCode: "JFK",
        type: .departure
    )
    @State private var arrivalAnnotation: FlightDetailAnnotation? = FlightDetailAnnotation(
        id: "arrival",
        coordinate: CLLocationCoordinate2D(latitude: 51.4700, longitude: -0.4543),
        airportCode: "LHR",
        type: .arrival
    )

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Stretchy Map Header
                    Map(coordinateRegion: $mapRegion, annotationItems: [
                        departureAnnotation,
                        arrivalAnnotation
                    ].compactMap { $0 }) { annotation in
                        MapAnnotation(coordinate: annotation.coordinate) {
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(annotation.type == .departure ? Color.green : Color.red)
                                        .frame(width: 12, height: 12)
                                    
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                        .frame(width: 12, height: 12)
                                }
                                
                                Text(annotation.airportCode)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(annotation.type == .departure ? Color.green : Color.red)
                                    )
                            }
                        }
                    }
                    .overlay(
                        // Flight path polyline
                        FlightPathView(coordinates: flightRoute)
                            .allowsHitTesting(false)
                    )
                    .frame(height: 350)
                    .clipped()
                    .stretchy()
                    
                    // Flight Detail Content
                    flightDetailContent()
                        .background(Color(UIColor.systemBackground))
                }
            }
            .ignoresSafeArea(edges: .top)
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
                        Text("New York - London")
                            .font(.system(size: 18))
                            .fontWeight(.bold)
                        Text("18 Jun, 2025")
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
    }
    
    private func flightDetailContent() -> some View {
        VStack(spacing: 16) {
            // Flight Info Header
            VStack {
                HStack{
                    Image("FlightTrackLogo")
                        .resizable()
                        .frame(width: 34, height: 34)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("BA 178")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("British Airways")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text("On Time")
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
   
                // Flight Route Timeline
                HStack(alignment: .top, spacing: 16) {
                    // Timeline
                    VStack(spacing: 0) {
                        Spacer()
                        Circle()
                            .stroke(Color.primary, lineWidth: 1)
                            .frame(width: 8, height: 8)
                        Rectangle()
                            .fill(Color.primary)
                            .frame(width: 1, height: 120)
                            .padding(.top, 4)
                            .padding(.bottom, 4)
                        Circle()
                            .stroke(Color.primary, lineWidth: 1)
                            .frame(width: 8, height: 8)
                        Spacer()
                    }
                    
                    // Flight details
                    VStack(alignment: .leading, spacing: 10) {
                        // Departure
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("JFK")
                                        .font(.system(size: 34, weight: .bold))
                                       
                                    Text("John F. Kennedy International Airport")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.gray)
                                    Text("Terminal: 7 • Gate: A12")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("14:30")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.rainForest)
                                    Text("On time")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.rainForest)
                                    Text("18 Jun")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        
                        // Duration
                        HStack {
                            Spacer()
                            Text("7h 45min")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.vertical, 8)
                            Spacer()
                        }
                        
                        // Arrival
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("LHR")
                                        .font(.system(size: 34, weight: .bold))
                                        .fontWeight(.bold)
                                    Text("London Heathrow Airport")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.gray)
                                    Text("Terminal: 5 • Gate: B24")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("02:15")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.rainForest)
                                    Text("On time")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.rainForest)
                                    Text("19 Jun")
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
                        title: "New York, United States",
                        gateTime: "14:30",
                        estimatedGateTime: "14:30",
                        gateStatus: "On time",
                        runwayTime: "14:35",
                        runwayStatus: "Departed",
                        isDeparture: true
                    )
                    
                    Divider()
                        .padding(.vertical,20)
                    
                    flightStatusCard(
                        title: "London, United Kingdom",
                        gateTime: "02:15",
                        estimatedGateTime: "02:15",
                        gateStatus: "On time",
                        runwayTime: "02:20",
                        runwayStatus: "Unavailable",
                        isDeparture: false
                    )
                }
                
//                AirlinesInfo()
                
//                AboutDestination()
                
                // Notification & Delete section
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
        .padding(.horizontal)
        .padding(.bottom, 32)
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
}

// MARK: - Map Support Models and Views

enum FlightDetailAirportType {
    case departure
    case arrival
}

struct FlightDetailAnnotation: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let airportCode: String
    let type: FlightDetailAirportType
}

struct eFlightPathView: View {
    let coordinates: [CLLocationCoordinate2D]
    
    var body: some View {
        if coordinates.count >= 2 {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 100, y: 100))
            }
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [5, 5])
            )
        }
    }
}

// MARK: - Supporting Views

struct eAirlinesInfo: View {
    var body: some View {
        VStack(alignment:.leading, spacing: 12){
            Text("Airline Information")
                .font(.system(size: 18, weight: .semibold))
                .padding(.top, 15)
            HStack{
                Image("FlightTrackLogo")
                    .frame(width: 34, height: 34)
                Text("British Airways")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
            }
            HStack{
                VStack {
                    Text("ATC Callsign")
                    Text("BAW")
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
                    Text("285")
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
                    Text("12.5y")
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
                Text("90%")
                    .font(.system(size: 12, weight: .bold))
            }
            CustomProgressBar(progress: 0.9)
                .padding(.vertical, 4)
            
            Text("Based on data for the past 10 days")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
        }
    }
}

struct eAboutDestination: View {
    var body: some View {
        VStack(alignment: .leading){
            Text("About your destination")
                .font(.system(size: 18, weight: .semibold))
            HStack{
                VStack(alignment: .leading){
                    Text("15°C")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Weather in London")
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
                    Text("5,585 km")
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

struct eCustomProgressBar: View {
    let progress: Double
    let height: CGFloat = 8
    let cornerRadius: CGFloat = 4
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: cornerRadius*2)
                    .fill(Color(red: 0.827, green: 0.827, blue: 0.827, opacity: 0.4))
                    .frame(height: height*2)
                
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(red: 0.0, green: 0.424, blue: 0.890))
                    .frame(width: geometry.size.width * CGFloat(progress), height: height)
                    .padding(.horizontal,5)
            }
        }
        .frame(height: height)
    }
}

#Preview {
    FlightDetailDesignScreen()
}
