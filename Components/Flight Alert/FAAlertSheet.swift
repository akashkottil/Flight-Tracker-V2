import SwiftUI

struct MyAlertsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showLocationSheet = false
    
    // ADDED: Accept real alert data and callbacks
    let alerts: [AlertResponse]
    let onAlertDeleted: ((AlertResponse) -> Void)?
    let onNewAlertCreated: ((AlertResponse) -> Void)?
    
    // ADDED: States for delete functionality
    @State private var alertToDelete: AlertResponse?
    @State private var showDeleteConfirmation = false
    @State private var isDeletingAlert = false
    @State private var deleteError: String?
    
    // Network manager for delete operations
    private let alertNetworkManager = AlertNetworkManager.shared
    
    // ADDED: Initializer to accept real data
    init(
        alerts: [AlertResponse] = [],
        onAlertDeleted: ((AlertResponse) -> Void)? = nil,
        onNewAlertCreated: ((AlertResponse) -> Void)? = nil
    ) {
        self.alerts = alerts
        self.onAlertDeleted = onAlertDeleted
        self.onNewAlertCreated = onNewAlertCreated
    }
    
    var body: some View {
        ZStack {
            
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.black)
                            .padding(10)
                            .background(Circle().fill(Color.gray.opacity(0.1)))
                    }
                    Spacer()
                    Text("My alerts")
                        .bold()
                        .font(.title2)
                    Spacer()
                    // Empty view for balance
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding()
                .background(Color.white)
                
                // UPDATED: Dynamic alerts list based on real data
                if alerts.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "bell.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        VStack(spacing: 8) {
                            Text("No alerts yet")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Text("Create your first flight price alert")
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        
                        Spacer()
                    }
                } else {
                    // Alerts list with real data
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // UPDATED: Use real alert data
                            ForEach(alerts) { alert in
                                alertCard(
                                    alert: alert,
                                    fromCode: alert.route.origin,
                                    fromName: alert.route.origin_name,
                                    toCode: alert.route.destination,
                                    toName: alert.route.destination_name
                                )
                            }
                            
                            // Add extra padding at bottom to prevent content from being hidden behind the button
                            Color.clear
                                .frame(height: 80)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                }
            }
            
            // Fixed bottom button
            VStack {
                Spacer()
                
                Button(action: {
                    showLocationSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add new alert")
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .medium))
                    .padding()
                    .background(Color("FABlue"))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
            }
            
            // ADDED: Loading overlay during delete
            if isDeletingAlert {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    
                    Text("Deleting alert...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(20)
                .background(Color.black.opacity(0.7))
                .cornerRadius(12)
            }
        }
        .sheet(isPresented: $showLocationSheet) {
            // UPDATED: Pass the callback for new alert creation
            FALocationSheet { newAlert in
                onNewAlertCreated?(newAlert)
            }
        }
        // ADDED: Delete confirmation alert
        .alert("Delete Alert", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                alertToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let alert = alertToDelete {
                    Task {
                        await deleteAlert(alert)
                    }
                }
            }
        } message: {
            if let alert = alertToDelete {
                Text("Are you sure you want to delete the alert for \(alert.route.origin_name) → \(alert.route.destination_name)?")
            }
        }
        // ADDED: Delete error alert
        .alert("Delete Failed", isPresented: .constant(deleteError != nil)) {
            Button("OK") {
                deleteError = nil
            }
        } message: {
            if let error = deleteError {
                Text(error)
            }
        }
    }
    
    // UPDATED: alertCard now accepts real alert data and handles delete
    @ViewBuilder
    private func alertCard(
        alert: AlertResponse,
        fromCode: String,
        fromName: String,
        toCode: String,
        toName: String
    ) -> some View {
        VStack(spacing: 0) {
            
            // From airport
            HStack(spacing: 15) {
                // Airport code badge
                VStack(alignment: .leading){
                    Text(fromCode)
                        .font(.system(size: 15, weight: .bold))
                        .padding(.vertical,5)
                        .cornerRadius(8)
                        Text(fromName)
                        .font(.system(size: 14))
                            .foregroundColor(.black)
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 12) {
                    // UPDATED: Delete button now triggers confirmation and API call
                    Button(action: {
                        alertToDelete = alert
                        showDeleteConfirmation = true
                    }) {
                        Image("FADelete")
                            .foregroundColor(.red)
                            .frame(width: 24, height: 24)
                    }
                    .disabled(isDeletingAlert) // Disable while deleting
                    
                    Button(action: {
                        print("Edit alert: \(alert.id)")
                        // TODO: Implement edit functionality
                    }) {
                        Image("FAEdit")
                            .foregroundColor(.gray)
                            .frame(width: 24, height: 24)
                    }
                    .disabled(isDeletingAlert) // Disable while deleting
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Arrow indicator
            HStack {
                Image("FADownArrow")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
                    .padding(.vertical, 8)
                Spacer()
            }
            .padding(.horizontal,20)
            
            // To airport
            HStack(spacing: 15) {
                // Airport code badge
                VStack(alignment: .leading){
                    Text(toCode)
                        .font(.system(size: 14, weight: .bold))
                        .padding(.vertical,5)
                        .cornerRadius(8)
                        Text(toName)
                        .font(.system(size: 14))
                            .foregroundColor(.black)
                }
                
                Spacer()
                
                // Empty space to align with action buttons above
                Color.clear.frame(width: 60, height: 24)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
            // ADDED: Optional - Show alert creation date and price info
//            if let cheapestFlight = alert.cheapest_flight {
//                Divider()
//                    .padding(.horizontal, 16)
//                
//                HStack {
//                    VStack(alignment: .leading, spacing: 4) {
//                        Text("Current Price")
//                            .font(.system(size: 12))
//                            .foregroundColor(.gray)
//                        
//                        Text("\(getCurrencySymbol(for: alert.route.currency))\(formatPrice(cheapestFlight.price))")
//                            .font(.system(size: 16, weight: .bold))
//                            .foregroundColor(.green)
//                    }
//                    
//                    Spacer()
//                    
//                    VStack(alignment: .trailing, spacing: 4) {
//                        Text("Status")
//                            .font(.system(size: 12))
//                            .foregroundColor(.gray)
//                        
//                        Text(cheapestFlight.price_category.capitalized)
//                            .font(.system(size: 14, weight: .medium))
//                            .foregroundColor(cheapestFlight.price_category.lowercased() == "cheap" ? .green : .orange)
//                    }
//                }
//                .padding(.horizontal, 16)
//                .padding(.bottom, 12)
//            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .opacity(isDeletingAlert && alertToDelete?.id == alert.id ? 0.5 : 1.0) // Dim card being deleted
    }
    
    // MARK: - Delete Alert Functionality
    
    @MainActor
    private func deleteAlert(_ alert: AlertResponse) async {
        isDeletingAlert = true
        deleteError = nil
        
        do {
            // ENHANCED: Use the smart delete method with better error handling
            try await alertNetworkManager.deleteAlertSmart(alertId: alert.id)
            
            // ✅ SUCCESS: Immediately notify parent to update local state
            onAlertDeleted?(alert)
            
            // Clear the alert to delete
            alertToDelete = nil
            
            print("✅ Alert deleted successfully and UI updated: \(alert.id)")
            
            // Note: We don't fetch alerts here - let the parent handle state updates
            
        } catch {
            // Enhanced error handling with user-friendly messages
            if let alertError = error as? AlertNetworkError {
                switch alertError {
                case .serverError(let message):
                    if message.contains("not found") || message.contains("already deleted") {
                        // Even if 404, consider it success since alert is gone
                        print("⚠️ Alert not found (404) - treating as successful deletion")
                        onAlertDeleted?(alert)
                        alertToDelete = nil
                        isDeletingAlert = false
                        return
                    } else if message.contains("permission") || message.contains("Access denied") {
                        deleteError = "You don't have permission to delete this alert."
                    } else {
                        deleteError = message
                    }
                default:
                    deleteError = "Failed to delete alert: \(error.localizedDescription)"
                }
            } else {
                deleteError = "Failed to delete alert: \(error.localizedDescription)"
            }
            
            print("❌ Failed to delete alert: \(error)")
        }
        
        isDeletingAlert = false
    }
    
    // MARK: - Helper Methods
    
    private func getCurrencySymbol(for currency: String) -> String {
        switch currency.uppercased() {
        case "INR":
            return "₹"
        case "USD":
            return "$"
        case "EUR":
            return "€"
        case "GBP":
            return "£"
        default:
            return currency
        }
    }
    
    private func formatPrice(_ price: Double) -> String {
        if price >= 1000 {
            return String(format: "%.0f", price)
        } else {
            return String(format: "%.0f", price)
        }
    }
}

#Preview {
    // Preview with sample data
    MyAlertsView(
        alerts: [
            AlertResponse(
                id: "sample-id-1",
                user: AlertUserResponse(
                    id: "testId",
                    push_token: "token",
                    created_at: "2025-06-27T14:06:14.919574Z",
                    updated_at: "2025-06-27T14:06:14.919604Z"
                ),
                route: AlertRouteResponse(
                    id: 151,
                    origin: "JFK",
                    destination: "COK",
                    currency: "USD",
                    origin_name: "John F. Kennedy International Airport",
                    destination_name: "Cochin International Airport",
                    created_at: "2025-06-25T09:32:47.398234Z",
                    updated_at: "2025-06-27T14:06:14.932802Z"
                ),
                cheapest_flight: CheapestFlight(
                    id: 13599,
                    price: 699,
                    price_category: "cheap",
                    outbound_departure_timestamp: 1752624000,
                    outbound_departure_datetime: "2025-07-16T00:00:00Z",
                    outbound_is_direct: true,
                    inbound_departure_timestamp: nil,
                    inbound_departure_datetime: nil,
                    inbound_is_direct: nil,
                    created_at: "2025-06-25T09:32:47.620603Z",
                    updated_at: "2025-06-25T09:32:47.620615Z",
                    route: 151
                ),
                image_url: "https://image.explore.lascadian.com/city_95673506.webp",
                target_price: nil,
                last_notified_price: nil,
                created_at: "2025-06-27T14:06:14.947629Z",
                updated_at: "2025-06-27T14:06:14.947659Z"
            )
        ],
        onAlertDeleted: { alert in
            print("Alert deleted: \(alert.id)")
        },
        onNewAlertCreated: { alert in
            print("New alert created: \(alert.id)")
        }
    )
}
