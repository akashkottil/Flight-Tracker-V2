import SwiftUI

struct AlertScreen: View {
    // State management for the new workflow
    @State private var alerts: [AlertResponse] = []
    @State private var alertsWithFlights: [AlertResponse] = []
    @State private var alertsWithoutFlights: [AlertResponse] = []
    @State private var isInitialLoading = false
    @State private var isRefreshing = false
    @State private var alertsError: String?
    @State private var hasEverLoaded = false
    @State private var showAddButton = false
    
    @State private var adultsCount = 2
    @State private var childrenCount = 0
    @State private var selectedCabinClass = "Economy"
    @State private var childrenAges: [Int?] = []
    @State private var showingPassengersSheet = false
    
    // Network manager
    private let alertNetworkManager = AlertNetworkManager.shared
    
    // MARK: - Computed Properties for Workflow Logic
    
    private var shouldShowCreateView: Bool {
        return !isInitialLoading && alerts.isEmpty && hasEverLoaded
    }
    
    private var shouldShowAlertView: Bool {
        return !alerts.isEmpty && hasEverLoaded
    }
    
    private var shouldShowFullScreenLoading: Bool {
        return isInitialLoading && alerts.isEmpty && !hasEverLoaded
    }
    
    private var shouldShowShimmerCards: Bool {
        return isRefreshing && !alerts.isEmpty
    }
    
    
    
    var body: some View {
        
        Group {
            if shouldShowFullScreenLoading {
                // Show full-screen loading on first load
                fullScreenLoadingView
            } else if shouldShowCreateView {
                // NEW: Show create view when user has no alerts
                FACreateView(
                    onAlertCreated: { alertResponse in
                        handleNewAlertCreated(alertResponse)
                    }
                )
            } else if shouldShowAlertView {
                // Show alerts view with proper content based on cheapest_flight status
                alertsContentView
            } else {
                // Fallback loading state
                fullScreenLoadingView
            }
        }
        .sheet(isPresented: $showingPassengersSheet) {
            PassengersAndClassSelector(
                adultsCount: $adultsCount,
                childrenCount: $childrenCount,
                selectedClass: $selectedCabinClass,
                childrenAges: $childrenAges
            )
        }
        .onAppear {
            handleTabAppear()
        }
        .refreshable {
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
    
    // MARK: - Alert Content View (NEW)
    
    @ViewBuilder
    private var alertsContentView: some View {
        ZStack {
            GradientColor.BlueWhite
                .ignoresSafeArea()
            
            VStack {
                FAheader(
                    adultsCount: $adultsCount,
                    childrenCount: $childrenCount,
                    selectedCabinClass: $selectedCabinClass,
                    childrenAges: $childrenAges,
                    onPassengerTap: {
                        showingPassengersSheet = true
                    }
                )
                
                if alertsWithFlights.isEmpty{
                    VStack{}
                }else{
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Today's price drop alerts")
                                .font(.system(size: 20, weight: .bold))
                            Text("Real-time flight price monitoring")
                                .font(.system(size: 14, weight: .regular))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                }
                
                
                
                ScrollView (showsIndicators: false) {
                    VStack(spacing: 0) {
                        
                        // MAIN CONTENT: Show cards or NoAlert based on cheapest_flight
                        if shouldShowShimmerCards {
                            // Show shimmer during refresh
                            ForEach(0..<max(alerts.count, 3), id: \.self) { index in
                                FAShimmerCard()
                                    .padding()
                                    .id("shimmer-\(index)")
                            }
                        } else if alertsWithFlights.isEmpty {
                            // NEW: Show NoAlert when all alerts have null cheapest_flight
                            VStack(spacing: 250) {
                                Spacer()
                                NoAlert()
                                Spacer()
                            }
                            .frame(maxHeight: .infinity)
                        } else {
                            // Show FACards only for alerts with cheapest_flight data
                            ForEach(alertsWithFlights) { alert in
                                FACard(
                                    alertData: alert,
                                    onDelete: { deletedAlert in
                                        handleAlertDeleted(deletedAlert)
                                    },
                                    onNavigateToSearch: { origin, destination, date, adults, children, cabinClass in
                                        handleAlertSearchNavigation(
                                            fromCode: origin,
                                            toCode: destination,
                                            date: date,
                                            adults: adults,
                                            children: children,
                                            cabinClass: cabinClass,
                                            alert: alert
                                        )
                                    },
                                    // ✅ SOLUTION: Use stored values from alert or default constants
                                    adultsCount: .constant(alert.stored_adults_count ?? 2),
                                    childrenCount: .constant(alert.stored_children_count ?? 0),
                                    selectedCabinClass: .constant(alert.stored_cabin_class ?? "Economy")
                                )
                                .padding(.horizontal)
                                .padding(.vertical,6)
                                .id("alert-\(alert.id)")
                            }                        }
                        
                        Color.clear
                            .frame(height: 100)
                    }
                }
                .animation(.easeInOut(duration: 0.4), value: shouldShowShimmerCards)
                .animation(.easeInOut(duration: 0.4), value: alertsWithFlights.count)
            }
            
            // Bottom button - always show when in alert view
            if showAddButton {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 0) {
                        // Add new alert button
                        Button(action: {
                            showLocationSheet = true
                        }) {
                            HStack {
                                Image("FAPlus")
                                Text("Add new alert")
                            }
                            .padding()
                        }
                        .disabled(shouldShowShimmerCards)
                        .opacity(shouldShowShimmerCards ? 0.7 : 1.0)
                        
                        // Vertical divider
                        Rectangle()
                            .fill(Color.white.opacity(0.4))
                            .frame(width: 1, height: 50)
                        
                        // Hamburger button
                        Button(action: {
                            showMyAlertsSheet = true
                        }) {
                            HStack {
                                Image("FAHamburger")
                            }
                            .padding()
                        }
                        .disabled(shouldShowShimmerCards)
                        .opacity(shouldShowShimmerCards ? 0.7 : 1.0)
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 18))
                    .background(Color("FABlue"))
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8)
                        .combined(with: .opacity)
                        .combined(with: .move(edge: .bottom)),
                    removal: .scale(scale: 0.8)
                        .combined(with: .opacity)
                        .combined(with: .move(edge: .bottom))
                ))
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showAddButton)
            }
        }
        .sheet(isPresented: $showLocationSheet) {
            FALocationSheet { newAlert in
                handleNewAlertCreated(newAlert)
            }
        }
        .sheet(isPresented: $showMyAlertsSheet) {
            MyAlertsView(
                alerts: alerts, // Pass all alerts to MyAlertsView
                onAlertDeleted: { deletedAlert in
                    handleAlertDeleted(deletedAlert)
                    
                    // Close sheet if no alerts left
                    if alerts.count <= 1 {
                        showMyAlertsSheet = false
                    }
                },
                onNewAlertCreated: { newAlert in
                    handleNewAlertCreated(newAlert)
                    showMyAlertsSheet = false
                },
                onAlertUpdated: { updatedAlert in
                    handleAlertUpdated(updatedAlert)
                }
            )
        }
    }
    
    // Sheet state variables
    @State private var showLocationSheet = false
    @State private var showMyAlertsSheet = false
    
    // MARK: - Loading View
    
    private var fullScreenLoadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: Color("FABlue")))
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GradientColor.BlueWhite.ignoresSafeArea())
    }
    
    // MARK: - Tab Switching Logic
    
    private func handleTabAppear() {
        // If we already have alerts in state, do NOTHING
        if !alerts.isEmpty {
            print("📱 Tab switch: Already have \(alerts.count) alerts, showing instantly")
            showAddButton = true
            return
        }
        
        // Try loading from cache first
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
        
        // Load cached data and categorize
        updateAlertsAndCategorize(cachedAlerts)
        hasEverLoaded = true
        showAddButton = true
        
        print("📱 ✅ Loaded \(alerts.count) alerts from cache instantly")
        print("📱 ✅ With flights: \(alertsWithFlights.count), Without flights: \(alertsWithoutFlights.count)")
    }
    
    // MARK: - API Loading Methods
    
    //    @MainActor
    //    private func performInitialLoad() async {
    //        print("🚀 Starting initial load...")
    //        isInitialLoading = true
    //        alertsError = nil
    //        showAddButton = false
    //
    //        do {
    //            // NEW: Use the specific user endpoint
    //            let fetchedAlerts = try await alertNetworkManager.fetchUserAlerts()
    //            updateAlertsAndCategorize(fetchedAlerts)
    //            hasEverLoaded = true
    //
    //            // Save to cache
    //            saveAlertsToCache()
    //
    //            print("✅ Initial load completed:")
    //            print("   Total alerts: \(alerts.count)")
    //            print("   With flights: \(alertsWithFlights.count)")
    //            print("   Without flights: \(alertsWithoutFlights.count)")
    //
    //            // Show button with animation if we have alerts
    //            if !alerts.isEmpty {
    //                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
    //                    showAddButtonWithAnimation()
    //                }
    //            }
    //
    //        } catch {
    //            alertsError = error.localizedDescription
    //            print("❌ Initial load failed: \(error)")
    //        }
    //
    //        isInitialLoading = false
    //    }
    //
    //
    //
    //    @MainActor
    //    private func performManualRefresh() async {
    //        print("🔄 Starting manual refresh...")
    //
    //        // Only show shimmer if we have existing alerts
    //        if !alerts.isEmpty {
    //            isRefreshing = true
    //        }
    //
    //        alertsError = nil
    //
    //        do {
    //            // NEW: Use the specific user endpoint
    //            let fetchedAlerts = try await alertNetworkManager.fetchUserAlerts()
    //            updateAlertsAndCategorize(fetchedAlerts)
    //            hasEverLoaded = true
    //
    //            // Save to cache
    //            saveAlertsToCache()
    //
    //            print("✅ Manual refresh completed:")
    //            print("   Total alerts: \(alerts.count)")
    //            print("   With flights: \(alertsWithFlights.count)")
    //            print("   Without flights: \(alertsWithoutFlights.count)")
    //
    //        } catch {
    //            alertsError = error.localizedDescription
    //            print("❌ Manual refresh failed: \(error)")
    //        }
    //
    //        isRefreshing = false
    //    }
    
    // MARK: temp api call
    
    @MainActor
    private func performInitialLoad() async {
        print("🚀 Starting initial load...")
        isInitialLoading = true
        alertsError = nil
        showAddButton = false
        
        do {
            // 🚧 TEMPORARY: Use temp API method during development
            let fetchedAlerts: [AlertResponse]
            if DevelopmentConfig.shouldUseTempAPI() {
                DevelopmentConfig.logTempFeature("Using temporary API for initial load")
                fetchedAlerts = try await alertNetworkManager.fetchUserAlertsWithTempData()
            } else {
                fetchedAlerts = try await alertNetworkManager.fetchUserAlerts()
            }
            
            updateAlertsAndCategorize(fetchedAlerts)
            hasEverLoaded = true
            
            // Save to cache
            saveAlertsToCache()
            
            print("✅ Initial load completed:")
            print("   Total alerts: \(alerts.count)")
            print("   With flights: \(alertsWithFlights.count)")
            print("   Without flights: \(alertsWithoutFlights.count)")
            
            // Show button with animation if we have alerts
            if !alerts.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showAddButtonWithAnimation()
                }
            }
            
        } catch {
            alertsError = error.localizedDescription
            print("❌ Initial load failed: \(error)")
        }
        
        isInitialLoading = false
    }
    
    @MainActor
    private func performManualRefresh() async {
        print("🔄 Starting manual refresh...")
        
        // Only show shimmer if we have existing alerts
        if !alerts.isEmpty {
            isRefreshing = true
        }
        
        alertsError = nil
        
        do {
            // 🚧 TEMPORARY: Use temp API method during development
            let fetchedAlerts: [AlertResponse]
            if DevelopmentConfig.shouldUseTempAPI() {
                DevelopmentConfig.logTempFeature("Using temporary API for manual refresh")
                fetchedAlerts = try await alertNetworkManager.fetchUserAlertsWithTempData()
            } else {
                fetchedAlerts = try await alertNetworkManager.fetchUserAlerts()
            }
            
            updateAlertsAndCategorize(fetchedAlerts)
            hasEverLoaded = true
            
            // Save to cache
            saveAlertsToCache()
            
            print("✅ Manual refresh completed:")
            print("   Total alerts: \(alerts.count)")
            print("   With flights: \(alertsWithFlights.count)")
            print("   Without flights: \(alertsWithoutFlights.count)")
            
        } catch {
            alertsError = error.localizedDescription
            print("❌ Manual refresh failed: \(error)")
        }
        
        isRefreshing = false
    }
    
    // MARK: - NEW: Alert Categorization Logic
    
    private func updateAlertsAndCategorize(_ newAlerts: [AlertResponse]) {
        alerts = newAlerts
        
        // Categorize alerts based on cheapest_flight
        alertsWithFlights = alerts.filter { $0.cheapest_flight != nil }
        alertsWithoutFlights = alerts.filter { $0.cheapest_flight == nil }
        
        print("📊 Alert categorization:")
        print("   Total: \(alerts.count)")
        print("   With flights: \(alertsWithFlights.count)")
        print("   Without flights: \(alertsWithoutFlights.count)")
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
        
        let newAlerts = alerts.filter { $0.id != deletedAlert.id }
        updateAlertsAndCategorize(newAlerts)
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
            // Create enhanced alert with current passenger data
            let enhancedAlert = AlertResponse(
                id: newAlert.id,
                user: newAlert.user,
                route: newAlert.route,
                cheapest_flight: newAlert.cheapest_flight,
                image_url: newAlert.image_url,
                target_price: newAlert.target_price,
                last_notified_price: newAlert.last_notified_price,
                created_at: newAlert.created_at,
                updated_at: newAlert.updated_at,
                stored_adults_count: adultsCount,      // ✅ Store current values
                stored_children_count: childrenCount,  // ✅ Store current values
                stored_cabin_class: selectedCabinClass // ✅ Store current values
            )
            
            let newAlerts = alerts + [enhancedAlert]
            updateAlertsAndCategorize(newAlerts)
            saveAlertsToCache()
            
            if !showAddButton {
                showAddButtonWithAnimation()
            }
            
            print("✅ New alert added with passenger data. Total: \(alerts.count)")
        }
    }
    
    private func handleAlertUpdated(_ updatedAlert: AlertResponse) {
        print("🔄 Handling alert update: \(updatedAlert.id)")
        
        // Find and replace the alert in the array
        if let index = alerts.firstIndex(where: { $0.id == updatedAlert.id }) {
            var newAlerts = alerts
            newAlerts[index] = updatedAlert
            updateAlertsAndCategorize(newAlerts)
            saveAlertsToCache()
            
            print("✅ Alert updated successfully")
        } else {
            print("⚠️ Alert to update not found in current list: \(updatedAlert.id)")
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
    
    // MARK: - Alert Search Navigation Handler
    
    private func handleAlertSearchNavigation(
        fromCode: String,
        toCode: String,
        date: Date,
        adults: Int,
        children: Int,
        cabinClass: String,
        alert: AlertResponse
    ) {
        print("🚨 Initiating search from alert: \(fromCode) → \(toCode)")
        
        // Use the extension method to navigate
        SharedSearchDataStore.shared.executeSearchFromAlert(
            fromLocationCode: fromCode,
            fromLocationName: alert.route.origin_name,
            toLocationCode: toCode,
            toLocationName: alert.route.destination_name,
            departureDate: date,
            adultsCount: adults,
            childrenCount: children,
            selectedCabinClass: cabinClass
        )
        
        // Navigate to explore tab
        // Note: You may need to trigger tab navigation here depending on your navigation structure
    }
    
}

//#Preview {
//    AlertScreen()
//}
