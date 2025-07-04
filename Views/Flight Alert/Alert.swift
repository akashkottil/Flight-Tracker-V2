import SwiftUI

struct AlertScreen: View {
    // UPDATED: Better state management for tab switching
    @State private var alerts: [AlertResponse] = []
    @State private var isInitialLoading = false
    @State private var isRefreshing = false
    @State private var alertsError: String?
    @State private var hasEverLoaded = false
    @State private var showAddButton = false        
    
    // Network manager
    private let alertNetworkManager = AlertNetworkManager.shared
    
    // UPDATED: Clear logic for when to show what
    private var shouldShowShimmerCards: Bool {
        return isRefreshing && !alerts.isEmpty  // Only during manual refresh
    }
    
    private var shouldShowFullScreenLoading: Bool {
        return isInitialLoading && alerts.isEmpty && !hasEverLoaded  // Only first time ever
    }
    
    private var hasAlerts: Bool {
        return !alerts.isEmpty
    }
    
    var body: some View {
        Group {
            if shouldShowFullScreenLoading {
                // Show full-screen loading ONLY on very first load
                fullScreenLoadingView
            } else if hasAlerts || shouldShowShimmerCards {
                // Show alerts view (either real cards or shimmer during refresh)
                FAAlertView(
                    alerts: alerts,
                    isLoadingShimmer: shouldShowShimmerCards,
                    showAddButton: showAddButton,
                    onAlertDeleted: { deletedAlert in
                        handleAlertDeleted(deletedAlert)
                    },
                    onNewAlertCreated: { newAlert in
                        handleNewAlertCreated(newAlert)
                    },
                    onAlertUpdated: { updatedAlert in
                        handleAlertUpdated(updatedAlert)
                    }
                )
            } else {
                // Show create view when no alerts exist and not loading
                FACreateView(
                    onAlertCreated: { alertResponse in
                        handleNewAlertCreated(alertResponse)
                    }
                )
            }
        }
        .onAppear {
            // FIXED: Proper tab switch handling
            handleTabAppear()
        }
        .refreshable {
            // Manual refresh - show shimmer
            Task {
                await performManualRefresh()
            }
        }
        .alert("Error Loading Alerts", isPresented: .constant(alertsError != nil)) {
            Button("Retry") {
                Task {
                    await performInitialLoad()
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
    
    private var fullScreenLoadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: Color("FABlue")))
            
//            Text("Loading your alerts...")
//                .font(.system(size: 16, weight: .medium))
//                .foregroundColor(.gray)
//            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GradientColor.BlueWhite.ignoresSafeArea())
    }
    
    // MARK: - FIXED: Tab Switching Logic
    
    private func handleTabAppear() {
        // If we already have alerts in state, do NOTHING
        if !alerts.isEmpty {
            print("📱 Tab switch: Already have \(alerts.count) alerts, showing instantly")
            // Button should already be visible from previous load - no animation needed
            showAddButton = true
            return
        }
        
        // If we don't have alerts in state, try loading from cache
        loadFromCacheIfAvailable()
        
        // If cache loading didn't work, fetch from API
        if alerts.isEmpty && !hasEverLoaded {
            print("📱 First time load: No cache found, fetching from API")
            Task {
                await performInitialLoad()
            }
        }
    }
    
    private func loadFromCacheIfAvailable() {
        guard let data = UserDefaults.standard.data(forKey: "CachedAlerts"),
              let cachedAlerts = try? JSONDecoder().decode([AlertResponse].self, from: data) else {
            print("📱 No cached alerts available")
            return
        }
        
        // Load cached data instantly
        alerts = cachedAlerts
        hasEverLoaded = true
        
        // Show button immediately for cached data - NO ANIMATION on cache load
        showAddButton = true
        
        print("📱 ✅ Loaded \(alerts.count) alerts from cache instantly - button visible")
    }
    
    // MARK: - API Loading Methods
    
    @MainActor
    private func performInitialLoad() async {
        isInitialLoading = true
        alertsError = nil
        showAddButton = false  // Hide button during loading
        
        do {
            let fetchedAlerts = try await alertNetworkManager.fetchAlerts()
            alerts = fetchedAlerts
            hasEverLoaded = true
            
            // Save to cache
            saveAlertsToCache()
            
            // Show button with animation after loading completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showAddButtonWithAnimation()
            }
            
            print("✅ Initial load completed: \(fetchedAlerts.count) alerts")
            
        } catch {
            alertsError = error.localizedDescription
            print("❌ Initial load failed: \(error)")
        }
        
        isInitialLoading = false
    }
    
    @MainActor
    private func performManualRefresh() async {
        // Only show shimmer if we have existing alerts
        if !alerts.isEmpty {
            isRefreshing = true
        }
        
        alertsError = nil
        
        do {
            let fetchedAlerts = try await alertNetworkManager.fetchAlerts()
            alerts = fetchedAlerts
            hasEverLoaded = true
            
            // Save to cache
            saveAlertsToCache()
            
            print("✅ Manual refresh completed: \(fetchedAlerts.count) alerts")
            
        } catch {
            alertsError = error.localizedDescription
            print("❌ Manual refresh failed: \(error)")
        }
        
        isRefreshing = false
    }
    
    // MARK: - Button Animation
    
    private func showAddButtonWithAnimation() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
            showAddButton = true
        }
    }
    
    private func hideAddButton() {
        withAnimation(.easeOut(duration: 0.2)) {
            showAddButton = false
        }
    }
    
    // MARK: - Alert Event Handlers
    
    private func handleAlertDeleted(_ deletedAlert: AlertResponse) {
        print("🗑️ Handling alert deletion: \(deletedAlert.id)")
        
        alerts.removeAll { $0.id == deletedAlert.id }
        saveAlertsToCache()
        
        // Hide button if no alerts left
        if alerts.isEmpty {
            hideAddButton()
        }
        
        print("✅ Alert removed. Remaining: \(alerts.count)")
    }
    
    private func handleNewAlertCreated(_ newAlert: AlertResponse) {
        print("➕ Handling new alert creation: \(newAlert.id)")
        
        if !alerts.contains(where: { $0.id == newAlert.id }) {
            alerts.append(newAlert)
            saveAlertsToCache()
            
            // Show button if not already visible
            if !showAddButton {
                showAddButtonWithAnimation()
            }
            
            print("✅ New alert added. Total: \(alerts.count)")
        }
    }
    
    // MARK: - NEW: Alert Update Handler
    
    private func handleAlertUpdated(_ updatedAlert: AlertResponse) {
        print("🔄 Handling alert update: \(updatedAlert.id)")
        
        // Find and replace the alert in the array
        if let index = alerts.firstIndex(where: { $0.id == updatedAlert.id }) {
            alerts[index] = updatedAlert
            saveAlertsToCache()
            
            print("✅ Alert updated successfully: \(updatedAlert.route.origin_name) → \(updatedAlert.route.destination_name)")
            print("✅ Alert list updated. Total: \(alerts.count)")
        } else {
            print("⚠️ Alert to update not found in current list: \(updatedAlert.id)")
            // Fallback: add it as a new alert
            handleNewAlertCreated(updatedAlert)
        }
    }
    
    // MARK: - Cache Management
    
    private func saveAlertsToCache() {
        do {
            let data = try JSONEncoder().encode(alerts)
            UserDefaults.standard.set(data, forKey: "CachedAlerts")
            UserDefaults.standard.set(Date(), forKey: "AlertsCacheTimestamp")
            print("💾 Cached \(alerts.count) alerts")
        } catch {
            print("❌ Failed to cache alerts: \(error)")
        }
    }
    
    // MARK: - Debug Methods
    
    private func clearCache() {
        UserDefaults.standard.removeObject(forKey: "CachedAlerts")
        UserDefaults.standard.removeObject(forKey: "AlertsCacheTimestamp")
        alerts = []
        hasEverLoaded = false
        showAddButton = false
        print("🗑️ Cache cleared")
    }
}

#Preview {
    AlertScreen()
}
