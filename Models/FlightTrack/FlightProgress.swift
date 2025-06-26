//
//  AnimatedFlightPath.swift
//  AllFlights
//
//  Created by [Your Name] on [Date]
//

import SwiftUI
import MapKit

// MARK: - Flight Path Models
struct FlightProgress {
    let status: FlightPathStatus
    let progress: Double // 0.0 to 1.0
    let currentPosition: CLLocationCoordinate2D
    let traveledPath: [CLLocationCoordinate2D]
    let remainingPath: [CLLocationCoordinate2D]
}

enum FlightPathStatus {
    case scheduled
    case departed
    case inAir
    case arrived
    case cancelled
    
    var displayText: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .departed: return "Departed"
        case .inAir: return "In Air"
        case .arrived: return "Arrived"
        case .cancelled: return "Cancelled"
        }
    }
}

// MARK: - Enhanced Flight Path View
struct AnimatedFlightPathView: View {
    let flightProgress: FlightProgress
    let mapRegion: MKCoordinateRegion
    @State private var animationProgress: Double = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            let departurePoint = coordinateToPoint(flightProgress.traveledPath.first ?? CLLocationCoordinate2D(), in: geometry, region: mapRegion)
            let arrivalPoint = coordinateToPoint(flightProgress.remainingPath.last ?? CLLocationCoordinate2D(), in: geometry, region: mapRegion)
            let currentFlightPosition = coordinateToPoint(flightProgress.currentPosition, in: geometry, region: mapRegion)
            
            ZStack {
                // Traveled path (blue)
                if flightProgress.traveledPath.count > 1 {
                    Path { path in
                        let points = flightProgress.traveledPath.map { coord in
                            coordinateToPoint(coord, in: geometry, region: mapRegion)
                        }
                        createArcPath(from: points.first!, to: currentFlightPosition, in: &path)
                    }
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.cyan.opacity(0.6)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .animation(.easeInOut(duration: 1.0), value: flightProgress.progress)
                }
                
                // Remaining path (gray)
                if flightProgress.remainingPath.count > 1 {
                    Path { path in
                        let points = flightProgress.remainingPath.map { coord in
                            coordinateToPoint(coord, in: geometry, region: mapRegion)
                        }
                        createArcPath(from: currentFlightPosition, to: points.last!, in: &path)
                    }
                    .stroke(
                        Color.gray.opacity(0.4),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [8, 4])
                    )
                }
                
                // Flight icon
                FlightIconView(
                    position: currentFlightPosition,
                    status: flightProgress.status,
                    animationProgress: animationProgress
                )
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever()) {
                        animationProgress = 1.0
                    }
                }
            }
        }
    }
    
    private func coordinateToPoint(_ coordinate: CLLocationCoordinate2D, in geometry: GeometryProxy, region: MKCoordinateRegion) -> CGPoint {
        let x = (coordinate.longitude - (region.center.longitude - region.span.longitudeDelta / 2)) / region.span.longitudeDelta * geometry.size.width
        let y = ((region.center.latitude + region.span.latitudeDelta / 2) - coordinate.latitude) / region.span.latitudeDelta * geometry.size.height
        return CGPoint(x: x, y: y)
    }
    
    private func createArcPath(from start: CGPoint, to end: CGPoint, in path: inout Path) {
        let midX = (start.x + end.x) / 2
        let midY = min(start.y, end.y) - abs(start.x - end.x) * 0.3
        let controlPoint = CGPoint(x: midX, y: midY)
        
        path.move(to: start)
        path.addQuadCurve(to: end, control: controlPoint)
    }
}

// MARK: - Flight Icon View
struct FlightIconView: View {
    let position: CGPoint
    let status: FlightPathStatus
    let animationProgress: Double
    
    var body: some View {
        ZStack {
            // Pulsing circle for in-air status
            if status == .inAir {
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                    .frame(width: 30, height: 30)
                    .scaleEffect(1.0 + sin(animationProgress * .pi * 4) * 0.3)
                    .animation(.easeInOut(duration: 2.0).repeatForever(), value: animationProgress)
            }
            
            // Flight icon
            Image(flightIconName)
                .font(.system(size: 16, weight: .bold))
//                .foregroundColor(.white)
                .padding(8)
//                .background(
//                    Circle()
//                        .fill(iconBackgroundColor)
//                        .shadow(color: Color.black.opacity(0.3), radius: 4)
//                )
                .rotationEffect(.degrees(rotationAngle))
        }
        .position(position)
    }
    
    private var flightIconName: String {
        switch status {
        case .scheduled: return "FlyingFlight"
        case .departed, .inAir: return "FlyingFlight"
        case .arrived: return "FlyingFlight"
        case .cancelled: return "FlyingFlight"
        }
    }
    
    private var iconBackgroundColor: Color {
        switch status {
        case .scheduled: return .orange
        case .departed, .inAir: return .blue
        case .arrived: return .green
        case .cancelled: return .red
        }
    }
    
    private var rotationAngle: Double {
        switch status {
        case .inAir: return 45 // Flying angle
        default: return 0
        }
    }
}

// MARK: - Flight Progress Calculator
class FlightProgressCalculator {
    
    static func calculateProgress(from flightDetail: FlightDetail) -> FlightProgress {
        let departureCoord = CLLocationCoordinate2D(
            latitude: flightDetail.departure.airport.location.lat,
            longitude: flightDetail.departure.airport.location.lng
        )
        
        let arrivalCoord = CLLocationCoordinate2D(
            latitude: flightDetail.arrival.airport.location.lat,
            longitude: flightDetail.arrival.airport.location.lng
        )
        
        let status = determineFlightStatus(flightDetail)
        let progress = calculateTimeProgress(flightDetail, status: status)
        let arcPath = generateArcPath(from: departureCoord, to: arrivalCoord)
        
        let currentPosition = interpolatePosition(along: arcPath, progress: progress)
        let traveledPath = Array(arcPath.prefix(Int(Double(arcPath.count) * progress)))
        let remainingPath = Array(arcPath.suffix(from: max(0, Int(Double(arcPath.count) * progress))))
        
        return FlightProgress(
            status: status,
            progress: progress,
            currentPosition: currentPosition,
            traveledPath: traveledPath.isEmpty ? [departureCoord] : traveledPath,
            remainingPath: remainingPath.isEmpty ? [arrivalCoord] : remainingPath
        )
    }
    
    private static func determineFlightStatus(_ flightDetail: FlightDetail) -> FlightPathStatus {
        let statusString = flightDetail.status?.lowercased() ?? ""
        let now = Date()
        
        // Parse departure time
        let departureTime = parseTime(flightDetail.departure.actual?.utc ?? flightDetail.departure.scheduled.utc)
        let arrivalTime = parseTime(flightDetail.arrival.actual?.utc ?? flightDetail.arrival.estimated?.utc ?? flightDetail.arrival.scheduled.utc)
        
        switch statusString {
        case "cancelled", "canceled":
            return .cancelled
        case "arrived", "landed":
            return .arrived
        case "departed", "airborne", "in air", "enroute":
            return .inAir
        case "scheduled":
            if let depTime = departureTime {
                if now >= depTime {
                    if let arrTime = arrivalTime, now >= arrTime {
                        return .arrived
                    } else {
                        return .inAir
                    }
                } else {
                    return .scheduled
                }
            }
            return .scheduled
        default:
            // Determine based on time
            if let depTime = departureTime {
                if now >= depTime {
                    if let arrTime = arrivalTime, now >= arrTime {
                        return .arrived
                    } else {
                        return .inAir
                    }
                } else {
                    return .scheduled
                }
            }
            return .scheduled
        }
    }
    
    private static func calculateTimeProgress(_ flightDetail: FlightDetail, status: FlightPathStatus) -> Double {
        let now = Date()
        
        guard let departureTime = parseTime(flightDetail.departure.actual?.utc ?? flightDetail.departure.scheduled.utc),
              let arrivalTime = parseTime(flightDetail.arrival.actual?.utc ?? flightDetail.arrival.estimated?.utc ?? flightDetail.arrival.scheduled.utc) else {
            
            switch status {
            case .scheduled: return 0.0
            case .departed, .inAir: return 0.5
            case .arrived: return 1.0
            case .cancelled: return 0.0
            }
        }
        
        let totalFlightDuration = arrivalTime.timeIntervalSince(departureTime)
        
        switch status {
        case .scheduled:
            return 0.0
        case .departed, .inAir:
            if now <= departureTime {
                return 0.0
            } else if now >= arrivalTime {
                return 1.0
            } else {
                let elapsedTime = now.timeIntervalSince(departureTime)
                return min(max(elapsedTime / totalFlightDuration, 0.0), 1.0)
            }
        case .arrived:
            return 1.0
        case .cancelled:
            return 0.0
        }
    }
    
    private static func parseTime(_ timeString: String?) -> Date? {
        guard let timeString = timeString else { return nil }
        
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
                return date
            }
        }
        return nil
    }
    
    private static func generateArcPath(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, points: Int = 50) -> [CLLocationCoordinate2D] {
        var path: [CLLocationCoordinate2D] = []
        
        // Create arc by adding curvature
        let midLat = (start.latitude + end.latitude) / 2
        let midLng = (start.longitude + end.longitude) / 2
        
        // Add curvature based on distance
        let distance = sqrt(pow(end.latitude - start.latitude, 2) + pow(end.longitude - start.longitude, 2))
        let curvature = distance * 0.3 // Adjust curvature as needed
        
        let controlPoint = CLLocationCoordinate2D(
            latitude: midLat + curvature,
            longitude: midLng
        )
        
        // Generate points along the quadratic bezier curve
        for i in 0...points {
            let t = Double(i) / Double(points)
            let lat = quadraticBezier(t: t, p0: start.latitude, p1: controlPoint.latitude, p2: end.latitude)
            let lng = quadraticBezier(t: t, p0: start.longitude, p1: controlPoint.longitude, p2: end.longitude)
            path.append(CLLocationCoordinate2D(latitude: lat, longitude: lng))
        }
        
        return path
    }
    
    private static func quadraticBezier(t: Double, p0: Double, p1: Double, p2: Double) -> Double {
        let oneMinusT = 1.0 - t
        return oneMinusT * oneMinusT * p0 + 2.0 * oneMinusT * t * p1 + t * t * p2
    }
    
    private static func interpolatePosition(along path: [CLLocationCoordinate2D], progress: Double) -> CLLocationCoordinate2D {
        guard !path.isEmpty else { return CLLocationCoordinate2D() }
        
        if progress <= 0.0 { return path.first! }
        if progress >= 1.0 { return path.last! }
        
        let index = Double(path.count - 1) * progress
        let lowerIndex = Int(index)
        let upperIndex = min(lowerIndex + 1, path.count - 1)
        
        if lowerIndex == upperIndex {
            return path[lowerIndex]
        }
        
        let t = index - Double(lowerIndex)
        let coord1 = path[lowerIndex]
        let coord2 = path[upperIndex]
        
        return CLLocationCoordinate2D(
            latitude: coord1.latitude + (coord2.latitude - coord1.latitude) * t,
            longitude: coord1.longitude + (coord2.longitude - coord1.longitude) * t
        )
    }
}

