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
    
    // Bottom sheet state
    @State private var showingBottomSheet = true
    @State private var bottomSheetDetent: PresentationDetent = .medium
    
    var body: some View {
        NavigationView {
            ZStack {
                // Full screen map
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
                    GradientColor.FTHGradient
                        .blendMode(.overlay)
                )
                .overlay(
                    // Flight path polyline
                    FlightPathView(coordinates: flightRoute)
                        .allowsHitTesting(false)
                )
                .ignoresSafeArea()
                
                // Bottom sheet trigger button
                //                VStack {
                //                    Spacer()
                //                    HStack {
                //                        Spacer()
                //                        Button(action: {
                //                            showingBottomSheet = true
                //                        }) {
                //                            VStack(spacing: 4) {
                //                                Image(systemName: "airplane")
                //                                    .font(.system(size: 20, weight: .medium))
                //                                    .foregroundColor(.white)
                //                                Text("Flight Details")
                //                                    .font(.system(size: 12, weight: .medium))
                //                                    .foregroundColor(.white)
                //                            }
                //                            .padding(.horizontal, 16)
                //                            .padding(.vertical, 12)
                //                            .background(Color.blue)
                //                            .cornerRadius(25)
                //                            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                //                        }
                //                        Spacer()
                //                    }
                //                    .padding(.bottom, 100)
                //                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
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
                    .foregroundColor(.white)
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
        .sheet(isPresented: $showingBottomSheet) {
            bottomSheetContent()
                .presentationDetents([.medium, .fraction(0.95)])
                .presentationDragIndicator(.visible)
                .presentationBackground(.regularMaterial)
                .interactiveDismissDisabled(true)
            
        }
    }
    
    // Bottom sheet content
    private func bottomSheetContent() -> some View {
        NavigationView {
            ScrollView {
                flightDetailContent()
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
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.green, lineWidth: 1)
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
                                        .foregroundColor(.green)
                                    Text("On time")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.green)
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
                                        .foregroundColor(.green)
                                    Text("On time")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.green)
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

struct FlightPathView: View {
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

#Preview {
    FlightDetailDesignScreen()
}
