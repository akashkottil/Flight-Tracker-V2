import SwiftUI

struct FAAlertView: View {
    
    // ADDED: Accept alerts data and callbacks
    let alerts: [AlertResponse]
    let onAlertDeleted: ((AlertResponse) -> Void)?
    let onNewAlertCreated: ((AlertResponse) -> Void)?
    
    @State private var showLocationSheet = false
    @State private var showMyAlertsSheet = false
    
    // ADDED: Animation states
    @State private var animatedAlerts: Set<String> = []
    @State private var hasInitiallyLoaded = false
    
    // ADDED: Default initializer for backward compatibility
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
            GradientColor.BlueWhite
                .ignoresSafeArea()
            VStack {
                FAheader()
                
                // UPDATED: Always show alerts since we only reach this view when alerts exist
                ScrollView {
                    VStack(spacing: 0) {
                        
                        // UPDATED: Display real alerts using FACard with animations
                        ForEach(Array(alerts.enumerated()), id: \.element.id) { index, alert in
                            FACard(
                                alertData: alert,
                                onDelete: { deletedAlert in
                                    // Animate out before deletion
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        animatedAlerts.remove(deletedAlert.id)
                                    }
                                    
                                    // Delay the actual deletion to allow animation
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        onAlertDeleted?(deletedAlert)
                                    }
                                }
                            )
                            .padding()
                            .opacity(animatedAlerts.contains(alert.id) ? 1 : 0)
                            .offset(y: animatedAlerts.contains(alert.id) ? 0 : 10)
                            .scaleEffect(animatedAlerts.contains(alert.id) ? 1 : 0.85)
                            .onAppear {
                                // Only animate if this card hasn't been animated yet
                                if !animatedAlerts.contains(alert.id) {
                                    // Stagger the animation for initial load
                                    let delay = hasInitiallyLoaded ? 0.1 : Double(index) * 0.15
                                    
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0).delay(delay)) {
                                        animatedAlerts.insert(alert.id)
                                    }
                                }
                            }
                        }
                        
                        Color.clear
                            .frame(height: 80)
                    }
                }
                .scrollIndicators(.hidden)
            }
            
            // Fixed bottom button with slide-up animation
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
                }
                .foregroundColor(.white)
                .font(.system(size: 18))
                .background(Color("FABlue"))
                .cornerRadius(10)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
                .offset(y: hasInitiallyLoaded ? 0 : 100)
                .opacity(hasInitiallyLoaded ? 1 : 0)
            }
        }
        .onAppear {
            // Mark as initially loaded after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                hasInitiallyLoaded = true
                
                // Animate bottom button
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    // Bottom button animation is handled by the offset/opacity modifiers above
                }
            }
        }
        .onChange(of: alerts.count) { newCount in
            // Handle new alerts being added
            for alert in alerts {
                if !animatedAlerts.contains(alert.id) {
                    // New alert detected, animate it in
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                        animatedAlerts.insert(alert.id)
                    }
                }
            }
        }
        .sheet(isPresented: $showLocationSheet) {
            // UPDATED: Handle new alert creation and pass to parent
            FALocationSheet { newAlert in
                print("✅ New alert created in FAAlertView: \(newAlert.id)")
                
                // Pass the new alert to the parent via callback
                onNewAlertCreated?(newAlert)
            }
        }
        .sheet(isPresented: $showMyAlertsSheet) {
            // UPDATED: Pass real alert data to MyAlertsView
            MyAlertsView(
                alerts: alerts,
                onAlertDeleted: { deletedAlert in
                    // Handle alert deletion - pass to parent
                    onAlertDeleted?(deletedAlert)
                    
                    // Close the sheet if no alerts left
                    if alerts.count <= 1 {
                        showMyAlertsSheet = false
                    }
                },
                onNewAlertCreated: { newAlert in
                    // Handle new alert creation - pass to parent
                    onNewAlertCreated?(newAlert)
                    
                    // Close the sheet after creating new alert
                    showMyAlertsSheet = false
                }
            )
        }
    }
}

// MARK: - Animation Extension for smoother transitions
extension View {
    func cardAppearAnimation(isVisible: Bool, delay: Double = 0) -> some View {
        self
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 30)
            .scaleEffect(isVisible ? 1 : 0.95)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: isVisible)
    }
}

#Preview {
    FAAlertView(
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
                    origin: "COK",
                    destination: "DXB",
                    currency: "INR",
                    origin_name: "Kochi",
                    destination_name: "Dubai",
                    created_at: "2025-06-25T09:32:47.398234Z",
                    updated_at: "2025-06-27T14:06:14.932802Z"
                ),
                cheapest_flight: CheapestFlight(
                    id: 13599,
                    price: 5555,
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
            ),
            AlertResponse(
                id: "sample-id-2",
                user: AlertUserResponse(
                    id: "testId",
                    push_token: "token",
                    created_at: "2025-06-27T14:06:14.919574Z",
                    updated_at: "2025-06-27T14:06:14.919604Z"
                ),
                route: AlertRouteResponse(
                    id: 152,
                    origin: "JFK",
                    destination: "COK",
                    currency: "USD",
                    origin_name: "John F. Kennedy International Airport",
                    destination_name: "Cochin International Airport",
                    created_at: "2025-06-25T09:32:47.398234Z",
                    updated_at: "2025-06-27T14:06:14.932802Z"
                ),
                cheapest_flight: CheapestFlight(
                    id: 13600,
                    price: 799,
                    price_category: "average",
                    outbound_departure_timestamp: 1752624000,
                    outbound_departure_datetime: "2025-07-20T00:00:00Z",
                    outbound_is_direct: false,
                    inbound_departure_timestamp: nil,
                    inbound_departure_datetime: nil,
                    inbound_is_direct: nil,
                    created_at: "2025-06-25T09:32:47.620603Z",
                    updated_at: "2025-06-25T09:32:47.620615Z",
                    route: 152
                ),
                image_url: "https://image.explore.lascadian.com/city_95673507.webp",
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
