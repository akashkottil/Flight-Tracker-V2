import SwiftUI

struct FAEditSheet: View {
    let alertToEdit: AlertResponse
    let onAlertUpdated: ((AlertResponse) -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedOriginAirport: Any?
    @State private var selectedDestinationAirport: Any?
    @State private var showOriginSelection = false
    @State private var showDestinationSelection = false
    @State private var isUpdatingAlert = false
    @State private var alertUpdateError: String?
    
    // Track selection state
    @State private var hasSelectedNewOrigin = false
    @State private var hasSelectedNewDestination = false
    
    private let alertNetworkManager = AlertNetworkManager.shared
    
    init(alertToEdit: AlertResponse, onAlertUpdated: ((AlertResponse) -> Void)? = nil) {
        self.alertToEdit = alertToEdit
        self.onAlertUpdated = onAlertUpdated
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                GradientColor.BlueWhite
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerSection
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            currentAlertInfoSection
                            routeSelectionSection
                            alertUpdateErrorSection
                            updateButtonSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
            }
        }
        .sheet(isPresented: $showOriginSelection) {
            FALocationSheet { airport in
                selectedOriginAirport = airport
                hasSelectedNewOrigin = true
                showOriginSelection = false
            }
        }
        .sheet(isPresented: $showDestinationSelection) {
            FALocationSheet { airport in
                selectedDestinationAirport = airport
                hasSelectedNewDestination = true
                showDestinationSelection = false
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.blue)
                .font(.system(size: 16))
                .disabled(isUpdatingAlert)
                
                Spacer()
                
                Text("Edit Alert")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                Button("Save") {
                    performUpdate()
                }
                .foregroundColor(canSaveChanges ? .blue : .gray)
                .font(.system(size: 16, weight: .medium))
                .disabled(!canSaveChanges || isUpdatingAlert)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
        }
        .background(Color.white)
    }
    
    // MARK: - Current Alert Info Section
    
    private var currentAlertInfoSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Current Alert")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("From")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                        Text(alertToEdit.route.origin_name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                        Text(alertToEdit.route.origin)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .medium))
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("To")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                        Text(alertToEdit.route.destination_name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                        Text(alertToEdit.route.destination)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                
                if let cheapestFlight = alertToEdit.cheapest_flight {
                    HStack {
                        Text("Current Price:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(Int(cheapestFlight.price)) \(alertToEdit.route.currency)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - Route Selection Section
    
    private var routeSelectionSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Update Route")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                Spacer()
            }
            
            VStack(spacing: 12) {
                // Origin Selection
                Button(action: {
                    showOriginSelection = true
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("From")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Text(getOriginDisplayName())
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                            Text(getOriginCode())
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Image(systemName: hasSelectedNewOrigin ? "checkmark.circle.fill" : "chevron.right")
                            .foregroundColor(hasSelectedNewOrigin ? .green : .gray)
                            .font(.system(size: 14))
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                .disabled(isUpdatingAlert)
                
                // Swap Button (only show if both airports are selected)
                if hasSelectedNewOrigin && hasSelectedNewDestination {
                    HStack {
                        Spacer()
                        Button(action: swapAirports) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                                .padding(8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .disabled(isUpdatingAlert)
                        Spacer()
                    }
                }
                
                // Destination Selection
                Button(action: {
                    showDestinationSelection = true
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("To")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Text(getDestinationDisplayName())
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                            Text(getDestinationCode())
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Image(systemName: hasSelectedNewDestination ? "checkmark.circle.fill" : "chevron.right")
                            .foregroundColor(hasSelectedNewDestination ? .green : .gray)
                            .font(.system(size: 14))
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                .disabled(isUpdatingAlert)
            }
        }
    }
    
    // MARK: - Alert Update Error Section
    
    @ViewBuilder
    private var alertUpdateErrorSection: some View {
        if let error = alertUpdateError {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: getErrorIcon(for: error))
                        .foregroundColor(getErrorColor(for: error))
                        .font(.system(size: 16))
                    
                    Text(getErrorTitle(for: error))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(getErrorColor(for: error))
                    
                    Spacer()
                }
                
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 12) {
                    if error.contains("already has an alert") || error.contains("already exists") {
                        Button("Continue Anyway") {
                            alertUpdateError = nil
                            performUpdate()
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    
                    Button("Try Again") {
                        alertUpdateError = nil
                        performUpdate()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    
                    Button("Dismiss") {
                        alertUpdateError = nil
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    Spacer()
                }
            }
            .padding(16)
            .background(getErrorColor(for: error).opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(getErrorColor(for: error).opacity(0.3), lineWidth: 1)
            )
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
            .animation(.easeInOut(duration: 0.3), value: alertUpdateError)
        }
    }
    
    // MARK: - Update Button Section
    
    private var updateButtonSection: some View {
        VStack(spacing: 16) {
            Button(action: performUpdate) {
                HStack {
                    if isUpdatingAlert {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Text("Updating Alert...")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    } else {
                        Text("Update Alert")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canSaveChanges && !isUpdatingAlert ? Color.blue : Color.gray.opacity(0.5))
                .cornerRadius(12)
            }
            .disabled(!canSaveChanges || isUpdatingAlert)
            .animation(.easeInOut(duration: 0.2), value: canSaveChanges)
            .animation(.easeInOut(duration: 0.2), value: isUpdatingAlert)
            
            if hasChanges {
                Text("Your changes will be saved and the alert will be updated with new price information.")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var canSaveChanges: Bool {
        return hasChanges && !isSameRoute
    }
    
    private var hasChanges: Bool {
        return hasSelectedNewOrigin || hasSelectedNewDestination
    }
    
    private var isSameRoute: Bool {
        let originCode = getOriginCode()
        let destinationCode = getDestinationCode()
        return originCode == destinationCode
    }
    
    // MARK: - Helper Methods for Dynamic Airport Data
    
    private func getOriginDisplayName() -> String {
        if hasSelectedNewOrigin, let airport = selectedOriginAirport {
            return extractDisplayName(from: airport)
        }
        return alertToEdit.route.origin_name
    }
    
    private func getOriginCode() -> String {
        if hasSelectedNewOrigin, let airport = selectedOriginAirport {
            return extractIATACode(from: airport)
        }
        return alertToEdit.route.origin
    }
    
    private func getDestinationDisplayName() -> String {
        if hasSelectedNewDestination, let airport = selectedDestinationAirport {
            return extractDisplayName(from: airport)
        }
        return alertToEdit.route.destination_name
    }
    
    private func getDestinationCode() -> String {
        if hasSelectedNewDestination, let airport = selectedDestinationAirport {
            return extractIATACode(from: airport)
        }
        return alertToEdit.route.destination
    }
    
    // MARK: - Dynamic Data Extraction
    
    private func extractDisplayName(from airport: Any) -> String {
        // Try different possible property names
        if let flightTrackAirport = airport as? FlightTrackAirport {
            return flightTrackAirport.city
        } else if let dict = airport as? [String: Any] {
            return dict["city"] as? String ?? dict["name"] as? String ?? "Unknown Airport"
        } else {
            // Use reflection to find a suitable property
            let mirror = Mirror(reflecting: airport)
            for child in mirror.children {
                if let label = child.label,
                   (label.lowercased().contains("city") || label.lowercased().contains("name")),
                   let value = child.value as? String {
                    return value
                }
            }
        }
        return "Selected Airport"
    }
    
    private func extractIATACode(from airport: Any) -> String {
        // Try different possible property names
        if let flightTrackAirport = airport as? FlightTrackAirport {
            return flightTrackAirport.iataCode
        } else if let dict = airport as? [String: Any] {
            return dict["iataCode"] as? String ?? dict["code"] as? String ?? "XXX"
        } else {
            // Use reflection to find IATA code
            let mirror = Mirror(reflecting: airport)
            for child in mirror.children {
                if let label = child.label,
                   label.lowercased().contains("iata"),
                   let value = child.value as? String {
                    return value
                }
            }
        }
        return "XXX"
    }
    
    // MARK: - Core Actions
    
    private func swapAirports() {
        let tempOrigin = selectedOriginAirport
        selectedOriginAirport = selectedDestinationAirport
        selectedDestinationAirport = tempOrigin
    }
    
    private func performUpdate() {
        let originCode = getOriginCode()
        let destinationCode = getDestinationCode()
        let originName = getOriginDisplayName()
        let destinationName = getDestinationDisplayName()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isUpdatingAlert = true
            alertUpdateError = nil
        }
        
        Task {
            do {
                print("🚀 Making edit alert API call...")
                print("   From: \(alertToEdit.route.origin) → \(alertToEdit.route.destination)")
                print("   To: \(originCode) → \(destinationCode)")
                
                let updatedAlert = try await alertNetworkManager.editAlert(
                    alertId: alertToEdit.id,
                    origin: originCode,
                    destination: destinationCode,
                    originName: originName,
                    destinationName: destinationName,
                    currency: alertToEdit.route.currency
                )
                
                await MainActor.run {
                    print("✅ Alert updated successfully! Closing sheet...")
                    onAlertUpdated?(updatedAlert)
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.isUpdatingAlert = false
                        
                        // Enhanced error handling for better user experience
                        if let alertError = error as? AlertNetworkError {
                            switch alertError {
                            case .serverError(let message):
                                if message.contains("unique set") || message.contains("already exists") {
                                    self.alertUpdateError = "This route already has an alert. The system will merge them into one alert for better tracking."
                                } else if message.contains("not found") {
                                    self.alertUpdateError = "Alert not found. It may have been deleted. Please refresh and try again."
                                } else if message.contains("permission") {
                                    self.alertUpdateError = "You don't have permission to edit this alert."
                                } else {
                                    self.alertUpdateError = "Update failed: \(message)"
                                }
                            default:
                                self.alertUpdateError = "Update failed: \(error.localizedDescription)"
                            }
                        } else {
                            self.alertUpdateError = "Update failed: \(error.localizedDescription)"
                        }
                    }
                    print("❌ Alert update failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Error Handling Helpers
    
    private func getErrorIcon(for error: String) -> String {
        if error.contains("already has an alert") || error.contains("already exists") {
            return "info.circle.fill"
        } else if error.contains("not found") {
            return "exclamationmark.triangle.fill"
        } else if error.contains("permission") {
            return "lock.circle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }
    
    private func getErrorColor(for error: String) -> Color {
        if error.contains("already has an alert") || error.contains("already exists") {
            return .blue
        } else if error.contains("not found") {
            return .orange
        } else if error.contains("permission") {
            return .red
        } else {
            return .red
        }
    }
    
    private func getErrorTitle(for error: String) -> String {
        if error.contains("already has an alert") || error.contains("already exists") {
            return "Route Already Exists"
        } else if error.contains("not found") {
            return "Alert Not Found"
        } else if error.contains("permission") {
            return "Permission Denied"
        } else {
            return "Update Failed"
        }
    }
}
