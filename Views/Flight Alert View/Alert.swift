import SwiftUI

struct AlertScreen: View {
    // UPDATED: State to track alerts and loading
    @State private var alerts: [AlertResponse] = []
    @State private var isLoadingAlerts = false
    @State private var alertsError: String?
    
    // Network manager
    private let alertNetworkManager = AlertNetworkManager.shared
    
    // Computed property to determine which view to show
    private var hasAlerts: Bool {
        !alerts.isEmpty
    }
    
    var body: some View {
        Group {
            if isLoadingAlerts {
                // Show loading state
                loadingView
            } else if hasAlerts {
                // Show alerts view with real API data
                FAAlertView(
                    alerts: alerts,
                    onAlertDeleted: { deletedAlert in
                        // Delete from API and update local state
                        Task {
                            await deleteAlert(deletedAlert)
                        }
                    },
                    onNewAlertCreated: { newAlert in
                        // Add new alert to local state (already created via API)
                        alerts.append(newAlert)
                        saveAlertsToCache() // Cache for offline viewing
                        print("✅ New alert added from FAAlertView: \(newAlert.id)")
                    }
                )
            } else {
                // Show create view when no alerts exist
                FACreateView(
                    onAlertCreated: { alertResponse in
                        // Add newly created alert to state
                        alerts.append(alertResponse)
                        saveAlertsToCache() // Cache for offline viewing
                        print("✅ Alert created and state updated - switching to FAAlertView")
                    }
                )
            }
        }
        .onAppear {
            // Fetch alerts from API when app opens
            Task {
                await fetchAlertsFromAPI()
            }
        }
        .refreshable {
            // Pull to refresh functionality
            Task {
                await fetchAlertsFromAPI()
            }
        }
        .alert("Error Loading Alerts", isPresented: .constant(alertsError != nil)) {
            Button("Retry") {
                Task {
                    await fetchAlertsFromAPI()
                }
            }
            Button("Cancel") {
                alertsError = nil
            }
        } message: {
            if let error = alertsError {
                Text(error)
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: Color("FABlue")))
            
            Text("Loading your alerts...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GradientColor.BlueWhite.ignoresSafeArea())
    }
    
    // MARK: - API Methods
    
    @MainActor
    private func fetchAlertsFromAPI() async {
        isLoadingAlerts = true
        alertsError = nil
        
        do {
            let fetchedAlerts = try await alertNetworkManager.fetchAlerts()
            alerts = fetchedAlerts
            
            // Cache for offline viewing
            saveAlertsToCache()
            
            print("✅ Successfully fetched \(fetchedAlerts.count) alerts from API")
            
        } catch {
            alertsError = error.localizedDescription
            print("❌ Failed to fetch alerts: \(error)")
            
            // Fallback to cached alerts if API fails
            loadAlertsFromCache()
        }
        
        isLoadingAlerts = false
    }
    
    @MainActor
    private func deleteAlert(_ alert: AlertResponse) async {
        do {
            // Delete from API
            try await alertNetworkManager.deleteAlert(alertId: alert.id)
            
            // Remove from local state
            alerts.removeAll { $0.id == alert.id }
            
            // Update cache
            saveAlertsToCache()
            
            print("✅ Alert deleted successfully: \(alert.id)")
            
        } catch {
            print("❌ Failed to delete alert: \(error)")
            
            // Show error to user
            alertsError = "Failed to delete alert: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Cache Management (Fallback for offline use)
    
    private func saveAlertsToCache() {
        if let data = try? JSONEncoder().encode(alerts) {
            UserDefaults.standard.set(data, forKey: "CachedAlerts")
            print("💾 Cached \(alerts.count) alerts locally")
        }
    }
    
    private func loadAlertsFromCache() {
        guard let data = UserDefaults.standard.data(forKey: "CachedAlerts"),
              let cachedAlerts = try? JSONDecoder().decode([AlertResponse].self, from: data) else {
            print("📱 No cached alerts found")
            return
        }
        
        alerts = cachedAlerts
        print("📱 Loaded \(alerts.count) alerts from cache (offline fallback)")
    }
}

#Preview {
    AlertScreen()
}
