import SwiftUI
import MapKit



// Custom annotation for flight icon
class FlightMapIconAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
    var rotation: Double = 0
}

// Custom SwiftUI view for the flight icon (renamed to avoid conflicts)
struct MapFlightIconView: View {
    let rotation: Double
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Pulsing background
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.4),
                            Color.blue.opacity(0.1),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 2,
                        endRadius: 15
                    )
                )
                .frame(width: 30, height: 30)
                .scaleEffect(isAnimating ? 1.2 : 0.8)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
            
            // Flight icon
            Image(systemName: "airplane")
                .resizable()
                .frame(width: 16, height: 16)
                .foregroundColor(.white)
                .rotationEffect(.degrees(rotation))
                .shadow(color: .blue.opacity(0.5), radius: 2, x: 0, y: 0)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct FlightMapView: UIViewRepresentable {
    let departure: CLLocationCoordinate2D
    let arrival: CLLocationCoordinate2D
    let arcPathPoints: [CLLocationCoordinate2D]
    let flightProgress: Double
    let pathAnimationProgress: Double
    let showFlightPath: Bool

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.mapType = .standard
        map.showsCompass = false
        map.showsScale = false
        
        // Set initial region
        let region = calculateOptimalRegion()
        map.setRegion(region, animated: false)

        return map
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Clear existing overlays
        uiView.removeOverlays(uiView.overlays)
        uiView.removeAnnotations(uiView.annotations)
        
        // Add airport annotations
        addAirportAnnotations(to: uiView)
        
        // Add flight path overlays if available
        if showFlightPath && !arcPathPoints.isEmpty {
            addFlightPathOverlays(to: uiView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    private func calculateOptimalRegion() -> MKCoordinateRegion {
        let centerLat = (departure.latitude + arrival.latitude) / 2
        let centerLng = (departure.longitude + arrival.longitude) / 2
        
        let latDelta = abs(departure.latitude - arrival.latitude) * 1.8
        let lngDelta = abs(departure.longitude - arrival.longitude) * 1.8
        
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng),
            span: MKCoordinateSpan(
                latitudeDelta: max(latDelta, 2.0),
                longitudeDelta: max(lngDelta, 2.0)
            )
        )
    }
    
    private func addAirportAnnotations(to mapView: MKMapView) {
        let departureAnnotation = MKPointAnnotation()
        departureAnnotation.coordinate = departure
        departureAnnotation.title = "Departure"
        
        let arrivalAnnotation = MKPointAnnotation()
        arrivalAnnotation.coordinate = arrival
        arrivalAnnotation.title = "Arrival"
        
        mapView.addAnnotations([departureAnnotation, arrivalAnnotation])
    }
    
    private func addFlightPathOverlays(to mapView: MKMapView) {
        guard arcPathPoints.count > 1 else { return }
        
        // --- shared counters -------------------------------------------------
        let totalPoints   = arcPathPoints.count
        let traveledCount = Int(Double(totalPoints) * flightProgress * pathAnimationProgress)
        
        // --- traveled path (solid purple) ------------------------------------
        if traveledCount >= 1 {   // include first point
            let traveledPoints = Array(arcPathPoints.prefix(traveledCount))
            let traveledPolyline = MKPolyline(coordinates: traveledPoints,
                                              count: traveledPoints.count)
            traveledPolyline.title = "traveled"
            mapView.addOverlay(traveledPolyline)
        }
        
        // --- remaining path (solid light‑blue) -------------------------------
        if traveledCount < totalPoints - 1 && pathAnimationProgress > 0.3 {
            let remainingPoints = Array(arcPathPoints.suffix(from: max(0, traveledCount)))
            let remainingPolyline = MKPolyline(coordinates: remainingPoints,
                                               count: remainingPoints.count)
            remainingPolyline.title = "remaining"
            mapView.addOverlay(remainingPolyline)
        }
        
        // --- flight icon at boundary -----------------------------------------
        if traveledCount > 0 && traveledCount < totalPoints {
            // remove the old icon (if any)
            mapView.removeAnnotations(
                mapView.annotations.filter { $0 is FlightMapIconAnnotation }
            )
            
            let iconIndex = min(traveledCount, totalPoints - 1)
            let flightIconAnnotation = FlightMapIconAnnotation()
            flightIconAnnotation.coordinate = arcPathPoints[iconIndex]
            flightIconAnnotation.rotation = calculateFlightRotation(at: iconIndex)
            mapView.addAnnotation(flightIconAnnotation)
        }
    }

    
    private func calculateFlightRotation(at index: Int) -> Double {
        guard index > 0 && index < arcPathPoints.count - 1 else {
            // Fallback for edge cases
            if index == 0 && arcPathPoints.count > 1 {
                let current = arcPathPoints[0]
                let next = arcPathPoints[1]
                let deltaLng = next.longitude - current.longitude
                let deltaLat = next.latitude - current.latitude
                return atan2(deltaLng, deltaLat) * 180 / .pi
            }
            return 0
        }
        
        let beforePoint = arcPathPoints[index - 1]
        let afterPoint = arcPathPoints[min(index + 1, arcPathPoints.count - 1)]
        
        let deltaLng = afterPoint.longitude - beforePoint.longitude
        let deltaLat = afterPoint.latitude - beforePoint.latitude
        
        let angleRadians = atan2(deltaLng, deltaLat)
        return angleRadians * 180 / .pi
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                
                // Different styles for traveled vs remaining path
                if polyline.title == "traveled" {
                    // Solid, vibrant line for traveled path
                    renderer.strokeColor = UIColor.systemPurple
                    renderer.lineWidth = 4
                    renderer.lineCap = .round
                    renderer.lineJoin = .round
                } else if polyline.title == "remaining" {
                    // Light, blurred/dashed line for remaining path
                    renderer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.5)
                    renderer.lineWidth = 3
                    renderer.lineCap = .round
                    renderer.lineJoin = .round
                }
                
                return renderer
            }
            return MKOverlayRenderer()
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let flightAnnotation = annotation as? FlightMapIconAnnotation {
                let identifier = "FlightIcon"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = false
                }
                
                // Create flight icon image with rotation
                let flightIconView = UIHostingController(rootView:
                    MapFlightIconView(rotation: flightAnnotation.rotation)
                )
                flightIconView.view.backgroundColor = UIColor.clear
                flightIconView.view.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
                
                // Convert SwiftUI view to UIImage
                let renderer = UIGraphicsImageRenderer(bounds: flightIconView.view.bounds)
                let image = renderer.image { context in
                    flightIconView.view.layer.render(in: context.cgContext)
                }
                
                annotationView?.image = image
                annotationView?.centerOffset = CGPoint(x: 0, y: 0)
                annotationView?.annotation = annotation // Add this line
                
                return annotationView
            }
            
            // Default airport annotations
            if annotation.title == "Departure" {
                let identifier = "Departure"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                }
                
                annotationView?.image = createAirportIcon(color: .systemGreen, size: 16)
                annotationView?.centerOffset = CGPoint(x: 0, y: 0)
                
                return annotationView
            } else if annotation.title == "Arrival" {
                let identifier = "Arrival"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                }
                
                annotationView?.image = createAirportIcon(color: .systemRed, size: 16)
                annotationView?.centerOffset = CGPoint(x: 0, y: 0)
                
                return annotationView
            }
            
            return nil
        }
        
        private func createAirportIcon(color: UIColor, size: CGFloat) -> UIImage {
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
            return renderer.image { context in
                color.setFill()
                let circle = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size, height: size))
                circle.fill()
                
                UIColor.white.setFill()
                let innerCircle = UIBezierPath(ovalIn: CGRect(x: size/4, y: size/4, width: size/2, height: size/2))
                innerCircle.fill()
            }
        }
    }
}
// MARK: - Stretchy Header Extension
extension View {
    func estretchy() -> some View {
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

// MARK: - Enhanced Color Extensions
extension Color {
    static let flightPathTraveled = Color.purple
    static let flightPathRemaining = Color.blue
    static let flightIconGlow = Color.blue.opacity(0.4)
}

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
    
    // Map-related state
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20.0, longitude: 60.0),
        span: MKCoordinateSpan(latitudeDelta: 20.0, longitudeDelta: 20.0)
    )
    @State private var flightRoute: [CLLocationCoordinate2D] = []
    @State private var departureAnnotation: FlightAnnotation?
    @State private var arrivalAnnotation: FlightAnnotation?

    // UPDATED: Simplified map loading state
    @State private var mapAnnotations: [FlightAnnotation] = []
    @State private var showMap = false
    
    // ENHANCED: Flight path and animation
    @State private var flightPathProgress: Double = 0.0
    @State private var flightIconPosition: CLLocationCoordinate2D?
    @State private var arcPathPoints: [CLLocationCoordinate2D] = []
    @State private var isAnimating = false
    @State private var pathAnimationProgress: Double = 0.0
    @State private var showFlightPath = false
    
    private let networkManager = FlightTrackNetworkManager.shared

    // Default initializer for backward compatibility
    init(flightNumber: String, date: String, onFlightViewed: ((TrackedFlightData) -> Void)? = nil) {
        self.flightNumber = flightNumber
        self.date = date
        self.onFlightViewed = onFlightViewed
    }

    var body: some View {
        NavigationView {
            ZStack {
                if let departure = departureAnnotation?.coordinate,
                   let arrival = arrivalAnnotation?.coordinate {
                    FlightMapView(
                        departure: departure,
                        arrival: arrival,
                        arcPathPoints: arcPathPoints,
                        flightProgress: flightPathProgress,
                        pathAnimationProgress: pathAnimationProgress,
                        showFlightPath: showFlightPath
                    )
                    .ignoresSafeArea()
                } else {
                    MapShimmerView()
                }

                
                // Gradient overlay
                GradientColor.FTHGradient
                    .blendMode(.overlay)
                    .allowsHitTesting(false)
            }
            .ignoresSafeArea()
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image("FliterBack")
                                .foregroundColor(.white)
                        }
                    }
                
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        if let flightDetail = flightDetail {
                            Text("\(flightDetail.departure.airport.city ?? flightDetail.departure.airport.name) - \(flightDetail.arrival.airport.city ?? flightDetail.arrival.airport.name)")
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
            .onAppear {
                Task {
                    await fetchFlightDetails()
                }
            }
            .onDisappear {
                // Add flight to recently viewed when user leaves this screen
                if let flightDetail = flightDetail, let onFlightViewed = onFlightViewed {
                    addToRecentlyViewed(flightDetail)
                }
            }
            .onChange(of: flightDetail?.flightIata) { _ in
                if let flight = flightDetail {
                    setupMapData(for: flight)
                    // Auto-load map after setup with animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            showMap = true
                        }
                        
                        // Animate flight path after map appears
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            animateFlightPath()
                        }
                    }
                }
            }
            .sheet(isPresented: .constant(true)) {
                bottomSheetContent()
                    .presentationDetents([.medium, .fraction(0.95)])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(.regularMaterial)
                    .interactiveDismissDisabled(true)
                    .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            }
        }.navigationBarBackButtonHidden(true)
    }
    
    
    // Bottom sheet content
    private func bottomSheetContent() -> some View {
        ScrollView {
            VStack(spacing: 16) {
                if isLoading {
                    ProgressView("Loading flight details...")
                        .padding()
                } else if let error = error {
                    errorView(error)
                } else if let flightDetail = flightDetail {
                    flightDetailContent(flightDetail)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .background(Color.clear)
    }
    
    // MARK: - ENHANCED Map Setup Methods
    
    private func setupMapData(for flight: FlightDetail) {
        let departureCoordinate = CLLocationCoordinate2D(
            latitude: flight.departure.airport.location.lat,
            longitude: flight.departure.airport.location.lng
        )
        
        let arrivalCoordinate = CLLocationCoordinate2D(
            latitude: flight.arrival.airport.location.lat,
            longitude: flight.arrival.airport.location.lng
        )
        
        // Create annotations
        departureAnnotation = FlightAnnotation(
            id: "departure",
            coordinate: departureCoordinate,
            airportCode: flight.departure.airport.iataCode,
            type: .departure
        )
        
        arrivalAnnotation = FlightAnnotation(
            id: "arrival",
            coordinate: arrivalCoordinate,
            airportCode: flight.arrival.airport.iataCode,
            type: .arrival
        )
        
        // UPDATED: Set map annotations immediately
        mapAnnotations = [
            FlightAnnotation(
                id: "departure",
                coordinate: departureCoordinate,
                airportCode: flight.departure.airport.iataCode,
                type: .departure
            ),
            FlightAnnotation(
                id: "arrival",
                coordinate: arrivalCoordinate,
                airportCode: flight.arrival.airport.iataCode,
                type: .arrival
            )
        ]
        
        // Create flight route
        flightRoute = [departureCoordinate, arrivalCoordinate]
        
        // Calculate region to fit both points
        let centerLat = (departureCoordinate.latitude + arrivalCoordinate.latitude) / 2
        let centerLng = (departureCoordinate.longitude + arrivalCoordinate.longitude) / 2
        
        let latDelta = abs(departureCoordinate.latitude - arrivalCoordinate.latitude) * 1.5
        let lngDelta = abs(departureCoordinate.longitude - arrivalCoordinate.longitude) * 1.5
        
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng),
            span: MKCoordinateSpan(
                latitudeDelta: max(latDelta, 1.0),
                longitudeDelta: max(lngDelta, 1.0)
            )
        )
        
        mapRegion = region
        
        // ENHANCED: Calculate flight path and position
        calculateFlightProgress(for: flight)
        generateSmartArcPath(from: departureCoordinate, to: arrivalCoordinate)
        
        print("✅ Map data setup complete - Annotations: \(mapAnnotations.count)")
    }
    
    // MARK: - Enhanced Flight Path Animation
    
    private func animateFlightPath() {
        withAnimation(.easeInOut(duration: 1.5)) {
            showFlightPath = true
        }
        
        // Animate the path drawing
        withAnimation(.easeInOut(duration: 2.0).delay(0.5)) {
            pathAnimationProgress = 1.0
        }
        
        // Animate flight icon after path appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { // Increased delay
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
    }
    
    // MARK: - Enhanced Arc Path Generation with Horizontal Curves
    
    private func generateSmartArcPath(from departure: CLLocationCoordinate2D, to arrival: CLLocationCoordinate2D) {
        let numberOfPoints = 100
        var points: [CLLocationCoordinate2D] = []
        
        // Calculate basic direction and distance
        let latDifference = arrival.latitude - departure.latitude
        let lngDifference = arrival.longitude - departure.longitude
        let distance = sqrt(pow(latDifference, 2) + pow(lngDifference, 2))
        
        // Determine curve direction based on flight direction
        let curveMagnitude = calculateCurveMagnitude(for: distance)
        let curveDirection = determineCurveDirection(departure: departure, arrival: arrival)
        
        // Calculate midpoint
        let midLat = (departure.latitude + arrival.latitude) / 2
        let midLng = (departure.longitude + arrival.longitude) / 2
        
        // Create perpendicular vector for curve offset
        let flightVector = (lat: latDifference, lng: lngDifference)
        let vectorLength = sqrt(pow(flightVector.lat, 2) + pow(flightVector.lng, 2))
        
        // Normalize and create perpendicular vector
        let normalizedVector = (
            lat: flightVector.lat / vectorLength,
            lng: flightVector.lng / vectorLength
        )
        
        // Perpendicular vector (rotated 90 degrees)
        let perpendicular = (
            lat: -normalizedVector.lng,
            lng: normalizedVector.lat
        )
        
        // Apply curve direction and magnitude
        let controlLat = midLat + perpendicular.lat * curveMagnitude * curveDirection
        let controlLng = midLng + perpendicular.lng * curveMagnitude * curveDirection
        
        // Generate quadratic Bézier curve points
        for i in 0...numberOfPoints {
            let t = Double(i) / Double(numberOfPoints)
            
            let lat = pow(1 - t, 2) * departure.latitude +
                     2 * (1 - t) * t * controlLat +
                     pow(t, 2) * arrival.latitude
            
            let lng = pow(1 - t, 2) * departure.longitude +
                     2 * (1 - t) * t * controlLng +
                     pow(t, 2) * arrival.longitude
            
            points.append(CLLocationCoordinate2D(latitude: lat, longitude: lng))
        }
        
        arcPathPoints = points
        
        // Calculate flight icon position based on progress
        updateFlightIconPosition()
        
        print("✈️ Generated smart arc path with \(points.count) points, progress: \(flightPathProgress)")
    }

    private func calculateCurveMagnitude(for distance: Double) -> Double {
        // Dynamic curve magnitude based on distance
        switch distance {
        case 0..<5:
            return distance * 0.08  // Very small curve for short flights
        case 5..<15:
            return distance * 0.15  // Small curve for medium-short flights
        case 15..<30:
            return distance * 0.22  // Medium curve for medium flights
        case 30..<50:
            return distance * 0.28  // Large curve for long flights
        default:
            return distance * 0.35  // Very large curve for transcontinental flights
        }
    }

    private func determineCurveDirection(departure: CLLocationCoordinate2D, arrival: CLLocationCoordinate2D) -> Double {
        let latDiff = arrival.latitude - departure.latitude
        let lngDiff = arrival.longitude - departure.longitude
        
        // Determine primary direction
        let isMainlyEastbound = abs(lngDiff) > abs(latDiff) && lngDiff > 0
        let isMainlyWestbound = abs(lngDiff) > abs(latDiff) && lngDiff < 0
        let isMainlyNorthbound = abs(latDiff) > abs(lngDiff) && latDiff > 0
        let isMainlySouthbound = abs(latDiff) > abs(lngDiff) && latDiff < 0
        
        // Smart curve direction logic
        if isMainlyEastbound {
            // For eastbound flights, curve based on latitude component
            return latDiff >= 0 ? 1.0 : -1.0  // Curve right if going northeast, left if southeast
        } else if isMainlyWestbound {
            // For westbound flights, curve opposite to latitude component
            return latDiff >= 0 ? -1.0 : 1.0  // Curve left if going northwest, right if southwest
        } else if isMainlyNorthbound {
            // For northbound flights, curve based on longitude component
            return lngDiff >= 0 ? 1.0 : -1.0  // Curve right if going northeast, left if northwest
        } else if isMainlySouthbound {
            // For southbound flights, curve opposite to longitude component
            return lngDiff >= 0 ? -1.0 : 1.0  // Curve left if going southeast, right if southwest
        } else {
            // For diagonal flights, use a combination approach
            return (lngDiff * latDiff >= 0) ? 1.0 : -1.0
        }
    }

    private func updateFlightIconPosition() {
        guard !arcPathPoints.isEmpty else {
            flightIconPosition = nil
            return
        }
        
        let index = min(Int(flightPathProgress * Double(arcPathPoints.count - 1)), arcPathPoints.count - 1)
        flightIconPosition = arcPathPoints[max(0, index)]
    }
    
    // MARK: - Flight Progress Calculation
    
    private func calculateFlightProgress(for flight: FlightDetail) {
        let status = flight.status?.lowercased() ?? ""
        
        // Get best available times
        let departureTime = getBestTime(
            actual: flight.departure.actual?.utc,
            estimated: flight.departure.estimated?.utc,
            scheduled: flight.departure.scheduled.utc
        )
        
        let arrivalTime = getBestTime(
            actual: flight.arrival.actual?.utc,
            estimated: flight.arrival.estimated?.utc,
            scheduled: flight.arrival.scheduled.utc
        )
        
        guard let depTime = departureTime,
              let arrTime = arrivalTime else {
            flightPathProgress = 0.0
            return
        }
        
        let currentTime = Date()
        
        // Calculate progress based on status
        switch status {
        case let s where s.contains("scheduled") || s.contains("boarding") || s.contains("delayed"):
            flightPathProgress = 0.0
            
        case let s where s.contains("arrived") || s.contains("landed"):
            flightPathProgress = 1.0
            
        case let s where s.contains("air") || s.contains("enroute") || s.contains("en-route") || s.contains("active"):
            // Calculate progress based on time elapsed
            let totalFlightDuration = arrTime.timeIntervalSince(depTime)
            let elapsedTime = currentTime.timeIntervalSince(depTime)
            let progress = max(0.0, min(1.0, elapsedTime / totalFlightDuration))
            flightPathProgress = progress
            
        case let s where s.contains("departed") || s.contains("takeoff") || s.contains("airborne"):
            // If just departed, show small progress
            flightPathProgress = 0.1
            
        default:
            // Default case - check time-based calculation
            if currentTime < depTime {
                flightPathProgress = 0.0
            } else if currentTime > arrTime {
                flightPathProgress = 1.0
            } else {
                let totalFlightDuration = arrTime.timeIntervalSince(depTime)
                let elapsedTime = currentTime.timeIntervalSince(depTime)
                flightPathProgress = max(0.0, min(1.0, elapsedTime / totalFlightDuration))
            }
        }
        
        print("✈️ Flight Progress: \(flightPathProgress) for status: \(status)")
    }
    
    private func getBestTime(actual: String?, estimated: String?, scheduled: String?) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        // Priority: actual > estimated > scheduled
        if let actual = actual, let date = formatter.date(from: actual) {
            return date
        }
        if let estimated = estimated, let date = formatter.date(from: estimated) {
            return date
        }
        if let scheduled = scheduled, let date = formatter.date(from: scheduled) {
            return date
        }
        return nil
    }
    
    // Add flight to recently viewed when screen is dismissed
    private func addToRecentlyViewed(_ flight: FlightDetail) {
        let trackedFlight = TrackedFlightData(
            id: "\(flightNumber)_\(date)",
            flightNumber: flight.flightIata,
            airlineName: flight.airline.name,
            status: flight.status ?? "Unknown",
            departureTime: formatTime(flight.departure.scheduled.local),
            departureAirport: flight.departure.airport.iataCode,
            departureDate: formatDateOnly(flight.departure.scheduled.local),
            arrivalTime: formatTime(flight.arrival.scheduled.local),
            arrivalAirport: flight.arrival.airport.iataCode,
            arrivalDate: formatDateOnly(flight.arrival.scheduled.local),
            duration: calculateDuration(departure: flight.departure.scheduled.local, arrival: flight.arrival.scheduled.local),
            flightType: "Direct",
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
            print("✅ Flight details loaded successfully")
        } catch {
            self.error = error.localizedDescription
            print("❌ Flight detail fetch error: \(error)")
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

    // MARK: - Compact Annotation View
    struct CompactAnnotationView: View {
        let annotation: FlightAnnotation
        
        var body: some View {
            VStack(spacing: 2) {
//                Circle()
//                    .fill(annotation.type == .departure ? Color.green : Color.red)
//                    .frame(width: 8, height: 8)
//
//                Text(annotation.airportCode)
//                    .font(.system(size: 8, weight: .bold))
//                    .foregroundColor(.white)
//                    .padding(.horizontal, 4)
//                    .padding(.vertical, 1)
//                    .background(
//                        RoundedRectangle(cornerRadius: 2)
//                            .fill(annotation.type == .departure ? Color.green : Color.red)
//                    )
            }
        }
    }
    
}

// MARK: - Enhanced Flight Path Overlay with Color Coding and Improved Rotation
struct EnhancedFlightPathOverlay: View {
    let departureCoord: CLLocationCoordinate2D
    let arrivalCoord: CLLocationCoordinate2D
    let mapRegion: MKCoordinateRegion
    let flightIconPosition: CLLocationCoordinate2D?
    let arcPathPoints: [CLLocationCoordinate2D]
    let isAnimating: Bool
    let flightProgress: Double
    let pathAnimationProgress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Draw traveled path (violet solid line)
                if arcPathPoints.count > 1 && flightProgress > 0 {
                    let traveledCount = max(1, Int(Double(arcPathPoints.count) * flightProgress * pathAnimationProgress))
                    let traveledPoints = Array(arcPathPoints.prefix(traveledCount))
                    
                    Path { path in
                        let points = traveledPoints.compactMap { coord in
                            convertCoordinateToPoint(coord, in: geometry.size)
                        }
                        
                        if let firstPoint = points.first {
                            path.move(to: firstPoint)
                            for point in points.dropFirst() {
                                path.addLine(to: point)
                            }
                        }
                    }
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.purple.opacity(0.9),
                                Color(red: 0.7, green: 0.3, blue: 0.9, opacity: 0.8),
                                Color.purple.opacity(0.9)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .shadow(color: Color.purple.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                
                // Draw remaining path (dotted blue line)
                if arcPathPoints.count > 1 && flightProgress < 1.0 && pathAnimationProgress > 0.3 {
                    let traveledCount = Int(Double(arcPathPoints.count) * flightProgress)
                    let remainingPoints = Array(arcPathPoints.suffix(from: max(0, traveledCount)))
                    
                    Path { path in
                        let points = remainingPoints.compactMap { coord in
                            convertCoordinateToPoint(coord, in: geometry.size)
                        }
                        
                        if let firstPoint = points.first {
                            path.move(to: firstPoint)
                            for point in points.dropFirst() {
                                path.addLine(to: point)
                            }
                        }
                    }
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.7),
                                Color.cyan.opacity(0.5),
                                Color.blue.opacity(0.7)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 0.3, lineCap: .round, dash: [1, 1])
                    )
                    .opacity(pathAnimationProgress)
                }
                
                // Enhanced Flight icon with better rotation
                if let flightPos = flightIconPosition, pathAnimationProgress > 0.5 {
                    let iconPoint = convertCoordinateToPoint(flightPos, in: geometry.size)
                    
                    ZStack {
                        // Animated pulsing background circle
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.blue.opacity(0.4),
                                        Color.blue.opacity(0.1),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 20
                                )
                            )
                            .frame(width: 40, height: 40)
                            .scaleEffect(isAnimating ? 1.3 : 0.8)
                            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
                        
                        // Flight icon shadow
                        Image("FlyingFlight")
                            .resizable()
                            .frame(width: 26, height: 26)
                            .foregroundColor(.black.opacity(0.3))
                            .rotationEffect(.degrees(calculateEnhancedFlightRotation()))
                            .offset(x: 1, y: 1)
                        
                        // Main flight icon
                        Image("FlyingFlight")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(calculateEnhancedFlightRotation()))
                            .scaleEffect(isAnimating ? 1.1 : 0.9)
                            .animation(.easeInOut(duration: 1.0), value: isAnimating)
                            .shadow(color: .blue.opacity(0.5), radius: 3, x: 0, y: 0)
                    }
                    .position(iconPoint)
                    .opacity(pathAnimationProgress)
                }
                
                // Add airport markers with enhanced design
                airportMarkers(in: geometry)
            }
        }
    }
    
    private func airportMarkers(in geometry: GeometryProxy) -> some View {
        Group {
            // Departure marker
            let depPoint = convertCoordinateToPoint(departureCoord, in: geometry.size)
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 24, height: 24)
                Circle()
                    .fill(Color.purple)
                    .frame(width: 12, height: 12)
                Circle()
                    .stroke(Color.purple, lineWidth: 2)
                    .frame(width: 12, height: 12)
            }
            .position(depPoint)
            .scaleEffect(pathAnimationProgress)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: pathAnimationProgress)
            
            // Arrival marker
            let arrPoint = convertCoordinateToPoint(arrivalCoord, in: geometry.size)
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 24, height: 24)
                Circle()
                    .fill(Color.blue)
                    .frame(width: 12, height: 12)
                Circle()
                    .stroke(Color.blue, lineWidth: 2)
                    .frame(width: 12, height: 12)
            }
            .position(arrPoint)
            .scaleEffect(pathAnimationProgress)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: pathAnimationProgress)
        }
    }
    
    private func convertCoordinateToPoint(_ coordinate: CLLocationCoordinate2D, in size: CGSize) -> CGPoint {
        let latDelta = mapRegion.span.latitudeDelta
        let lngDelta = mapRegion.span.longitudeDelta
        
        let x = (coordinate.longitude - (mapRegion.center.longitude - lngDelta/2)) / lngDelta * size.width
        let y = ((mapRegion.center.latitude + latDelta/2) - coordinate.latitude) / latDelta * size.height
        
        return CGPoint(x: x, y: y)
    }
    
    private func calculateEnhancedFlightRotation() -> Double {
        // Calculate rotation based on flight path direction at current position
        guard arcPathPoints.count > 2 else {
            return calculateBasicRotation()
        }
        
        let progressIndex = Int(Double(arcPathPoints.count - 1) * flightProgress)
        let currentIndex = min(max(progressIndex, 1), arcPathPoints.count - 2)
        
        // Get points before and after current position for better direction calculation
        let beforePoint = arcPathPoints[currentIndex - 1]
        let afterPoint = arcPathPoints[min(currentIndex + 1, arcPathPoints.count - 1)]
        
        // Calculate direction vector
        let deltaLng = afterPoint.longitude - beforePoint.longitude
        let deltaLat = afterPoint.latitude - beforePoint.latitude
        
        // Calculate angle in degrees
        let angleRadians = atan2(deltaLng, deltaLat)
        let angleDegrees = angleRadians * 180 / .pi
        
        // Adjust for icon orientation (assuming icon points upward by default)
        return angleDegrees
    }
    
    private func calculateBasicRotation() -> Double {
        // Fallback rotation calculation
        let deltaLng = arrivalCoord.longitude - departureCoord.longitude
        let deltaLat = arrivalCoord.latitude - departureCoord.latitude
        
        let angle = atan2(deltaLng, deltaLat) * 180 / .pi
        return angle + 90
    }
}

// MARK: - Map Support Models and Views

enum AirportType {
    case departure
    case arrival
}

struct FlightAnnotation: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let airportCode: String
    let type: AirportType
}

struct sFlightPathView: View {
    let coordinates: [CLLocationCoordinate2D]
    
    var body: some View {
        if coordinates.count >= 2 {
            Path { path in
                let start = coordinates[0]
                let end = coordinates[1]
                
                // Convert coordinates to view space would need proper map projection
                // For now, we'll use a simple straight line overlay
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

// MARK: - Supporting Views (keeping original design)

struct AirlinesInfo: View {
    let airline: FlightDetailAirline
    
    var body: some View {
        VStack(alignment:.leading, spacing: 12){
            Text("Airline Information")
                .font(.system(size: 18, weight: .semibold))
                .padding(.top, 15)
            HStack{
                AirlineLogoView(
                    iataCode: airline.iataCode,
                    fallbackImage: "FlightTrackLogo",
                    size: 34
                )
                Text(airline.name)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
            }
            HStack{
                VStack {
                    Text("ATC Callsign")
                    Text(airline.callsign ?? "N/A")
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
                    Text("\(airline.totalAircrafts ?? 0)")
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
                    Text("\(String(format: "%.1f", airline.averageFleetAge ?? 0.0))y")
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

// MARK: - UPDATED Map Shimmer View
struct MapShimmerView: View {
    @State private var shimmerOffset: CGFloat = -200
    
    var body: some View {
        ZStack {
            // Base background - more map-like
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.green.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Route visualization shimmer
            VStack(spacing: 30) {
                Spacer()
                
                HStack {
                    // Departure point shimmer
                    VStack(spacing: 4) {
                        Circle()
                            .fill(Color.green.opacity(0.6))
                            .frame(width: 12, height: 12)
                            .modifier(ShimmerModifier())
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 16)
                            .modifier(ShimmerModifier())
                    }
                    
                    Spacer()
                    
                    // Route line shimmer - curved path
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 20))
                        path.addQuadCurve(
                            to: CGPoint(x: 100, y: 20),
                            control: CGPoint(x: 50, y: -10)
                        )
                    }
                    .stroke(
                        Color.blue.opacity(0.4),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 3])
                    )
                    .frame(height: 40)
                    .modifier(ShimmerModifier())
                    
                    Spacer()
                    
                    // Arrival point shimmer
                    VStack(spacing: 4) {
                        Circle()
                            .fill(Color.red.opacity(0.6))
                            .frame(width: 12, height: 12)
                            .modifier(ShimmerModifier())
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 16)
                            .modifier(ShimmerModifier())
                    }
                }
                .padding(.horizontal, 40)
                
                // Loading text with better animation
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "airplane")
                            .foregroundColor(.blue)
                            .font(.system(size: 16))
                        
                        Text("Loading Flight Route")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    
                    // Custom loading dots
                    HStack(spacing: 4) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 6, height: 6)
                                .scaleEffect(shimmerOffset == CGFloat(index) ? 1.2 : 0.8)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                    value: shimmerOffset
                                )
                        }
                    }
                }
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 200
            }
        }
    }
}

// MARK: - Shimmer Modifier for Map Loading
struct ShimmerModifier: ViewModifier {
    @State private var animation = false
    
    func body(content: Content) -> some View {
        content
            .mask(
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .white.opacity(0.5), .clear]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .rotationEffect(.degrees(70))
                .offset(x: animation ? 200 : -200)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    animation.toggle()
                }
            }
    }
}

#Preview {
    FlightDetailScreen(flightNumber: "6E 703", date: "20250618")
}
