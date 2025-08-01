import SwiftUI
import MapKit

struct CurvedFlightMapView: UIViewRepresentable {
    let departure: CLLocationCoordinate2D
    let arrival: CLLocationCoordinate2D
    let progress: Double // 0.0 to 1.0

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator

        // Center map
        let centerLat = (departure.latitude + arrival.latitude) / 2
        let centerLng = (departure.longitude + arrival.longitude) / 2
        let latDelta = abs(departure.latitude - arrival.latitude) * 1.5
        let lngDelta = abs(departure.longitude - arrival.longitude) * 1.5

        mapView.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng),
            span: MKCoordinateSpan(
                latitudeDelta: max(latDelta, 1.0),
                longitudeDelta: max(lngDelta, 1.0)
            )
        )

        mapView.isUserInteractionEnabled = false // Optional: disable gestures

        context.coordinator.setup(mapView: mapView, departure: departure, arrival: arrival, progress: progress)

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        context.coordinator.updateFlightProgress(progress)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        private var flightLayer: CAShapeLayer?
        private var progressLayer: CAShapeLayer?
        private var iconLayer: CALayer?
        private var arcPoints: [CGPoint] = []
        private weak var mapView: MKMapView?

        func setup(mapView: MKMapView, departure: CLLocationCoordinate2D, arrival: CLLocationCoordinate2D, progress: Double) {
            self.mapView = mapView

            let points = generateArcPoints(from: departure, to: arrival, on: mapView)
            self.arcPoints = points

            drawFlightPath(on: mapView, points: points, progress: progress)
            drawFlightIcon(on: mapView, at: progress)
        }

        func updateFlightProgress(_ progress: Double) {
            guard mapView != nil else { return }
            updateFlightIcon(progress: progress)
            updateTraveledPath(progress: progress)
        }

        private func drawFlightPath(on mapView: MKMapView, points: [CGPoint], progress: Double) {
            let path = UIBezierPath()
            path.move(to: points.first!)
            for pt in points.dropFirst() {
                path.addLine(to: pt)
            }

            // Full path - light blue (remaining)
            let background = CAShapeLayer()
            background.path = path.cgPath
            background.strokeColor = UIColor.systemBlue.withAlphaComponent(0.25).cgColor
            background.lineWidth = 4
            background.lineDashPattern = [6, 4]
            background.fillColor = UIColor.clear.cgColor

            mapView.layer.addSublayer(background)
            self.flightLayer = background

            // Progress path - purple (traveled)
            let progressPath = UIBezierPath()
            let endIndex = max(1, Int(Double(points.count - 1) * progress))
            progressPath.move(to: points.first!)
            for pt in points[1...endIndex] {
                progressPath.addLine(to: pt)
            }

            let progressLayer = CAShapeLayer()
            progressLayer.path = progressPath.cgPath
            progressLayer.strokeColor = UIColor.purple.cgColor
            progressLayer.lineWidth = 4
            progressLayer.fillColor = UIColor.clear.cgColor

            mapView.layer.addSublayer(progressLayer)
            self.progressLayer = progressLayer
        }

        private func drawFlightIcon(on mapView: MKMapView, at progress: Double) {
            guard !arcPoints.isEmpty else { return }

            let index = min(Int(progress * Double(arcPoints.count - 1)), arcPoints.count - 1)
            let iconCenter = arcPoints[index]

            let icon = CALayer()
            icon.contents = UIImage(named: "FlyingFlight")?.cgImage
            icon.frame = CGRect(x: iconCenter.x - 12, y: iconCenter.y - 12, width: 24, height: 24)
            icon.opacity = 1.0
            mapView.layer.addSublayer(icon)

            self.iconLayer = icon
        }

        private func updateFlightIcon(progress: Double) {
            guard !arcPoints.isEmpty, let icon = iconLayer else { return }

            let index = min(Int(progress * Double(arcPoints.count - 1)), arcPoints.count - 1)
            let pt = arcPoints[index]

            CATransaction.begin()
            CATransaction.setAnimationDuration(0.25)
            icon.position = pt
            CATransaction.commit()
        }

        private func updateTraveledPath(progress: Double) {
            guard let progressLayer = progressLayer else { return }
            let path = UIBezierPath()
            let endIndex = max(1, Int(Double(arcPoints.count - 1) * progress))
            path.move(to: arcPoints.first!)
            for pt in arcPoints[1...endIndex] {
                path.addLine(to: pt)
            }

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            progressLayer.path = path.cgPath
            CATransaction.commit()
        }

        // Bézier arc generation
        private func generateArcPoints(from dep: CLLocationCoordinate2D, to arr: CLLocationCoordinate2D, on mapView: MKMapView) -> [CGPoint] {
            let numberOfPoints = 100
            let midLat = (dep.latitude + arr.latitude) / 2
            let midLng = (dep.longitude + arr.longitude) / 2

            let distance = hypot(dep.latitude - arr.latitude, dep.longitude - arr.longitude)
            let arcMagnitude = distance * 0.3

            let isEastbound = arr.longitude > dep.longitude
            let arcDir = isEastbound ? 1.0 : -1.0

            let flightVec = (lng: arr.longitude - dep.longitude, lat: arr.latitude - dep.latitude)
            let perp = (lng: -flightVec.lat, lat: flightVec.lng)
            let length = sqrt(perp.lng * perp.lng + perp.lat * perp.lat)
            let perpNorm = (lng: perp.lng / length, lat: perp.lat / length)

            let control = CLLocationCoordinate2D(
                latitude: midLat + arcMagnitude * arcDir * perpNorm.lat,
                longitude: midLng + arcMagnitude * arcDir * perpNorm.lng
            )

            var curve: [CLLocationCoordinate2D] = []
            for i in 0...numberOfPoints {
                let t = Double(i) / Double(numberOfPoints)
                let lat = pow(1 - t, 2) * dep.latitude + 2 * (1 - t) * t * control.latitude + pow(t, 2) * arr.latitude
                let lng = pow(1 - t, 2) * dep.longitude + 2 * (1 - t) * t * control.longitude + pow(t, 2) * arr.longitude
                curve.append(CLLocationCoordinate2D(latitude: lat, longitude: lng))
            }

            return curve.map { mapView.convert($0, toPointTo: mapView) }
        }
    }
}
