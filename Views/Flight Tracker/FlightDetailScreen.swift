import SwiftUI
import MapKit



// Custom annotation for flight icon
class FlightMapIconAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
    var rotation: Double = 0
}

// Updated MapFlightIconView to use your custom FlyingFlight image
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
            
            // Flight icon - CHANGED: Use your custom FlyingFlight image
            Image("FlyingFlight") // Using your custom asset instead of SF Symbol
                .resizable()
                .frame(width: 20, height: 20) // Slightly larger for better visibility
                .foregroundColor(.white)
                .rotationEffect(.degrees(rotation))
                .shadow(color: .blue.opacity(0.5), radius: 2, x: 0, y: 0)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// Fixed FlightMapView with simplified flight icon logic
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
        
        // Optimize for smooth animation
        optimizeMapPerformance(map)
        
        let region = calculateOptimalRegionWithBottomSheet()
        map.setRegion(region, animated: false)
        
        print("🗺️ Created MKMapView with region: \(region)")
        return map
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Reduce unnecessary updates by checking for meaningful changes
        let progressDiff = abs(context.coordinator.lastFlightProgress - flightProgress)
        let pathProgressDiff = abs(context.coordinator.lastPathProgress - pathAnimationProgress)
        
        let shouldUpdate = progressDiff > 0.001 || // Only update if progress changed significantly
                          pathProgressDiff > 0.001 ||
                          context.coordinator.lastShowPath != showFlightPath
        
        guard shouldUpdate else { return }
        
        // Update coordinator state
        context.coordinator.lastFlightProgress = flightProgress
        context.coordinator.lastPathProgress = pathAnimationProgress
        context.coordinator.lastShowPath = showFlightPath
        
        // Clear and rebuild overlays efficiently
        uiView.removeOverlays(uiView.overlays)
        let existingFlightIcons = uiView.annotations.filter { $0 is FlightMapIconAnnotation }
        uiView.removeAnnotations(existingFlightIcons)
        
        // Add airport annotations only once
        if uiView.annotations.filter({ $0.title == "Departure" || $0.title == "Arrival" }).isEmpty {
            addAirportAnnotations(to: uiView)
        }
        
        // Add flight path overlays if available
        if showFlightPath && !arcPathPoints.isEmpty {
            addFlightPathOverlays(to: uiView)
            
            // Animate region only once
            if !context.coordinator.hasAnimatedToRegion {
                context.coordinator.hasAnimatedToRegion = true
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    private func calculateOptimalRegionWithBottomSheet() -> MKCoordinateRegion {
        let flightCenterLat = (departure.latitude + arrival.latitude) / 2
        let flightCenterLng = (departure.longitude + arrival.longitude) / 2
        
        let latDelta = abs(departure.latitude - arrival.latitude)
        let lngDelta = abs(departure.longitude - arrival.longitude)
        
        // Calculate the radius that includes both airports with padding
        let maxDelta = max(latDelta, lngDelta)
        let radiusPadding = max(maxDelta * 0.3, 1.0) // 30% padding or minimum 1 degree
        
        // For 80% height, we need to account for the visible area being smaller
        // Adjust the latitude span to ensure both airports are visible in the 80% area
        let heightFactor = 0.8 // 80% of screen height
        let adjustedLatSpan = max(latDelta + (2 * radiusPadding), 2.0) / heightFactor
        let adjustedLngSpan = max(lngDelta + (2 * radiusPadding), 2.0)
        
        // Position the center slightly lower to account for the 80% height constraint
        // This ensures both airports appear in the visible 80% area
        let centerOffsetFactor = (1.0 - heightFactor) / 2 // Offset by 10% of span
        let mapCenterLat = flightCenterLat - (adjustedLatSpan * centerOffsetFactor)
        let mapCenterLng = flightCenterLng
        
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: mapCenterLat, longitude: mapCenterLng),
            span: MKCoordinateSpan(
                latitudeDelta: adjustedLatSpan,
                longitudeDelta: adjustedLngSpan
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
        print("✈️ Added airport annotations")
    }
    private func optimizeMapPerformance(_ mapView: MKMapView) {
        // Reduce map rendering during animation
        mapView.isUserInteractionEnabled = false
        
        // Re-enable after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            mapView.isUserInteractionEnabled = true
        }
    }
    
    private func addFlightPathOverlays(to mapView: MKMapView) {
        guard arcPathPoints.count > 1 else {
            print("❌ No arc path points available")
            return
        }
        
        let totalPoints = arcPathPoints.count
        let traveledCount = Int(Double(totalPoints) * flightProgress * pathAnimationProgress)
        
        // Always show the complete route outline (faint)
        if pathAnimationProgress > 0.1 {
            let completeRoutePolyline = MKPolyline(coordinates: arcPathPoints, count: arcPathPoints.count)
            completeRoutePolyline.title = "complete_route"
            mapView.addOverlay(completeRoutePolyline)
        }
        
        // Add progressively drawn traveled path
        if traveledCount >= 2 { // Ensure at least 2 points for a line
            let traveledPoints = Array(arcPathPoints.prefix(traveledCount))
            let traveledPolyline = MKPolyline(coordinates: traveledPoints, count: traveledPoints.count)
            traveledPolyline.title = "traveled"
            mapView.addOverlay(traveledPolyline)
        }
        
        // Add flight icon at current position
        if !arcPathPoints.isEmpty && flightProgress > 0.001 && pathAnimationProgress > 0.1 {
            let iconIndex = min(max(Int(Double(totalPoints - 1) * flightProgress), 0), totalPoints - 1)
            let flightIconAnnotation = FlightMapIconAnnotation()
            flightIconAnnotation.coordinate = arcPathPoints[iconIndex]
            flightIconAnnotation.rotation = calculateFlightRotation(at: iconIndex)
            
            mapView.addAnnotation(flightIconAnnotation)
        }
    }
    
    private func calculateFlightRotation(at index: Int) -> Double {
        guard index >= 0 && index < arcPathPoints.count else {
            print("⚠️ Invalid rotation index: \(index)")
            return 0
        }
        
        // Simple rotation calculation
        if index == 0 && arcPathPoints.count > 1 {
            let current = arcPathPoints[0]
            let next = arcPathPoints[1]
            let angle = atan2(next.longitude - current.longitude, next.latitude - current.latitude) * 180 / .pi
            
            return angle
        }
        
        if index == arcPathPoints.count - 1 && index > 0 {
            let previous = arcPathPoints[index - 1]
            let current = arcPathPoints[index]
            let angle = atan2(current.longitude - previous.longitude, current.latitude - previous.latitude) * 180 / .pi
            print("🧭 Last point rotation: \(angle)°")
            return angle
        }
        
        if index > 0 && index < arcPathPoints.count - 1 {
            let beforePoint = arcPathPoints[index - 1]
            let afterPoint = arcPathPoints[index + 1]
            let angle = atan2(afterPoint.longitude - beforePoint.longitude, afterPoint.latitude - beforePoint.latitude) * 180 / .pi
            return angle
        }
        
        print("🧭 Default rotation: 0°")
        return 0
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var lastFlightProgress: Double = -1
            var lastPathProgress: Double = -1
            var lastShowPath: Bool = false
            var hasAnimatedToRegion: Bool = false
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                
                if polyline.title == "complete_route" {
                    // Faint complete route outline
                    renderer.strokeColor = UIColor.white.withAlphaComponent(2.9)
                    renderer.lineWidth = 2
                    renderer.lineCap = .round
                    renderer.lineDashPattern = [2, 4] // Subtle dashed line
                    
                } else if polyline.title == "traveled" {
                    // Progressive traveled path with gradient effect
                    renderer.strokeColor = UIColor.systemPurple
                    renderer.lineWidth = 4
                    renderer.lineCap = .round
                    
                } else if polyline.title == "remaining" {
                    renderer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.5)
                    renderer.lineWidth = 3
                    renderer.lineCap = .round
                    renderer.lineDashPattern = [5, 3]
                    
                }
                
                return renderer
            }
            return MKOverlayRenderer()
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            
            
            // Handle flight icon annotation
            if let flightAnnotation = annotation as? FlightMapIconAnnotation {
                
                
                let identifier = "FlightIcon"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = false
                }
                
                // SIMPLIFIED: Create icon directly instead of using SwiftUI conversion
                let iconImage = createFlightIcon(rotation: flightAnnotation.rotation)
                annotationView?.image = iconImage
                annotationView?.centerOffset = CGPoint(x: 0, y: 0)
                annotationView?.annotation = annotation
                
                
                return annotationView
            }
            
            // Handle airport annotations
            if annotation.title == "Departure" {
                let identifier = "Departure"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                }
                
                annotationView?.image = createAirportIcon(color: UIColor.black.withAlphaComponent(0.7), size: 12)
                annotationView?.centerOffset = CGPoint(x: 0, y: 0)
                
                
                return annotationView
            } else if annotation.title == "Arrival" {
                let identifier = "Arrival"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                }
                
                annotationView?.image = createAirportIcon(color: UIColor.black.withAlphaComponent(0.7), size: 12)
                annotationView?.centerOffset = CGPoint(x: 0, y: 0)
                
                
                return annotationView
            }
            
            print("⚠️ No annotation view created for: \(annotation)")
            return nil
        }
        
        private func createFlightIcon(rotation: Double) -> UIImage {
            let size = CGSize(width: 40, height: 40)
            let renderer = UIGraphicsImageRenderer(size: size)
            
            return renderer.image { context in
                let cgContext = context.cgContext
                
                // Add smooth shadow for better visibility
                cgContext.setShadow(offset: CGSize(width: 1, height: 1), blur: 2, color: UIColor.black.withAlphaComponent(0.3).cgColor)
                
                // Try to load and draw the custom image
                if let flightImage = UIImage(named: "FlyingFlight") {
                    
                    
                    // Apply rotation with smooth interpolation
                    cgContext.saveGState()
                    cgContext.translateBy(x: size.width/2, y: size.height/2)
                    
                    // Smooth rotation interpolation
                    let smoothRotation = rotation * .pi / 180
                    cgContext.rotate(by: smoothRotation)
                    cgContext.translateBy(x: -10, y: -10)
                    
                    // Draw with anti-aliasing for smoother appearance
                    cgContext.setAllowsAntialiasing(true)
                    cgContext.interpolationQuality = .high
                    
                    flightImage.draw(in: CGRect(x: 0, y: 0, width: 20, height: 20))
                    cgContext.restoreGState()
                } else {
                    
                    
                    // Smooth fallback airplane shape
                    cgContext.setFillColor(UIColor.white.cgColor)
                    cgContext.setAllowsAntialiasing(true)
                    cgContext.saveGState()
                    cgContext.translateBy(x: size.width/2, y: size.height/2)
                    cgContext.rotate(by: rotation * .pi / 180)
                    
                    // Draw smoother airplane shape
                    let airplanePath = UIBezierPath()
                    airplanePath.move(to: CGPoint(x: 0, y: -8))
                    airplanePath.addCurve(to: CGPoint(x: -6, y: 2), controlPoint1: CGPoint(x: -3, y: -5), controlPoint2: CGPoint(x: -5, y: -1))
                    airplanePath.addLine(to: CGPoint(x: -2, y: 2))
                    airplanePath.addLine(to: CGPoint(x: -1, y: 6))
                    airplanePath.addLine(to: CGPoint(x: 1, y: 6))
                    airplanePath.addLine(to: CGPoint(x: 2, y: 2))
                    airplanePath.addCurve(to: CGPoint(x: 6, y: 2), controlPoint1: CGPoint(x: 5, y: -1), controlPoint2: CGPoint(x: 3, y: -5))
                    airplanePath.close()
                    
                    airplanePath.fill()
                    cgContext.restoreGState()
                }
            }
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

// Add this new struct for share functionality
struct FlightShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiView: UIActivityViewController, context: Context) {}
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
    @State private var flightPathProgress: Double = 0.1
    @State private var flightIconPosition: CLLocationCoordinate2D?
    @State private var arcPathPoints: [CLLocationCoordinate2D] = []
    @State private var isAnimating = false
    @State private var pathAnimationProgress: Double = 1.0
    @State private var showFlightPath = false
    
    // ADD THESE NEW ANIMATION STATES:
    @State private var animatedFlightProgress: Double = 0.0
    @State private var animatedPathProgress: Double = 0.0
    @State private var isInitialAnimationComplete = false
    @State private var animatedPathDrawingProgress: Double = 0.0
    
    // ADD: Share functionality state
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    
    private let networkManager = FlightTrackNetworkManager.shared

    // Default initializer for backward compatibility
    init(flightNumber: String, date: String, onFlightViewed: ((TrackedFlightData) -> Void)? = nil) {
        self.flightNumber = flightNumber
        self.date = date
        self.onFlightViewed = onFlightViewed
    }
    
    

    var body: some View {
        NavigationView {
                GeometryReader { geometry in
                    ZStack(alignment: .top) { // Add top alignment to ZStack
                        if let departure = departureAnnotation?.coordinate,
                           let arrival = arrivalAnnotation?.coordinate {
                            FlightMapView(
                                departure: departure,
                                arrival: arrival,
                                arcPathPoints: arcPathPoints,
                                flightProgress: animatedFlightProgress,
                                pathAnimationProgress: animatedPathProgress,
                                showFlightPath: showFlightPath
                            )
                            .frame(height: geometry.size.height * 0.8) // Limit to 60% of screen height
                            .frame(maxWidth: .infinity) // Keep full width
                            .clipped() // Clip any overflow
                        } else {
                            MapShimmerView()
                                .frame(height: geometry.size.height * 0.8) // Same height limit for shimmer
                                .frame(maxWidth: .infinity)
                                .clipped()
                        }

                        // Gradient overlay - also limit to same height
                        GradientColor.FTHGradient
                            .frame(height: geometry.size.height * 0.8)
                            .frame(maxWidth: .infinity)
                            .blendMode(.overlay)
                            .allowsHitTesting(false)
                    }
                    .ignoresSafeArea(.all, edges: .top) // Move ignoresSafeArea to the ZStack level
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    // Your existing toolbar items...
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
                            shareFlightDetails()
                        }) {
                            Image("FilterShare")
                        }
                    }
                }
                // Rest of your existing code...
                .onAppear {
//                    FlightTrackNetworkManager.shared.useMockData = true
                    Task {
                        await fetchFlightDetails()
                    }
                }
                .onDisappear {
//                    FlightTrackNetworkManager.shared.useMockData = false
                    
                    if let flightDetail = flightDetail, let onFlightViewed = onFlightViewed {
                        addToRecentlyViewed(flightDetail)
                    }
                }
                .onChange(of: flightDetail?.flightIata) { _ in
                    if let flight = flightDetail {
                        setupMapData(for: flight)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.easeInOut(duration: 0.6)) {
                                showMap = true
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                animateFlightPath()
                            }
                        }
                    }
                }
                .sheet(isPresented: .constant(true)) {
                    bottomSheetContent()
                        .presentationDetents([.medium, .fraction(0.95)])
                        .presentationDragIndicator(.visible)
                        .presentationBackground(Color.white)
                        .interactiveDismissDisabled(true)
                        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                        .sheet(isPresented: $showShareSheet) {
                            ShareSheet(items: shareItems)
                                .presentationDetents([.medium])
                                .presentationDragIndicator(.visible)
                        }
                }
            }
            .navigationBarBackButtonHidden(true)    }
    
    // ADD: Share functionality
    private func shareFlightDetails() {
        guard let flight = flightDetail else {
            // Fallback share content if flight details aren't loaded yet
            shareItems = [
                "Flight \(flightNumber) - \(formatDateForDisplay(date))",
                "Track this flight with FlightTrack app!"
            ]
            showShareSheet = true
            return
        }
        
        // Create comprehensive share content
        let flightInfo = """
        ✈️ Flight \(flight.flightIata) - \(flight.airline.name)
        
        📅 \(formatDateForDisplay(date))
        
        🛫 Departure: \(flight.departure.airport.city ?? flight.departure.airport.name) (\(flight.departure.airport.iataCode))
        ⏰ \(formatTime(flight.departure.scheduled.local))
        
        🛬 Arrival: \(flight.arrival.airport.city ?? flight.arrival.airport.name) (\(flight.arrival.airport.iataCode))
        ⏰ \(formatTime(flight.arrival.scheduled.local))
        
        ⏱️ Duration: \(calculateDuration(departure: flight.departure.scheduled.local, arrival: flight.arrival.scheduled.local))
        
        
        📊 Status: \(flight.status ?? "Unknown")
        
        Track flights with AllFlights app! 🚀
        """
        
        shareItems = [flightInfo]
        showShareSheet = true
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
    
    
    // UPDATED: setupMapData with forced top positioning
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
        
        // Set map annotations
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
        
        // Calculate optimal region with dynamic zoom
        let region = calculateOptimalRegionForBottomSheet()
        mapRegion = region
        
        // Calculate flight path and position
        calculateFlightProgress(for: flight)
        generateSmartArcPath(from: departureCoordinate, to: arrivalCoordinate)
        
        print("✅ Map data setup complete with dynamic zoom - Region: \(region)")
        print("📍 Departure: \(departureCoordinate)")
        print("📍 Arrival: \(arrivalCoordinate)")
        print("📏 Distance: \(sqrt(pow(abs(departureCoordinate.latitude - arrivalCoordinate.latitude), 2) + pow(abs(departureCoordinate.longitude - arrivalCoordinate.longitude), 2))) degrees")
    }


    private func startSmoothFlightAnimation() {
        
        
        // Much faster animation
        let animationDuration: Double = 3.5 // Reduced from 6.0
        let frameRate: Double = 30.0
        let totalFrames = Int(animationDuration * frameRate)
        let targetProgress = flightPathProgress
        
        var currentFrame = 0
        
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0/frameRate, repeats: true) { timer in
            currentFrame += 1
            let progress = Double(currentFrame) / Double(totalFrames)
            
            if progress >= 1.0 {
                // Ensure final values are set exactly
                animatedFlightProgress = targetProgress
                animatedPathDrawingProgress = targetProgress
                timer.invalidate()
                isInitialAnimationComplete = true
                
            } else {
                // Use smooth easing
                let easedProgress = easeInOut(progress)
                let currentProgressValue = easedProgress * targetProgress
                
                // Update both simultaneously for perfect coordination
                DispatchQueue.main.async {
                    self.animatedFlightProgress = currentProgressValue
                    self.animatedPathDrawingProgress = currentProgressValue
                }
                
                // Debug every 60 frames (every second)
                if currentFrame % 60 == 0 {
                    print("🎬 Animation progress: \(Int(progress * 100))% - flight=\(String(format: "%.3f", currentProgressValue))")
                }
            }
        }
    }

    // Improved easing function for smoother animation
    private func easeInOut(_ t: Double) -> Double {
        if t < 0.5 {
            return 2 * t * t
        } else {
            return -1 + (4 - 2 * t) * t
        }
    }
    private func animateFlightPath() {
        print("🎬 Starting flight path animation with dynamic zoom")
        
        // Reset animation states
        animatedFlightProgress = 0.0
        animatedPathProgress = 1.0
        animatedPathDrawingProgress = 0.0
        isInitialAnimationComplete = false
        
        let finalRegion = calculateOptimalRegionForBottomSheet()
        
        // Start with a wider view (zoom out first)
        let initialRegion = MKCoordinateRegion(
            center: finalRegion.center,
            span: MKCoordinateSpan(
                latitudeDelta: finalRegion.span.latitudeDelta * 1.8,
                longitudeDelta: finalRegion.span.longitudeDelta * 1.8
            )
        )
        
        // Set initial wide view
        withAnimation(.easeOut(duration: 0.6)) {
            mapRegion = initialRegion
        }
        
        // Show the flight path container
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showFlightPath = true
                animatedPathProgress = 1.0
            }
        }
        
        // Zoom to optimal view smoothly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 1.2)) {
                mapRegion = finalRegion
            }
        }
        
        // Start flight animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            startSmoothFlightAnimation()
        }
        
        // Start flight icon animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                isAnimating = true
            }
        }
        
        print("🎬 Dynamic zoom animation sequence started")
        print("📊 Initial span: lat=\(initialRegion.span.latitudeDelta), lng=\(initialRegion.span.longitudeDelta)")
        print("📊 Final span: lat=\(finalRegion.span.latitudeDelta), lng=\(finalRegion.span.longitudeDelta)")
    }

    private func validateAirportVisibility(region: MKCoordinateRegion, departure: CLLocationCoordinate2D, arrival: CLLocationCoordinate2D) -> Bool {
        let heightFactor = 0.8
        let visibleLatRange = region.span.latitudeDelta * heightFactor
        let visibleLatMin = region.center.latitude - (visibleLatRange / 2)
        let visibleLatMax = region.center.latitude + (visibleLatRange / 2)
        
        let visibleLngRange = region.span.longitudeDelta
        let visibleLngMin = region.center.longitude - (visibleLngRange / 2)
        let visibleLngMax = region.center.longitude + (visibleLngRange / 2)
        
        let departureVisible = departure.latitude >= visibleLatMin && departure.latitude <= visibleLatMax &&
                              departure.longitude >= visibleLngMin && departure.longitude <= visibleLngMax
        
        let arrivalVisible = arrival.latitude >= visibleLatMin && arrival.latitude <= visibleLatMax &&
                            arrival.longitude >= visibleLngMin && arrival.longitude <= visibleLngMax
        
        print("🔍 Airport visibility check:")
        print("   Departure visible: \(departureVisible)")
        print("   Arrival visible: \(arrivalVisible)")
        print("   Visible lat range: \(visibleLatMin) to \(visibleLatMax)")
        print("   Visible lng range: \(visibleLngMin) to \(visibleLngMax)")
        
        return departureVisible && arrivalVisible
    }
    
    // UPDATED: Bottom sheet aware region calculation with forced positioning
    private func calculateOptimalRegionForBottomSheet() -> MKCoordinateRegion {
        guard let departure = departureAnnotation?.coordinate,
              let arrival = arrivalAnnotation?.coordinate else {
            return mapRegion
        }
        
        let flightCenterLat = (departure.latitude + arrival.latitude) / 2
        let flightCenterLng = (departure.longitude + arrival.longitude) / 2
        
        let latDelta = abs(departure.latitude - arrival.latitude)
        let lngDelta = abs(departure.longitude - arrival.longitude)
        
        // Dynamic radius calculation based on distance between airports
        let distance = sqrt(pow(latDelta, 2) + pow(lngDelta, 2))
        let radiusFactor = calculateRadiusFactor(for: distance)
        
        // Calculate required spans with dynamic padding
        let requiredLatSpan = max(latDelta * radiusFactor, 2.0)
        let requiredLngSpan = max(lngDelta * radiusFactor, 2.0)
        
        // For 80% height, adjust the center and span
        let heightFactor = 0.8
        let adjustedLatSpan = requiredLatSpan / heightFactor
        
        // Center adjustment to ensure both airports are visible in 80% area
        let centerOffset = adjustedLatSpan * (1.0 - heightFactor) / 2
        let mapCenterLat = flightCenterLat - centerOffset
        
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: mapCenterLat, longitude: flightCenterLng),
            span: MKCoordinateSpan(
                latitudeDelta: adjustedLatSpan,
                longitudeDelta: requiredLngSpan
            )
        )
    }
    
    private func calculateRadiusFactor(for distance: Double) -> Double {
        // Dynamic radius factor based on the distance between airports
        switch distance {
        case 0..<1:
            return 3.0  // Very close airports - zoom in more
        case 1..<5:
            return 2.5  // Close airports - moderate zoom
        case 5..<15:
            return 2.0  // Medium distance - normal zoom
        case 15..<30:
            return 1.8  // Long distance - zoom out slightly
        case 30..<60:
            return 1.6  // Very long distance - zoom out more
        default:
            return 1.4  // Transcontinental flights - maximum zoom out
        }
    }

    
    // MARK: - Enhanced Arc Path Generation with Smart Direction Based on Geography
    private func generateSmartArcPath(from departure: CLLocationCoordinate2D, to arrival: CLLocationCoordinate2D) {
        let numberOfPoints = 100
        var points: [CLLocationCoordinate2D] = []
        
        // Calculate basic direction and distance
        let latDifference = arrival.latitude - departure.latitude
        let lngDifference = arrival.longitude - departure.longitude
        let distance = sqrt(pow(latDifference, 2) + pow(lngDifference, 2))
        
        // Determine curve direction based on intelligent flight routing
        let curveMagnitude = calculateCurveMagnitude(for: distance)
        let curveDirection = determineIntelligentCurveDirection(departure: departure, arrival: arrival)
        
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
        
        print("✈️ Generated smart arc path with \(points.count) points, curve direction: \(curveDirection > 0 ? "RIGHT (arrival is LEFT of departure)" : "LEFT (arrival is RIGHT of departure)"), progress: \(flightPathProgress)")
    }

    private func calculateCurveMagnitude(for distance: Double) -> Double {
        // Dynamic curve magnitude based on distance with more realistic scaling
        switch distance {
        case 0..<3:
            return distance * 0.05  // Very minimal curve for very short flights
        case 3..<8:
            return distance * 0.12  // Small curve for short flights
        case 8..<20:
            return distance * 0.18  // Medium curve for medium flights
        case 20..<40:
            return distance * 0.25  // Larger curve for long flights
        case 40..<80:
            return distance * 0.30  // Large curve for very long flights
        default:
            return distance * 0.35  // Maximum curve for transcontinental flights
        }
    }
    
    private func determineIntelligentCurveDirection(departure: CLLocationCoordinate2D, arrival: CLLocationCoordinate2D) -> Double {
        let lngDiff = arrival.longitude - departure.longitude
        
        // Simple logic based on relative position:
        // If arrival is to the RIGHT of departure (positive longitude difference) -> curve LEFT (negative)
        // If arrival is to the LEFT of departure (negative longitude difference) -> curve RIGHT (positive)
        
        if lngDiff > 0 {
            // Arrival is to the RIGHT -> curve LEFT
            return -1.0
        } else {
            // Arrival is to the LEFT -> curve RIGHT
            return 1.0
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

    // MARK: - Enhanced Flight Icon Position Update
    private func updateFlightIconPosition() {
        guard !arcPathPoints.isEmpty else {
            flightIconPosition = nil
            return
        }
        
        let index = min(Int(flightPathProgress * Double(arcPathPoints.count - 1)), arcPathPoints.count - 1)
        flightIconPosition = arcPathPoints[max(0, index)]
        
        // Debug: Print current flight position and direction
        if index > 0 && index < arcPathPoints.count - 1 {
            let prevPoint = arcPathPoints[index - 1]
            let nextPoint = arcPathPoints[index + 1]
            let direction = calculateFlightDirection(from: prevPoint, to: nextPoint)
            print("✈️ Flight at position \(index)/\(arcPathPoints.count), heading: \(direction)°")
        }
    }
    
    private func calculateFlightDirection(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let deltaLng = to.longitude - from.longitude
        let deltaLat = to.latitude - from.latitude
        let angleRadians = atan2(deltaLng, deltaLat)
        let angleDegrees = angleRadians * 180 / .pi
        return angleDegrees
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
                            Text(calculateDuration(departure: flight.departure.scheduled.local, arrival: flight.arrival.scheduled.local))
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.vertical, 1)
                                .padding(.horizontal,3)
                                .background(
                                    Capsule()
                                        .fill(Color.white)
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.black.opacity(0.6), lineWidth: 0.5)
                                        )
                                )
                                VStack
                            {
                                Divider()
                            }
                            
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
                
                HStack{
                    Image("FTRefreshed")
                    Text("Updated just Now")
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding(.horizontal,20)
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
            .cornerRadius(20)
            
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

// MARK: - UPDATED Map Shimmer View
struct MapShimmerView: View {
    @State private var shimmerOffset: CGFloat = -200
    
    var body: some View {
        ZStack {
            // Map image that fills the entire screen (stretched or cropped)
            Image("mapImg") // Replace with your actual map image or map view.
                .resizable()
                .scaledToFill() // Ensures the image stretches or crops to fill the screen
                .edgesIgnoringSafeArea(.all) // No space around the image, it will fill the screen
                .blur(radius: 2) // Apply blur to the image
            
            // Gradient overlay that goes from top to bottom
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.6), Color.clear]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all) // Ensure the gradient covers the whole image
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

//#Preview {
//    FlightTrackNetworkManager.shared.useMockData = true
//    return FlightDetailScreen(flightNumber: "6E703", date: "20250618")
//}
