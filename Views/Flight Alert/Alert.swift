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
                        // ✅ FIXED: Update local state immediately - no API refetch
                        handleAlertDeleted(deletedAlert)
                    },
                    onNewAlertCreated: { newAlert in
                        // ✅ FIXED: Add new alert to local state immediately
                        handleNewAlertCreated(newAlert)
                    }
                )
            } else {
                // Show create view when no alerts exist
                FACreateView(
                    onAlertCreated: { alertResponse in
                        // ✅ FIXED: Add newly created alert to state
                        handleNewAlertCreated(alertResponse)
                    }
                )
            }
        }
        .onAppear {
            // Fetch alerts from API when app opens (only if empty)
            if alerts.isEmpty {
                Task {
                    await fetchAlertsFromAPI()
                }
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
    
    // MARK: - ✅ FIXED: Alert Event Handlers
    
    private func handleAlertDeleted(_ deletedAlert: AlertResponse) {
        print("🗑️ Handling alert deletion: \(deletedAlert.id)")
        
        // ✅ IMMEDIATE STATE UPDATE - Remove from local array
        alerts.removeAll { $0.id == deletedAlert.id }
        
        // Update cache for offline viewing
        saveAlertsToCache()
        
        print("✅ Alert removed from local state. Remaining alerts: \(alerts.count)")
        
        // ❌ REMOVED: No API refetch here - that was causing the error
        // The delete API call is already handled in MyAlertsView
    }
    
    private func handleNewAlertCreated(_ newAlert: AlertResponse) {
        print("➕ Handling new alert creation: \(newAlert.id)")
        
        // ✅ IMMEDIATE STATE UPDATE - Add to existing alerts
        // Check if alert already exists to avoid duplicates
        if !alerts.contains(where: { $0.id == newAlert.id }) {
            alerts.append(newAlert)
            
            // Update cache for offline viewing
            saveAlertsToCache()
            
            print("✅ New alert added to local state. Total alerts: \(alerts.count)")
        } else {
            print("⚠️ Alert already exists in local state: \(newAlert.id)")
        }
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
    
    // MARK: - ❌ REMOVED: Delete method (now handled in MyAlertsView)
    // The delete API call is now handled directly in MyAlertsView, and this view
    // only updates local state via the callback
    
    // MARK: - Cache Management (Unchanged)
    
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
